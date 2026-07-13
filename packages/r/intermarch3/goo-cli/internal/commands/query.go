package commands

import (
	"fmt"

	"github.com/spf13/cobra"

	"goo-cli/internal/config"
	"goo-cli/internal/gnokey"
	"goo-cli/internal/utils"
)

// NewQueryCmd creates the query command
func NewQueryCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "query",
		Short: "Query oracle data",
		Long:  "Read-only queries for oracle state and parameters",
	}

	cmd.AddCommand(NewQueryResultCmd())
	cmd.AddCommand(NewQueryParamsCmd())
	cmd.AddCommand(NewQueryListCmd())

	return cmd
}

// NewQueryResultCmd queries the result of a request
func NewQueryResultCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "result <request-id>",
		Short: "Get the final result of a request",
		Long:  "Query the winning value for a resolved request (requires signing)",
		Args:  cobra.ExactArgs(1),
		Example: `  goo query result 0000001`,
		RunE: func(cmd *cobra.Command, args []string) error {
			requestID := args[0]

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// Call as transaction since it requires realm context
			if err := executor.CallFunction("RequestResult", []string{requestID}, ""); err != nil {
				return err
			}

			utils.PrintSuccess(fmt.Sprintf("Result query for request %s executed successfully!", requestID))

			return nil
		},
	}

	return cmd
}

// NewQueryParamsCmd queries oracle parameters
func NewQueryParamsCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "params",
		Short: "Get oracle parameters",
		Long:  "Query all oracle configuration parameters",
		Example: `  goo query params`,
		RunE: func(cmd *cobra.Command, args []string) error {
			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			utils.PrintSection("Oracle Parameters")

			// Query each parameter
			params := []struct {
				name     string
				funcName string
			}{
				{"Bond", "GetBond"},
				{"Resolution Time", "GetResolutionTime"},
				{"Requester Reward", "GetRequesterReward"},
				{"Dispute Duration", "GetDisputeDuration"},
				{"Reveal Duration", "GetRevealDuration"},
				{"Vote Token Price", "GetVoteTokenPrice"},
			}

			for _, p := range params {
				result, err := executor.QueryFunction(p.funcName, []string{})
				if err != nil {
					utils.PrintError(fmt.Sprintf("Failed to query %s: %v", p.name, err))
					continue
				}
				utils.PrintKeyValue(p.name, result)
			}

			return nil
		},
	}

	return cmd
}

// NewQueryListCmd lists requests with their states
func NewQueryListCmd() *cobra.Command {
	var stateFilter string

	cmd := &cobra.Command{
		Use:   "list",
		Short: "List all requests with their states",
		Long:  "Query and display all requests with their current states",
		Example: `  goo query list
  goo query list --state Proposed`,
		RunE: func(cmd *cobra.Command, args []string) error {
			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// Validate state filter if provided
			if stateFilter != "" {
				validStates := []string{"Requested", "Proposed", "Disputed", "Resolved"}
				isValid := false
				for _, valid := range validStates {
					if stateFilter == valid {
						isValid = true
						break
					}
				}
				if !isValid {
					return fmt.Errorf("invalid state '%s'. Valid states are: Requested, Proposed, Disputed, Resolved", stateFilter)
				}
			}

			// Query request IDs based on filter
			var queryFunc string
			var queryArgs []string
			if stateFilter != "" {
				queryFunc = "GetRequestsIdsWithState"
				queryArgs = []string{stateFilter}
			} else {
				queryFunc = "GetRequestsIds"
				queryArgs = []string{}
			}

			result, err := executor.QueryFunction(queryFunc, queryArgs)
			if err != nil {
				return err
			}

			// Parse the request IDs from the query result
			requestIDs, err := utils.ParseStringArrayFromQuery(result)
			if err != nil {
				return fmt.Errorf("failed to parse request IDs: %w", err)
			}

			if len(requestIDs) == 0 {
				if stateFilter != "" {
					utils.PrintInfo(fmt.Sprintf("No requests found with state: %s", stateFilter))
				} else {
					utils.PrintInfo("No requests found")
				}
				return nil
			}

			// Print header
			if stateFilter != "" {
				utils.PrintSuccess(fmt.Sprintf("Requests (filtered by state: %s)", stateFilter))
			} else {
				utils.PrintSuccess("All Requests")
			}
			fmt.Println()
			fmt.Printf("%-12s %-50s %-15s\n", "Request ID", "Question", "State")
			fmt.Println(fmt.Sprintf("%s %s %s", "------------", "--------------------------------------------------", "---------------"))

			// Query and display details for each request
			for _, id := range requestIDs {
				// Get full request to extract question
				requestResult, err := executor.QueryFunction("GetRequest", []string{id})
				if err != nil {
					fmt.Printf("%-12s %-50s %-15s\n", id, "Error", "Error")
					continue
				}

				// Parse request to get question and state
				req, err := utils.ParseDataRequestFromQuery(requestResult)
				if err != nil {
					fmt.Printf("%-12s %-50s %-15s\n", id, "Parse Error", "Error")
					continue
				}

				// Truncate question if too long
				question := utils.TruncateString(req.AncillaryData, 50)
				fmt.Printf("%-12s %-50s %-15s\n", id, question, req.State)
			}

			fmt.Println()
			utils.PrintInfo(fmt.Sprintf("Total: %d request(s)", len(requestIDs)))

			return nil
		},
	}

	cmd.Flags().StringVar(&stateFilter, "state", "", "Filter by state: Requested, Proposed, Disputed, Resolved")

	return cmd
}
