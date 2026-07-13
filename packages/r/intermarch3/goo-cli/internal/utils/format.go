package utils

import (
	"fmt"
	"strings"
	"time"
)

// FormatUgnot formats ugnot amount for display
func FormatUgnot(amount int64) string {
	return fmt.Sprintf("%d ugnot", amount)
}

// FormatBool formats boolean for Gno function calls
func FormatBool(b bool) string {
	if b {
		return "true"
	}
	return "false"
}

// FormatDuration formats a duration in a human-readable way
func FormatDuration(d time.Duration) string {
	if d < time.Minute {
		return fmt.Sprintf("%ds", int(d.Seconds()))
	}
	if d < time.Hour {
		return fmt.Sprintf("%dm%ds", int(d.Minutes()), int(d.Seconds())%60)
	}
	if d < 24*time.Hour {
		return fmt.Sprintf("%dh%dm", int(d.Hours()), int(d.Minutes())%60)
	}
	days := int(d.Hours() / 24)
	hours := int(d.Hours()) % 24
	return fmt.Sprintf("%dd%dh", days, hours)
}

// FormatTimestamp formats a Unix timestamp
func FormatTimestamp(ts int64) string {
	t := time.Unix(ts, 0)
	return t.Format("2006-01-02 15:04:05 MST")
}

// FormatTimeUntil formats time remaining until a timestamp
func FormatTimeUntil(ts int64) string {
	t := time.Unix(ts, 0)
	duration := time.Until(t)
	if duration < 0 {
		return "expired"
	}
	return FormatDuration(duration)
}

// TruncateString truncates a string to maxLen with ellipsis
func TruncateString(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	if maxLen <= 3 {
		return s[:maxLen]
	}
	return s[:maxLen-3] + "..."
}

// FormatAddress formats a Gno address for display
func FormatAddress(addr string) string {
	if len(addr) <= 16 {
		return addr
	}
	return addr[:8] + "..." + addr[len(addr)-6:]
}

// PrintKeyValue prints a key-value pair with proper alignment
func PrintKeyValue(key string, value interface{}) {
	fmt.Printf("  %-20s %v\n", key+":", value)
}

// PrintSection prints a section header
func PrintSection(title string) {
	fmt.Println()
	fmt.Println(strings.Repeat("=", 60))
	fmt.Printf("  %s\n", strings.ToUpper(title))
	fmt.Println(strings.Repeat("=", 60))
}

// PrintSuccess prints a success message
func PrintSuccess(message string) {
	fmt.Printf("✓ %s\n", message)
}

// PrintError prints an error message
func PrintError(message string) {
	fmt.Printf("✗ %s\n", message)
}

// PrintWarning prints a warning message
func PrintWarning(message string) {
	fmt.Printf("⚠ %s\n", message)
}

// PrintInfo prints an info message
func PrintInfo(message string) {
	fmt.Printf("ℹ %s\n", message)
}

// ParseStringArrayFromQuery parses a string array from gnokey query output
// Input format: "height: 0\ndata: (slice[(\"0000001\" string),(\"0000002\" string)] []string)\n"
// Returns: ["0000001", "0000002"]
func ParseStringArrayFromQuery(output string) ([]string, error) {
	var result []string

	// Find the data line
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "data:") {
			// Extract content between "slice[" and "]"
			start := strings.Index(line, "slice[")
			if start == -1 {
				// Empty array case: (slice[] []string)
				return result, nil
			}
			start += 6 // Move past "slice["

			end := strings.Index(line[start:], "]")
			if end == -1 {
				return nil, fmt.Errorf("failed to parse array: missing closing bracket")
			}

			content := line[start : start+end]
			if content == "" {
				return result, nil
			}

			// Split by "),(" to get individual items
			items := strings.Split(content, "),(")
			for _, item := range items {
				// Clean up the item: remove quotes and type annotation
				// Format: ("0000001" string) or "0000001" string
				item = strings.TrimPrefix(item, "(")
				item = strings.TrimSuffix(item, ")")
				item = strings.TrimSpace(item)

				// Extract the string value between quotes
				if idx := strings.Index(item, "\""); idx != -1 {
					endIdx := strings.Index(item[idx+1:], "\"")
					if endIdx != -1 {
						value := item[idx+1 : idx+1+endIdx]
						result = append(result, value)
					}
				}
			}

			return result, nil
		}
	}

	return nil, fmt.Errorf("no data field found in query output")
}

