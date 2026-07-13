package gnokey

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	"goo-cli/internal/config"
	"goo-cli/internal/utils"
)

// TxExecutor handles execution of gnokey transactions
type TxExecutor struct {
	KeyName   string
	RealmPath string
	ChainID   string
	Remote    string
	GasFee    string
	GasWanted int64
	Verbose   bool
}

// NewExecutor creates a new TxExecutor from config
func NewExecutor(cfg *config.Config, verbose bool) *TxExecutor {
	return &TxExecutor{
		KeyName:   cfg.KeyName,
		RealmPath: cfg.RealmPath,
		ChainID:   cfg.ChainID,
		Remote:    cfg.Remote,
		GasFee:    cfg.GasFee,
		GasWanted: cfg.GasWanted,
		Verbose:   verbose,
	}
}

// CallFunction executes a function call (transaction)
func (e *TxExecutor) CallFunction(funcName string, args []string, sendCoins string) error {
	// Build command arguments
	cmdArgs := []string{
		"maketx", "call",
		"--pkgpath", e.RealmPath,
		"--func", funcName,
		"--gas-fee", e.GasFee,
		"--gas-wanted", fmt.Sprintf("%d", e.GasWanted),
		"--broadcast",
		"--chainid", e.ChainID,
		"--remote", e.Remote,
	}

	// Add function arguments
	for _, arg := range args {
		cmdArgs = append(cmdArgs, "--args", arg)
	}

	// Add coins if specified
	if sendCoins != "" {
		cmdArgs = append(cmdArgs, "--send", sendCoins)
	}

	// Add key name
	cmdArgs = append(cmdArgs, e.KeyName)

	// Always print the command for transactions (user needs to see what they're signing)
	fmt.Println("Executing:")
	printCommand("gnokey", cmdArgs)
	fmt.Println()

	// Execute the command with inherited stdin for interactive password input
	cmd := exec.Command("gnokey", cmdArgs...)
	cmd.Stdin = os.Stdin

	// Handle stdout and stderr based on verbose mode
	var stdoutBuf, stderrBuf bytes.Buffer
	if e.Verbose {
		// In verbose mode, show full output
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
	} else {
		// In non-verbose mode, capture both stdout and stderr
		cmd.Stdout = &stdoutBuf
		cmd.Stderr = &stderrBuf
		// Print password prompt since stderr is not shown
		fmt.Print("Password: ")
	}

	if err := cmd.Run(); err != nil {
		// Print newline after password input in non-verbose mode
		if !e.Verbose {
			fmt.Println()
		}
		// If error occurred in non-verbose mode, parse the captured stderr
		if !e.Verbose && stderrBuf.Len() > 0 {
			// Create error from captured stderr and parse it for friendly message
			return utils.ParseContractError(fmt.Errorf("%s", stderrBuf.String()))
		}
		// In verbose mode or if no stderr captured, return the error as-is
		return err
	}

	// Print newline after password input in non-verbose mode on success
	if !e.Verbose {
		fmt.Println()
	}

	return nil
}

// QueryFunction executes a query (read-only call)
func (e *TxExecutor) QueryFunction(funcName string, args []string) (string, error) {
	// Build the query path with function call syntax
	queryPath := fmt.Sprintf("%s.%s(", e.RealmPath, funcName)
	if len(args) > 0 {
		formattedArgs := formatArgs(args)
		queryPath += strings.Join(formattedArgs, ",")
	}
	queryPath += ")"

	// Build command arguments
	cmdArgs := []string{
		"query", "vm/qeval",
		"--remote", e.Remote,
		"--data", queryPath,
	}

	// Print the command being executed only in verbose mode
	if e.Verbose {
		fmt.Println("Executing:")
		printCommand("gnokey", cmdArgs)
		fmt.Println()
	}

	// Execute the command
	cmd := exec.Command("gnokey", cmdArgs...)
	output, err := cmd.CombinedOutput()

	// Print output only in verbose mode
	if e.Verbose {
		fmt.Println(string(output))
	}

	if err != nil {
		return "", utils.ParseContractError(fmt.Errorf("query failed: %w", err))
	}

	return string(output), nil
}

