package commands

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/spf13/cobra"

	"goo-cli/internal/config"
	"goo-cli/internal/gnokey"
	"goo-cli/internal/search_agent"
	"goo-cli/internal/utils"
)

// NewProposeCmd creates the propose command
func NewProposeCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "propose",
		Short: "Propose values for requests",
		Long:  "Propose a value for a data request or resolve a request",
	}

	cmd.AddCommand(NewProposeValueCmd())
	cmd.AddCommand(NewProposeResolveCmd())

	return cmd
}

// NewProposeValueCmd proposes a value for a request
func NewProposeValueCmd() *cobra.Command {
	var searchFlag bool

	cmd := &cobra.Command{
		Use:   "value <request-id> [value]",
		Short: "Propose a value for a request",
		Long:  "Propose a value for a data request. Requires bond to be sent with the transaction. Use --search to automatically research the value using AI.",
		Args:  cobra.RangeArgs(1, 2),
		Example: `  # Manual proposal
  goo propose value 0000001 3500
  
  # AI-powered proposal with web search
  goo propose value 0000001 --search
  
  # With custom key
  goo propose value 0000001 --search --key mykey`,
		RunE: func(cmd *cobra.Command, args []string) error {
			requestID := args[0]
			var value string

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// If --search flag is used, query AI for the value
			if searchFlag {
				// Check if API key is configured
				if cfg.GoogleAPIKey == "" {
					return fmt.Errorf("❌ Google API key not configured. Run 'goo config init' or set it manually in ~/.goo/config.yaml")
				}

				// Query request details from smart contract
				utils.PrintInfo(fmt.Sprintf("Fetching request details for ID: %s", requestID))
				requestResult, err := executor.QueryFunction("GetRequest", []string{requestID})
				if err != nil {
					return fmt.Errorf("failed to fetch request details: %w", err)
				}

				// Parse the request to get the question
				req, err := utils.ParseDataRequestFromQuery(requestResult)
				if err != nil {
					return fmt.Errorf("failed to parse request: %w", err)
				}

				question := req.AncillaryData
				isYesNo := req.YesNoQuestion
				
				fmt.Println()
				fmt.Printf("Question: %s\n", question)
				fmt.Println()

				// Initialize Gemini client
				geminiClient, err := search_agent.NewGeminiClient(cfg.GoogleAPIKey, verbose)
				if err != nil {
					fmt.Println()
					utils.PrintError(fmt.Sprintf("Failed to initialize AI client: %v", err))
					fmt.Println()
					return nil // Exit gracefully, error already displayed
				}
				defer geminiClient.Close()

				// Query Gemini for the answer
				response, err := geminiClient.QueryQuestion(question)
				if err != nil {
					fmt.Println()
					utils.PrintError(fmt.Sprintf("AI research failed: %v", err))
					fmt.Println()
					return nil // Exit gracefully, error already displayed
				}

				// Check for special error cases
				if response.Value == "FUTURE_QUESTION_ERROR" {
					fmt.Println()
					utils.PrintError("This question is about a future event")
					utils.PrintError("Oracle cannot predict the future - only answer verifiable questions")
					fmt.Println()
					return nil // Exit gracefully, error already displayed
				}

				if response.Value == "INSUFFICIENT DATA" {
					fmt.Println()
					utils.PrintWarning("AI could not find sufficient data to answer this question")
					fmt.Println()
					fmt.Println("Reason:")
					fmt.Println(response.Why)
					fmt.Println()
					return nil // Exit gracefully, error already displayed
				}

				// Validate and convert value based on question type
				proposedValue := strings.TrimSpace(response.Value)
				
				if isYesNo {
					// For yes/no questions, convert to 0 or 1
					normalizedValue := strings.ToLower(proposedValue)
					if normalizedValue == "yes" {
						proposedValue = "1"
					} else if normalizedValue == "no" {
						proposedValue = "0"
					} else {
						fmt.Println()
						utils.PrintError(fmt.Sprintf("Invalid yes/no answer from AI: '%s'", response.Value))
						fmt.Println("Expected: 'Yes' or 'No'")
						fmt.Println()
						return nil // Exit gracefully, error already displayed
					}
				} else {
					// For numeric questions, validate it's a valid number
					if !isValidNumber(proposedValue) {
						fmt.Println()
						utils.PrintError(fmt.Sprintf("Invalid numeric answer from AI: '%s'", response.Value))
						fmt.Println("Expected: A pure number like '3874' or '3874.50'")
						fmt.Println("The AI should return only the number without currency symbols, commas, or text.")
						fmt.Println()
						return nil // Exit gracefully, error already displayed
					}
				}

				// Display research results (clean output)
				fmt.Println()
				if isYesNo {
					fmt.Printf("Answer: %s → %s\n", response.Value, proposedValue)
				} else {
					fmt.Printf("Answer: %s\n", proposedValue)
				}
				fmt.Println()
				
				if response.Why != "" {
					fmt.Println("Justification:")
					// Wrap the justification text at ~80 characters
					words := strings.Fields(response.Why)
					line := ""
					for _, word := range words {
						if len(line)+len(word)+1 > 80 {
							fmt.Println(line)
							line = word
						} else {
							if line != "" {
								line += " "
							}
							line += word
						}
					}
					if line != "" {
						fmt.Println(line)
					}
					fmt.Println()
				}

				if len(response.Sources) > 0 {
					fmt.Println("Sources:")
					for i, src := range response.Sources {
						fmt.Printf("  %d. %s\n", i+1, src)
					}
					fmt.Println()
				}

				// Ask for confirmation
				fmt.Print("Propose this value? [y/N]: ")
				reader := bufio.NewReader(os.Stdin)
				confirm, _ := reader.ReadString('\n')
				confirm = strings.TrimSpace(strings.ToLower(confirm))
				
				if confirm != "y" && confirm != "yes" {
					utils.PrintInfo("Cancelled")
					return nil
				}

				value = proposedValue
				fmt.Println()

			} else {
				// Manual mode - value must be provided
				if len(args) < 2 {
					return fmt.Errorf("value argument required (or use --search flag for AI-powered proposal)")
				}
				value = args[1]
			}

			// Query the required bond amount from contract
			utils.PrintInfo("Querying required bond amount from contract...")
			bond, err := executor.QueryInt64("GetBond")
			if err != nil {
				return fmt.Errorf("failed to query bond amount: %w", err)
			}

			utils.PrintInfo(fmt.Sprintf("Bond required: %d ugnot", bond))
			fmt.Println()

			// Execute transaction with bond
			funcArgs := []string{requestID, value}
			sendAmount := fmt.Sprintf("%dugnot", bond)

			if err := executor.CallFunction("ProposeValue", funcArgs, sendAmount); err != nil {
				return err
			}

			utils.PrintSuccess("Value proposed successfully!")
			utils.PrintInfo(fmt.Sprintf("Request ID: %s", requestID))
			utils.PrintInfo(fmt.Sprintf("Proposed Value: %s", value))
			utils.PrintInfo(fmt.Sprintf("Bond sent: %d ugnot", bond))

			return nil
		},
	}

	cmd.Flags().BoolVar(&searchFlag, "search", false, "Use AI-powered search to propose a value automatically")

	return cmd
}

// isValidNumber checks if a string represents a valid number
// Accepts: integers, decimals with period, negative numbers
// Rejects: anything with non-numeric characters (including currency symbols, commas, text)
func isValidNumber(s string) bool {
	if s == "" {
		return false
	}
	
	// Try to parse as float64
	// This validates the format without additional dependencies
	var f float64
	_, err := fmt.Sscanf(s, "%f", &f)
	return err == nil
}

// NewProposeResolveCmd resolves a non-disputed request
func NewProposeResolveCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "resolve <request-id>",
		Short: "Resolve a non-disputed request",
		Long:  "Finalize a request that has not been disputed after the resolution time",
		Args:  cobra.ExactArgs(1),
		Example: `  goo propose resolve 0000001`,
		RunE: func(cmd *cobra.Command, args []string) error {
			requestID := args[0]

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// Execute transaction
			if err := executor.CallFunction("ResolveRequest", []string{requestID}, ""); err != nil {
				return err
			}

			utils.PrintSuccess("Request resolution submitted!")
			utils.PrintInfo(fmt.Sprintf("Request ID: %s", requestID))

			return nil
		},
	}

	return cmd
}
