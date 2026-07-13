package commands

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/spf13/cobra"

	"goo-cli/internal/config"
	"goo-cli/internal/utils"
)

// NewConfigCmd creates the config command
func NewConfigCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "config",
		Short: "Manage CLI configuration",
		Long:  "Initialize and manage the CLI configuration file",
	}

	cmd.AddCommand(NewConfigInitCmd())
	cmd.AddCommand(NewConfigShowCmd())

	return cmd
}

// NewConfigInitCmd initializes the config file
func NewConfigInitCmd() *cobra.Command {
	var force bool
	
	cmd := &cobra.Command{
		Use:   "init",
		Short: "Initialize configuration file",
		Long:  "Create a new configuration file with default values at ~/.goo/config.yaml",
		Example: `  goo config init
  goo config init --force  # Overwrite existing config`,
		RunE: func(cmd *cobra.Command, args []string) error {
			configPath, err := config.GetConfigPath()
			if err != nil {
				return err
			}

			// Check if config already exists
			if _, err := os.Stat(configPath); err == nil {
				if !force {
					return fmt.Errorf("config file already exists at %s (use --force to overwrite)", configPath)
				}
				utils.PrintWarning("Overwriting existing configuration...")
			}

			reader := bufio.NewReader(os.Stdin)

			// Create config with default values
			cfg := config.DefaultConfig()

			fmt.Println()
			fmt.Println("🔧 GOO CLI Configuration")
			fmt.Println("═══════════════════════════")
			fmt.Println()

			// 1. Ask for key name
			fmt.Print("Enter your gnokey name (default: test): ")
			keyName, _ := reader.ReadString('\n')
			keyName = strings.TrimSpace(keyName)
			if keyName != "" {
				cfg.KeyName = keyName
			}

			// 2. Ask for network type
			fmt.Println()
			fmt.Println("Select network:")
			fmt.Println("  1. Development (local dev network)")
			fmt.Println("  2. Custom (specify chain ID and remote)")
			fmt.Print("Choice [1/2] (default: 1): ")
			
			choice, _ := reader.ReadString('\n')
			choice = strings.TrimSpace(choice)

			if choice == "2" {
				// Custom network
				fmt.Println()
				fmt.Print("Enter Chain ID: ")
				chainID, _ := reader.ReadString('\n')
				chainID = strings.TrimSpace(chainID)
				if chainID != "" {
					cfg.ChainID = chainID
				}

				fmt.Print("Enter Remote URL: ")
				remote, _ := reader.ReadString('\n')
				remote = strings.TrimSpace(remote)
				if remote != "" {
					cfg.Remote = remote
				}
			} else {
				// Dev network (default)
				cfg.ChainID = "dev"
				cfg.Remote = "tcp://127.0.0.1:26657"
				utils.PrintInfo("Using dev network (chain_id: dev, remote: tcp://127.0.0.1:26657)")
			}

			// 3. Ask for Google API key (optional)
			fmt.Println()
			fmt.Println("🔍 AI-Powered Proposals (Optional)")
			fmt.Println("───────────────────────────────────")
			fmt.Println("Enable AI to automatically research and propose values using Google Gemini.")
			fmt.Println()
			fmt.Print("Enter Google API Key (leave empty to skip): ")

			apiKey, _ := reader.ReadString('\n')
			apiKey = strings.TrimSpace(apiKey)

			if apiKey != "" {
				cfg.GoogleAPIKey = apiKey
				utils.PrintSuccess("Google API key configured")
			} else {
				utils.PrintInfo("Skipped - you can add it later in ~/.goo/config.yaml")
			}

			// Save config
			if err := config.Save(cfg); err != nil {
				return err
			}

			// Display summary
			fmt.Println()
			utils.PrintSuccess(fmt.Sprintf("Config file created at %s", configPath))
			fmt.Println()
			fmt.Println("Configuration:")
			fmt.Printf("  Key Name:       %s\n", cfg.KeyName)
			fmt.Printf("  Realm Path:     %s\n", cfg.RealmPath)
			fmt.Printf("  Chain ID:       %s\n", cfg.ChainID)
			fmt.Printf("  Remote:         %s\n", cfg.Remote)
			fmt.Printf("  Gas Fee:        %s\n", cfg.GasFee)
			fmt.Printf("  Gas Wanted:     %d\n", cfg.GasWanted)
			if cfg.GoogleAPIKey != "" {
				maskedKey := cfg.GoogleAPIKey
				if len(maskedKey) > 8 {
					maskedKey = maskedKey[:8] + "..."
				}
				fmt.Printf("  Google API Key: %s\n", maskedKey)
			} else {
				fmt.Printf("  Google API Key: (not configured)\n")
			}
			fmt.Println()
			fmt.Println("💡 You can edit this file anytime: ~/.goo/config.yaml")

			if cfg.GoogleAPIKey == "" {
				fmt.Println()
				fmt.Println("To enable AI-powered proposals later:")
				fmt.Println("  1. Get a free API key: https://makersuite.google.com/app/apikey")
				fmt.Println("  2. Edit ~/.goo/config.yaml and add:")
				fmt.Println("     google_api_key: your-api-key-here")
				fmt.Println("  3. Use: goo propose value <id> --search")
			}

			return nil
		},
	}

	cmd.Flags().BoolVarP(&force, "force", "f", false, "Overwrite existing configuration file")

	return cmd
}

// NewConfigShowCmd displays the current configuration
func NewConfigShowCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "show",
		Short: "Show current configuration",
		Long:  "Display the current CLI configuration",
		Example: `  goo config show`,
		RunE: func(cmd *cobra.Command, args []string) error {
			cfg := config.Load()

			utils.PrintSection("Current Configuration")
			utils.PrintKeyValue("Key Name", cfg.KeyName)
			utils.PrintKeyValue("Realm Path", cfg.RealmPath)
			utils.PrintKeyValue("Chain ID", cfg.ChainID)
			utils.PrintKeyValue("Remote", cfg.Remote)
			utils.PrintKeyValue("Gas Fee", cfg.GasFee)
			utils.PrintKeyValue("Gas Wanted", cfg.GasWanted)
			
			if cfg.GoogleAPIKey != "" {
				maskedKey := cfg.GoogleAPIKey
				if len(maskedKey) > 8 {
					maskedKey = maskedKey[:8] + "..."
				}
				utils.PrintKeyValue("Google API Key", maskedKey)
			} else {
				utils.PrintKeyValue("Google API Key", "(not configured)")
			}
			fmt.Println()

			configPath, err := config.GetConfigPath()
			if err == nil {
				utils.PrintInfo(fmt.Sprintf("Config file: %s", configPath))
			}

			return nil
		},
	}

	return cmd
}