// ParseStringFromQuery parses a string value from gnokey query output
// Input format: "height: 0\ndata: (\"Requested\" string)\n"
// Returns: "Requested"
func ParseStringFromQuery(output string) (string, error) {
	// Find the data line
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "data:") {
			// Extract the string value between quotes
			line = strings.TrimPrefix(line, "data:")
			line = strings.TrimSpace(line)

			// Remove parentheses and type annotation
			line = strings.Trim(line, "()")

			// Extract string between quotes
			if idx := strings.Index(line, "\""); idx != -1 {
				endIdx := strings.Index(line[idx+1:], "\"")
				if endIdx != -1 {
					return line[idx+1 : idx+1+endIdx], nil
				}
			}

			return "", fmt.Errorf("failed to parse string from: %s", line)
		}
	}

	return "", fmt.Errorf("no data field found in query output")
}

// DataRequest represents a parsed request from the contract
type DataRequest struct {
	ID             string
	Creator        string
	Timestamp      string
	AncillaryData  string
	YesNoQuestion  bool
	ProposedValue  int64
	Proposer       string
	ProposerBond   int64
	Disputer       string
	DisputerBond   int64
	ResolutionTime string
	WinningValue   int64
	State          string
	Deadline       string
}

// ParseDataRequestFromQuery parses a DataRequest struct from gnokey query output
// Input format: struct{("0000001" string),(address),(time.Time),("question" string),(true bool)...}
func ParseDataRequestFromQuery(output string) (*DataRequest, error) {
	// Find the data line
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "data:") {
			// Extract struct content
			start := strings.Index(line, "struct{")
			if start == -1 {
				return nil, fmt.Errorf("no struct found in output")
			}
			start += 7 // Move past "struct{"

			end := strings.LastIndex(line, "}")
			if end == -1 {
				return nil, fmt.Errorf("struct not closed")
			}

			content := line[start:end]

			// Split by "),(" to get individual fields
			fields := splitStructFields(content)

			if len(fields) < 14 {
				return nil, fmt.Errorf("expected 14 fields, got %d", len(fields))
			}

			req := &DataRequest{
				ID:             extractStringValue(fields[0]),
				Creator:        extractAddressValue(fields[1]),
				Timestamp:      extractTimeValue(fields[2]),
				AncillaryData:  extractStringValue(fields[3]),
				YesNoQuestion:  extractBoolValue(fields[4]),
				ProposedValue:  extractInt64Value(fields[5]),
				Proposer:       extractAddressValue(fields[6]),
				ProposerBond:   extractInt64Value(fields[7]),
				Disputer:       extractAddressValue(fields[8]),
				DisputerBond:   extractInt64Value(fields[9]),
				ResolutionTime: extractTimeValue(fields[10]),
				WinningValue:   extractInt64Value(fields[11]),
				State:          extractStringValue(fields[12]),
				Deadline:       extractTimeValue(fields[13]),
			}

			return req, nil
		}
	}

	return nil, fmt.Errorf("no data field found in query output")
}

// splitStructFields splits struct fields handling nested parentheses
func splitStructFields(content string) []string {
	var fields []string
	var current strings.Builder
	depth := 0

	for i := 0; i < len(content); i++ {
		c := content[i]

		if c == '(' {
			depth++
			current.WriteByte(c)
		} else if c == ')' {
			depth--
			current.WriteByte(c)

			// If we're back to depth 0 and next char is comma, this is end of field
			if depth == 0 && i+1 < len(content) && content[i+1] == ',' {
				fields = append(fields, current.String())
				current.Reset()
				i++ // Skip the comma
			}
		} else {
			current.WriteByte(c)
		}
	}

	// Add last field
	if current.Len() > 0 {
		fields = append(fields, current.String())
	}

	return fields
}

// extractStringValue extracts string from format: ("value" string)
func extractStringValue(field string) string {
	field = strings.TrimSpace(field)
	field = strings.TrimPrefix(field, "(")
	field = strings.TrimSuffix(field, ")")

	if idx := strings.Index(field, "\""); idx != -1 {
		endIdx := strings.Index(field[idx+1:], "\"")
		if endIdx != -1 {
			return field[idx+1 : idx+1+endIdx]
		}
	}
	return ""
}