// formatArgs formats arguments for Gno function calls
func formatArgs(args []string) []string {
	formatted := make([]string, len(args))
	for i, arg := range args {
		formatted[i] = fmt.Sprintf("\"%s\"", arg)
	}
	return formatted
}

// printCommand prints a command with proper quoting for display
func printCommand(name string, args []string) {
	fmt.Print(name)
	for _, arg := range args {
		// Quote arguments that contain spaces or special characters
		if strings.ContainsAny(arg, " \t\n\"'") {
			fmt.Printf(" \"%s\"", strings.ReplaceAll(arg, "\"", "\\\""))
		} else {
			fmt.Printf(" %s", arg)
		}
	}
	fmt.Println()
}

// QueryInt64 queries a function that returns an int64 value
func (e *TxExecutor) QueryInt64(funcName string) (int64, error) {
	result, err := e.QueryFunction(funcName, []string{})
	if err != nil {
		return 0, err
	}

	// Parse the result to extract the int64 value
	// The output format is like: "height: 0\ndata: (2000000 int64)\n"
	var value int64
	lines := strings.Split(result, "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "data:") {
			// Extract the value from format: "data: (value type)"
			line = strings.TrimPrefix(line, "data:")
			line = strings.TrimSpace(line)
			// Remove parentheses and split
			line = strings.Trim(line, "()")
			parts := strings.Fields(line)
			if len(parts) >= 1 {
				_, err = fmt.Sscanf(parts[0], "%d", &value)
				if err == nil {
					return value, nil
				}
			}
		}
	}
	return 0, utils.ParseContractError(fmt.Errorf("failed to parse int64 from query result: %s", result))
}

// VoteData represents stored vote information
type VoteData struct {
	RequestID string `json:"request_id"`
	Value     string `json:"value"`
	Salt      string `json:"salt"`
	Hash      string `json:"hash"`
	Timestamp string `json:"timestamp"`
}

// SaveVoteLocally saves vote data to local storage
func SaveVoteLocally(requestID, value, salt, hash string) error {
	// Get home directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get home directory: %w", err)
	}

	// Create votes directory
	votesDir := fmt.Sprintf("%s/.goo/votes", homeDir)
	if err := os.MkdirAll(votesDir, 0755); err != nil {
		return fmt.Errorf("failed to create votes directory: %w", err)
	}

	// Create vote data
	voteData := VoteData{
		RequestID: requestID,
		Value:     value,
		Salt:      salt,
		Hash:      hash,
		Timestamp: time.Now().Format(time.RFC3339),
	}

	// Marshal to JSON
	data, err := json.MarshalIndent(voteData, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal vote data: %w", err)
	}

	// Write to file
	filePath := fmt.Sprintf("%s/%s.json", votesDir, requestID)
	if err := os.WriteFile(filePath, data, 0644); err != nil {
		return fmt.Errorf("failed to write vote file: %w", err)
	}

	utils.PrintInfo(fmt.Sprintf("Vote data saved to: %s", filePath))
	return nil
}

// LoadVoteLocally loads vote data from local storage
func LoadVoteLocally(requestID string) (value, salt string, err error) {
	// Get home directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", "", fmt.Errorf("failed to get home directory: %w", err)
	}

	// Read vote file
	filePath := fmt.Sprintf("%s/.goo/votes/%s.json", homeDir, requestID)
	data, err := os.ReadFile(filePath)
	if err != nil {
		return "", "", fmt.Errorf("failed to read vote file: %w (did you commit a vote for this request?)", err)
	}

	// Unmarshal JSON
	var voteData VoteData
	if err := json.Unmarshal(data, &voteData); err != nil {
		return "", "", fmt.Errorf("failed to parse vote data: %w", err)
	}

	if voteData.Value == "" || voteData.Salt == "" {
		return "", "", fmt.Errorf("vote data is incomplete")
	}

	return voteData.Value, voteData.Salt, nil
}
