package commands

import (
	"github.com/spf13/cobra"
)

var (
	keyOverride string
	verbose     bool
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "goo",
	Short: "GOO Oracle CLI",
	Long:  `A command-line interface for interacting with the GOO Oracle on Gno.land`,
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() error {
	return rootCmd.Execute()
}

func init() {
	// Add global flags
	rootCmd.PersistentFlags().StringVarP(&keyOverride, "key", "k", "", "Override the key name from config")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "Enable verbose output")

	// Add all subcommands
	rootCmd.AddCommand(NewConfigCmd())
	rootCmd.AddCommand(NewRequestCmd())
	rootCmd.AddCommand(NewProposeCmd())
	rootCmd.AddCommand(NewDisputeCmd())
	rootCmd.AddCommand(NewVoteCmd())
	rootCmd.AddCommand(NewQueryCmd())
	rootCmd.AddCommand(NewAdminCmd())
}
