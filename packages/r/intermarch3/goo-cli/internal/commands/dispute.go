package commands

import (
	"fmt"

	"github.com/spf13/cobra"

	"goo-cli/internal/config"
	"goo-cli/internal/gnokey"
	"goo-cli/internal/utils"
)

// NewDisputeCmd creates the dispute command
func NewDisputeCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "dispute",
		Short: "Manage disputes",
		Long:  "Create, query, and resolve disputes on proposed values",
	}

	cmd.AddCommand(NewDisputeCreateCmd())
	cmd.AddCommand(NewDisputeGetCmd())
	cmd.AddCommand(NewDisputeResolveCmd())

	return cmd
}

// NewDisputeCreateCmd creates a new dispute
func NewDisputeCreateCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "create <request-id>",
		Short: "Create a dispute on a proposed value",
		Long:  "Challenge a proposed value by creating a dispute. Requires bond to be sent with the transaction.",
		Args:  cobra.ExactArgs(1),
		Example: `  goo dispute create 0000001`,
		RunE: func(cmd *cobra.Command, args []string) error {
			requestID := args[0]

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// Query the required bond amount from contract
			utils.PrintInfo("Querying required bond amount from contract...")
			bond, err := executor.QueryInt64("GetBond")
			if err != nil {
				return fmt.Errorf("failed to query bond amount: %w", err)
			}

			utils.PrintInfo(fmt.Sprintf("Bond required: %d ugnot", bond))

			// Execute transaction with bond
			sendAmount := fmt.Sprintf("%dugnot", bond)
			if err := executor.CallFunction("DisputeData", []string{requestID}, sendAmount); err != nil {
				return err
			}

			utils.PrintSuccess("Dispute created successfully!")
			utils.PrintInfo(fmt.Sprintf("Request ID: %s", requestID))
			utils.PrintInfo("Voting period has started")
			utils.PrintInfo(fmt.Sprintf("Bond sent: %d ugnot", bond))

			return nil
		},
	}

	return cmd
}

// NewDisputeGetCmd gets details of a dispute
func NewDisputeGetCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "get <request-id>",
		Short: "Get details of a dispute",
		Long:  "Retrieve details about a dispute including vote counts and timing",
		Args:  cobra.ExactArgs(1),
		Example: `  goo dispute get 0000001`,
		RunE: func(cmd *cobra.Command, args []string) error {
			requestID := args[0]

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// Query the dispute
			result, err := executor.QueryFunction("GetDispute", []string{requestID})
			if err != nil {
				return err
			}

			// Parse the dispute data
			dispute, err := utils.ParseDisputeFromQuery(result)
			if err != nil {
				// If parsing fails, show raw output in verbose mode
				if verbose {
					utils.PrintError(fmt.Sprintf("Failed to parse dispute: %v", err))
					fmt.Println(result)
				}
				return fmt.Errorf("failed to parse dispute data: %w", err)
			}

			// Display dispute information in a clean format
			utils.PrintSection(fmt.Sprintf("Dispute for Request %s", dispute.RequestID))
			fmt.Println()

			// Status Information
			fmt.Println("Status:")
			utils.PrintKeyValue("  Request ID", dispute.RequestID)
			if dispute.IsResolved {
				utils.PrintKeyValue("  Status", "Resolved")
				utils.PrintKeyValue("  Winning Value", dispute.WinningValue)
			} else {
				utils.PrintKeyValue("  Status", "Active")
			}

			// Voting Information
			fmt.Println()
			fmt.Println("Voting:")
			utils.PrintKeyValue("  Total Votes", dispute.Votes)
			utils.PrintKeyValue("  Revealed Votes", dispute.NbResolvedVotes)
			unrevealed := int64(dispute.Votes) - dispute.NbResolvedVotes
			utils.PrintKeyValue("  Unrevealed Votes", unrevealed)
			fmt.Println()

			return nil
		},
	}

	return cmd
}

// NewDisputeResolveCmd resolves a dispute
func NewDisputeResolveCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "resolve <request-id>",
		Short: "Resolve a dispute after voting period",
		Long:  "Finalize a dispute after the reveal period has ended",
		Args:  cobra.ExactArgs(1),
		Example: `  goo dispute resolve 0000001`,
		RunE: func(cmd *cobra.Command, args []string) error {
			requestID := args[0]

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// Execute transaction
			if err := executor.CallFunction("ResolveDispute", []string{requestID}, ""); err != nil {
				return err
			}

			utils.PrintSuccess("Dispute resolution submitted!")
			utils.PrintInfo(fmt.Sprintf("Request ID: %s", requestID))

			return nil
		},
	}

	return cmd
}
