package commands

import (
	"fmt"
	"strconv"

	"github.com/spf13/cobra"

	"goo-cli/internal/config"
	"goo-cli/internal/gnokey"
	"goo-cli/internal/utils"
)

// NewAdminCmd creates the admin command
func NewAdminCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "admin",
		Short: "Admin operations",
		Long:  "Administrative commands for managing oracle parameters (requires admin privileges)",
	}

	cmd.AddCommand(NewAdminSetResolutionDurationCmd())
	cmd.AddCommand(NewAdminSetRewardCmd())
	cmd.AddCommand(NewAdminSetBondCmd())
	cmd.AddCommand(NewAdminChangeAdminCmd())

	return cmd
}

// NewAdminSetResolutionDurationCmd sets resolution duration
func NewAdminSetResolutionDurationCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "set-resolution-duration <seconds>",
		Short: "Set the resolution duration",
		Long:  "Update the time window for resolving non-disputed proposals (admin only)",
		Args:  cobra.ExactArgs(1),
		Example: `  goo admin set-resolution-duration 120`,
		RunE: func(cmd *cobra.Command, args []string) error {
			duration, err := strconv.ParseInt(args[0], 10, 64)
			if err != nil {
				return fmt.Errorf("invalid duration: %w", err)
			}

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			utils.PrintWarning("This operation requires admin privileges!")

			// Execute transaction
			funcArgs := []string{fmt.Sprintf("%d", duration)}
			if err := executor.CallFunction("SetResolutionDuration", funcArgs, ""); err != nil {
				return err
			}

			utils.PrintSuccess("Resolution duration updated!")
			utils.PrintInfo(fmt.Sprintf("New duration: %d seconds (%s)", duration, utils.FormatDuration(utils.DurationFromSeconds(duration))))

			return nil
		},
	}

	return cmd
}

// NewAdminSetRewardCmd sets requester reward
func NewAdminSetRewardCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "set-reward <amount>",
		Short: "Set the requester reward amount",
		Long:  "Update the default reward amount for requesters (admin only)",
		Args:  cobra.ExactArgs(1),
		Example: `  goo admin set-reward 2000000`,
		RunE: func(cmd *cobra.Command, args []string) error {
			amount, err := strconv.ParseInt(args[0], 10, 64)
			if err != nil {
				return fmt.Errorf("invalid amount: %w", err)
			}

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			utils.PrintWarning("This operation requires admin privileges!")

			// Execute transaction
			funcArgs := []string{fmt.Sprintf("%d", amount)}
			if err := executor.CallFunction("SetrequesterReward", funcArgs, ""); err != nil {
				return err
			}

			utils.PrintSuccess("Requester reward updated!")
			utils.PrintInfo(fmt.Sprintf("New reward: %s", utils.FormatUgnot(amount)))

			return nil
		},
	}

	return cmd
}

// NewAdminSetBondCmd sets bond amount
func NewAdminSetBondCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "set-bond <amount>",
		Short: "Set the bond amount",
		Long:  "Update the bond amount required for proposals and disputes (admin only)",
		Args:  cobra.ExactArgs(1),
		Example: `  goo admin set-bond 3000000`,
		RunE: func(cmd *cobra.Command, args []string) error {
			amount, err := strconv.ParseInt(args[0], 10, 64)
			if err != nil {
				return fmt.Errorf("invalid amount: %w", err)
			}

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			utils.PrintWarning("This operation requires admin privileges!")

			// Execute transaction
			funcArgs := []string{fmt.Sprintf("%d", amount)}
			if err := executor.CallFunction("SetBond", funcArgs, ""); err != nil {
				return err
			}

			utils.PrintSuccess("Bond amount updated!")
			utils.PrintInfo(fmt.Sprintf("New bond: %s", utils.FormatUgnot(amount)))

			return nil
		},
	}

	return cmd
}

// NewAdminChangeAdminCmd changes the admin address
func NewAdminChangeAdminCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "change-admin <address>",
		Short: "Transfer admin privileges",
		Long:  "Change the admin address to a new address (admin only)",
		Args:  cobra.ExactArgs(1),
		Example: `  goo admin change-admin g1abcdef...`,
		RunE: func(cmd *cobra.Command, args []string) error {
			newAdmin := args[0]

			keyOverride, _ := cmd.Flags().GetString("key")
			verbose, _ := cmd.Flags().GetBool("verbose")
			cfg := config.LoadWithKeyOverride(keyOverride)
			executor := gnokey.NewExecutor(cfg, verbose)

			utils.PrintWarning("This operation requires admin privileges!")
			utils.PrintWarning(fmt.Sprintf("You are transferring admin rights to: %s", newAdmin))

			// Execute transaction
			funcArgs := []string{newAdmin}
			if err := executor.CallFunction("ChangeAdmin", funcArgs, ""); err != nil {
				return err
			}

			utils.PrintSuccess("Admin changed successfully!")
			utils.PrintInfo(fmt.Sprintf("New admin: %s", newAdmin))

			return nil
		},
	}

	return cmd
}
