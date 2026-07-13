package commands

import (
	"fmt"

	"github.com/spf13/cobra"

	"goo-cli/internal/config"
	"goo-cli/internal/gnokey"
	"goo-cli/internal/utils"
)

// NewRequestCmd creates the request command
func NewRequestCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "request",
		Short: "Manage data requests",
		Long:  "Create, query, and manage data requests in the oracle",
	}

	cmd.AddCommand(NewRequestCreateCmd())
	cmd.AddCommand(NewRequestGetCmd())
	cmd.AddCommand(NewRequestRetrieveFundCmd())

	return cmd
}

// NewRequestCreateCmd creates a new data request
func NewRequestCreateCmd() *cobra.Command {
	var (
		question string
		yesno    bool
		deadline string
		reward   int64
	)

	cmd := &cobra.Command{
		Use:   "create",
		Short: "Create a new data request",
		Long:  "Create a new data request with specified question, type, deadline, and reward",
		Example: `  goo request create \
    --question "What is the ETH/USD price on 2025-10-27 12:00 UTC?" \
    --deadline "2025-10-28T12:00:00Z" \
    --reward 1000000

  # For yes/no questions, use --yesno flag
  goo request create \
    --question "Did BTC reach $100,000 by 2025-10-27?" \
    --yesno \
    --deadline "2025-10-28T12:00:00Z" \
    --reward 1000000`,
		RunE: func(cmd *cobra.Command, args []string) error {
			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// Parse deadline
			deadlineTime, err := utils.ParseDeadline(deadline)
			if err != nil {
				return err
			}

			// If reward is 0, query the default requester reward from contract
			if reward == 0 {
				utils.PrintInfo("Querying default requester reward from contract...")
				reward, err = executor.QueryInt64("GetRequesterReward")
				if err != nil {
					return fmt.Errorf("failed to query requester reward: %w", err)
				}
				utils.PrintInfo(fmt.Sprintf("Default reward: %d ugnot", reward))
			}

			// Prepare function arguments
			funcArgs := []string{
				question,                                // ancillaryData
				utils.FormatBool(yesno),                // yesNoQuestion
				fmt.Sprintf("%d", deadlineTime.Unix()), // deadline
			}

			sendAmount := fmt.Sprintf("%dugnot", reward)

			// Execute transaction
			if err := executor.CallFunction("RequestData", funcArgs, sendAmount); err != nil {
				return err
			}

			utils.PrintSuccess("Request created successfully!")
			utils.PrintInfo(fmt.Sprintf("Question: %s", question))
			if yesno {
				utils.PrintInfo("Type: yes/no question")
			} else {
				utils.PrintInfo("Type: numeric")
			}
			utils.PrintInfo(fmt.Sprintf("Deadline: %s", utils.FormatTimeRFC3339(deadlineTime)))
			utils.PrintInfo(fmt.Sprintf("Reward sent: %d ugnot", reward))

			return nil
		},
	}

	cmd.Flags().StringVar(&question, "question", "", "Question or ancillary data for the request")
	cmd.Flags().BoolVar(&yesno, "yesno", false, "Set to true for yes/no questions (default: numeric)")
	cmd.Flags().StringVar(&deadline, "deadline", "", "Deadline in RFC3339 format (e.g., 2025-10-28T12:00:00Z)")
	cmd.Flags().Int64Var(&reward, "reward", 0, "Reward amount in ugnot (default: query from contract)")

	cmd.MarkFlagRequired("question")
	cmd.MarkFlagRequired("deadline")

	return cmd
}

// NewRequestGetCmd gets details of a request
func NewRequestGetCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "get <request-id>",
		Short: "Get details of a specific request",
		Args:  cobra.ExactArgs(1),
		Example: `  goo request get 0000001`,
		RunE: func(cmd *cobra.Command, args []string) error {
			requestID := args[0]

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// Query the request
			result, err := executor.QueryFunction("GetRequest", []string{requestID})
			if err != nil {
				return err
			}

			// Parse the request data
			req, err := utils.ParseDataRequestFromQuery(result)
			if err != nil {
				// If parsing fails, show raw output in verbose mode
				if verbose {
					utils.PrintError(fmt.Sprintf("Failed to parse request: %v", err))
					fmt.Println(result)
				}
				return fmt.Errorf("failed to parse request data: %w", err)
			}

			// Display request information in a clean format
			utils.PrintSection(fmt.Sprintf("Request %s", req.ID))
			fmt.Println()

			// Basic Information
			fmt.Println("Basic Information:")
			utils.PrintKeyValue("  Request ID", req.ID)
			utils.PrintKeyValue("  State", req.State)
			utils.PrintKeyValue("  Creator", req.Creator)
			utils.PrintKeyValue("  Question", req.AncillaryData)
			if req.YesNoQuestion {
				utils.PrintKeyValue("  Type", "Yes/No Question")
			} else {
				utils.PrintKeyValue("  Type", "Numeric")
			}
			// Note: Timestamps/Deadlines are stored as time.Time and can't be parsed from query output
			// To display them, the contract would need getter functions that return Unix timestamps

			// Proposal Information
			fmt.Println()
			fmt.Println("Proposal Information:")
			if req.Proposer != "" {
				utils.PrintKeyValue("  Proposer", req.Proposer)
				utils.PrintKeyValue("  Proposed Value", req.ProposedValue)
				utils.PrintKeyValue("  Proposer Bond", fmt.Sprintf("%d ugnot", req.ProposerBond))
			} else {
				utils.PrintKeyValue("  Status", "No proposal yet")
			}

			// Dispute Information
			fmt.Println()
			fmt.Println("Dispute Information:")
			if req.Disputer != "" {
				utils.PrintKeyValue("  Disputer", req.Disputer)
				utils.PrintKeyValue("  Disputer Bond", fmt.Sprintf("%d ugnot", req.DisputerBond))
			} else {
				utils.PrintKeyValue("  Status", "Not disputed")
			}

			// Resolution Information
			if req.State == "Resolved" {
				fmt.Println()
				fmt.Println("Resolution:")
				utils.PrintKeyValue("  Winning Value", req.WinningValue)
			}

			fmt.Println()

			return nil
		},
	}

	return cmd
}

// NewRequestRetrieveFundCmd retrieves fund from unfulfilled request
func NewRequestRetrieveFundCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "retrieve-fund <request-id>",
		Short: "Retrieve reward from unfulfilled request",
		Long:  "Retrieve the reward from a request that was not fulfilled before the deadline",
		Args:  cobra.ExactArgs(1),
		Example: `  goo request retrieve-fund 0000001`,
		RunE: func(cmd *cobra.Command, args []string) error {
			requestID := args[0]

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// Execute transaction
			if err := executor.CallFunction("RequesterRetreiveFund", []string{requestID}, ""); err != nil {
				return err
			}

			utils.PrintSuccess("Fund retrieval transaction submitted!")
			utils.PrintInfo(fmt.Sprintf("Request ID: %s", requestID))

			return nil
		},
	}

	return cmd
}
