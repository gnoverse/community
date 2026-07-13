package config

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/viper"
	"gopkg.in/yaml.v3"
)

// Config holds the CLI configuration
type Config struct {
	KeyName      string `yaml:"keyname" mapstructure:"keyname"`
	RealmPath    string `yaml:"realm_path" mapstructure:"realm_path"`
	ChainID      string `yaml:"chain_id" mapstructure:"chain_id"`
	Remote       string `yaml:"remote" mapstructure:"remote"`
	GasFee       string `yaml:"gas_fee" mapstructure:"gas_fee"`
	GasWanted    int64  `yaml:"gas_wanted" mapstructure:"gas_wanted"`
	GoogleAPIKey string `yaml:"google_api_key" mapstructure:"google_api_key"`
}

// DefaultConfig returns a config with default values
func DefaultConfig() *Config {
	return &Config{
		KeyName:    "mykey",
		RealmPath:  "gno.land/r/intermarch3/goo",
		ChainID:    "dev",
		Remote:     "tcp://127.0.0.1:26657",
		GasFee:     "1000000ugnot",
		GasWanted:  20000000,
	}
}

// GetConfigPath returns the path to the config file
func GetConfigPath() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}
	return filepath.Join(homeDir, ".goo", "config.yaml"), nil
}

// Load reads the configuration from file or returns defaults
func Load() *Config {
	configPath, err := GetConfigPath()
	if err != nil {
		fmt.Printf("Warning: %v, using defaults\n", err)
		return DefaultConfig()
	}

	viper.SetConfigFile(configPath)
	viper.SetConfigType("yaml")

	if err := viper.ReadInConfig(); err != nil {
		// If config doesn't exist, return defaults
		if os.IsNotExist(err) {
			return DefaultConfig()
		}
		fmt.Printf("Warning: failed to read config: %v, using defaults\n", err)
		return DefaultConfig()
	}

	var cfg Config
	if err := viper.Unmarshal(&cfg); err != nil {
		fmt.Printf("Warning: failed to parse config: %v, using defaults\n", err)
		return DefaultConfig()
	}

	return &cfg
}

// LoadWithKeyOverride loads config and overrides the key name if provided
func LoadWithKeyOverride(keyOverride string) *Config {
	cfg := Load()
	if keyOverride != "" {
		cfg.KeyName = keyOverride
	}
	return cfg
}

// Save writes the configuration to file
func Save(cfg *Config) error {
	configPath, err := GetConfigPath()
	if err != nil {
		return err
	}

	// Create directory if it doesn't exist
	configDir := filepath.Dir(configPath)
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	// Marshal to YAML
	data, err := yaml.Marshal(cfg)
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	// Write to file
	if err := os.WriteFile(configPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}

	return nil
}

// InitConfig creates a new config file with default values
func InitConfig() error {
	configPath, err := GetConfigPath()
	if err != nil {
		return err
	}

	// Check if config already exists
	if _, err := os.Stat(configPath); err == nil {
		return fmt.Errorf("config file already exists at %s", configPath)
	}

	// Save default config
	cfg := DefaultConfig()
	if err := Save(cfg); err != nil {
		return err
	}

	fmt.Printf("✓ Config file created at %s\n", configPath)
	fmt.Println("\nDefault configuration:")
	fmt.Printf("  Key Name:      %s\n", cfg.KeyName)
	fmt.Printf("  Realm Path:    %s\n", cfg.RealmPath)
	fmt.Printf("  Chain ID:      %s\n", cfg.ChainID)
	fmt.Printf("  Remote:        %s\n", cfg.Remote)
	fmt.Printf("  Gas Fee:       %s\n", cfg.GasFee)
	fmt.Printf("  Gas Wanted:    %d\n", cfg.GasWanted)
	if cfg.GoogleAPIKey != "" {
		fmt.Printf("  Google API Key: %s\n", cfg.GoogleAPIKey[:min(8, len(cfg.GoogleAPIKey))]+"...")
	} else {
		fmt.Printf("  Google API Key: (not configured)\n")
	}
	fmt.Println("\nEdit this file to customize your settings.")

	return nil
}

// min returns the minimum of two integers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