// extractAddressValue extracts address from format: (address) or ("g1..." .uverse.address)
func extractAddressValue(field string) string {
	field = strings.TrimSpace(field)
	field = strings.TrimPrefix(field, "(")
	field = strings.TrimSuffix(field, ")")

	// Check if it's a quoted address
	if idx := strings.Index(field, "\""); idx != -1 {
		endIdx := strings.Index(field[idx+1:], "\"")
		if endIdx != -1 {
			return field[idx+1 : idx+1+endIdx]
		}
	}

	// Check if it's empty address
	if strings.Contains(field, ".uverse.address") && !strings.Contains(field, "g1") {
		return ""
	}

	// Extract g1 address if present
	if idx := strings.Index(field, "g1"); idx != -1 {
		// Find the end (space or quote)
		addr := field[idx:]
		if spaceIdx := strings.Index(addr, " "); spaceIdx != -1 {
			addr = addr[:spaceIdx]
		}
		if quoteIdx := strings.Index(addr, "\""); quoteIdx != -1 {
			addr = addr[:quoteIdx]
		}
		return strings.TrimSpace(addr)
	}

	return ""
}

// extractBoolValue extracts bool from format: (true bool)
func extractBoolValue(field string) bool {
	return strings.Contains(field, "true")
}

// extractInt64Value extracts int64 from format: (123 int64)
func extractInt64Value(field string) int64 {
	field = strings.TrimSpace(field)
	field = strings.TrimPrefix(field, "(")

	// Extract number before space or closing paren
	var numStr string
	for _, c := range field {
		if c >= '0' && c <= '9' || c == '-' {
			numStr += string(c)
		} else {
			break
		}
	}

	var val int64
	fmt.Sscanf(numStr, "%d", &val)
	return val
}

// extractTimeValue extracts time reference - just return placeholder for refs
func extractTimeValue(field string) string {
	// Time is represented as ref(...) in the output
	// We can't parse the actual time from this format
	if strings.Contains(field, "ref(") {
		return "N/A"
	}
	return ""
}

// Dispute represents a parsed dispute from the contract
type Dispute struct {
	RequestID       string
	Votes           int // Number of votes (we can't parse the full Vote slice)
	NbResolvedVotes int64
	IsResolved      bool
	WinningValue    int64
	EndTime         string
	EndRevealTime   string
}

// ParseDisputeFromQuery parses a Dispute struct from gnokey query output
// Input format: struct{("0000002" string),(slice[...] []Vote),(0 int64),(...),(...),(ref(...))...}
func ParseDisputeFromQuery(output string) (*Dispute, error) {
	// Find the data line
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "data:") {
			// Extract struct content
			start := strings.Index(line, "struct{")
			if start == -1 {
				return nil, fmt.Errorf("no struct found in output")
			}
			start += 7 // Move past "struct{"

			end := strings.LastIndex(line, "}")
			if end == -1 {
				return nil, fmt.Errorf("struct not closed")
			}

			content := line[start:end]

			// Split by "),(" to get individual fields
			fields := splitStructFields(content)

			if len(fields) < 8 {
				return nil, fmt.Errorf("expected 8 fields, got %d", len(fields))
			}

			// Count votes in the slice
			votesCount := countVotesInSlice(fields[1])

			dispute := &Dispute{
				RequestID:       extractStringValue(fields[0]),
				Votes:           votesCount,
				NbResolvedVotes: extractInt64Value(fields[2]),
				// fields[3] is *avl.Tree (Voters) - skip
				IsResolved:    extractBoolValue(fields[4]),
				WinningValue:  extractInt64Value(fields[5]),
				EndTime:       extractTimeValue(fields[6]),
				EndRevealTime: extractTimeValue(fields[7]),
			}

			return dispute, nil
		}
	}

	return nil, fmt.Errorf("no data field found in query output")
}

// countVotesInSlice counts the number of votes in a slice field
// Format: (slice[ref(...),ref(...)] []Vote)
func countVotesInSlice(field string) int {
	// Look for "slice[" and count refs
	if !strings.Contains(field, "slice[") {
		return 0
	}

	// Extract content between slice[ and ]
	start := strings.Index(field, "slice[")
	if start == -1 {
		return 0
	}
	start += 6

	end := strings.Index(field[start:], "]")
	if end == -1 {
		return 0
	}

	content := field[start : start+end]
	if content == "" {
		return 0
	}

	// Count commas + 1 to get number of items
	count := 1
	for _, c := range content {
		if c == ',' {
			count++
		}
	}

	return count
}
