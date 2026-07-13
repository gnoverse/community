package commands

import (
	"fmt"

	"github.com/spf13/cobra"

	"goo-cli/internal/config"
	"goo-cli/internal/gnokey"
	"goo-cli/internal/utils"
)

// NewVoteCmd creates the vote command
func NewVoteCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "vote",
		Short: "Manage voting on disputes",
		Long:  "Buy tokens, commit votes, reveal votes, and check balance",
	}

	cmd.AddCommand(NewVoteBuyTokenCmd())
	cmd.AddCommand(NewVoteBalanceCmd())
	cmd.AddCommand(NewVoteCommitCmd())
	cmd.AddCommand(NewVoteRevealCmd())

	return cmd
}

// NewVoteBuyTokenCmd buys initial vote tokens
func NewVoteBuyTokenCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "buy-token",
		Short: "Buy initial vote token",
		Long:  "Purchase the initial vote token required to participate in voting",
		Example: `  goo vote buy-token`,
		RunE: func(cmd *cobra.Command, args []string) error {
			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// Query the vote token price from contract
			utils.PrintInfo("Querying vote token price from contract...")
			price, err := executor.QueryInt64("GetVoteTokenPrice")
			if err != nil {
				return fmt.Errorf("failed to query vote token price: %w", err)
			}

			utils.PrintInfo(fmt.Sprintf("Vote token price: %d ugnot", price))

			// Execute transaction
			sendAmount := fmt.Sprintf("%dugnot", price)
			if err := executor.CallFunction("BuyInitialVoteToken", []string{}, sendAmount); err != nil {
				return err
			}

			utils.PrintSuccess("Vote token purchased successfully!")
			utils.PrintInfo(fmt.Sprintf("Price paid: %d ugnot", price))

			return nil
		},
	}

	return cmd
}

// NewVoteBalanceCmd checks vote token balance
func NewVoteBalanceCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "balance",
		Short: "Check vote token balance",
		Long:  "Query your current vote token balance (requires signing)",
		Example: `  goo vote balance`,
		RunE: func(cmd *cobra.Command, args []string) error {
			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// Call as transaction since it requires realm context
			if err := executor.CallFunction("BalanceOfVoteToken", []string{}, ""); err != nil {
				return err
			}

			utils.PrintSuccess("Balance query executed successfully!")

			return nil
		},
	}

	return cmd
}

// NewVoteCommitCmd commits a vote
func NewVoteCommitCmd() *cobra.Command {
	var salt string

	cmd := &cobra.Command{
		Use:   "commit <request-id> <value>",
		Short: "Commit a vote on a dispute",
		Long:  "Submit a hashed vote during the voting period. The hash will be revealed later.",
		Args:  cobra.ExactArgs(2),
		Example: `  goo vote commit 0000001 3500
  goo vote commit 0000001 3500 --salt my-random-salt`,
		RunE: func(cmd *cobra.Command, args []string) error {
			requestID := args[0]
			value := args[1]

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// Auto-generate salt if not provided
			if salt == "" {
				salt = utils.GenerateRandomSalt(32)
				utils.PrintInfo(fmt.Sprintf("Auto-generated salt: %s", salt))
			}

			// Generate hash
			hash := utils.GenerateVoteHash(value, salt)

			// Execute transaction
			funcArgs := []string{requestID, hash}
			if err := executor.CallFunction("VoteOnDispute", funcArgs, ""); err != nil {
				return err
			}

			// Save vote data locally
			if err := gnokey.SaveVoteLocally(requestID, value, salt, hash); err != nil {
				utils.PrintWarning(fmt.Sprintf("Failed to save vote locally: %v", err))
			}

			utils.PrintSuccess("Vote committed successfully!")
			utils.PrintInfo(fmt.Sprintf("Request ID: %s", requestID))
			utils.PrintInfo(fmt.Sprintf("Value: %s", value))
			utils.PrintInfo(fmt.Sprintf("Hash: %s", hash))
			utils.PrintInfo("Vote data saved locally for reveal phase")

			return nil
		},
	}

	cmd.Flags().StringVar(&salt, "salt", "", "Salt for vote hash (auto-generated if not provided)")

	return cmd
}

// NewVoteRevealCmd reveals a committed vote
func NewVoteRevealCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "reveal <request-id>",
		Short: "Reveal a committed vote",
		Long:  "Reveal your vote during the reveal period using locally stored vote data",
		Args:  cobra.ExactArgs(1),
		Example: `  goo vote reveal 0000001`,
		RunE: func(cmd *cobra.Command, args []string) error {
			requestID := args[0]

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			// Load vote data from local storage
			value, salt, err := gnokey.LoadVoteLocally(requestID)
			if err != nil {
				return fmt.Errorf("failed to load vote data: %w", err)
			}

			// Execute transaction
			funcArgs := []string{requestID, value, salt}
			if err := executor.CallFunction("RevealVote", funcArgs, ""); err != nil {
				return err
			}

			utils.PrintSuccess("Vote revealed successfully!")
			utils.PrintInfo(fmt.Sprintf("Request ID: %s", requestID))
			utils.PrintInfo(fmt.Sprintf("Value: %s", value))

			return nil
		},
	}

	return cmd
}
