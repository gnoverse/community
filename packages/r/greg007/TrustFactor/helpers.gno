package trustfactor

import (
	"strconv"
	"time"

	"gno.land/r/sys/users"
)

// formatTimeAgo converts a Unix timestamp into a human-readable relative time string.
// The format varies based on the time elapsed: "Today", "N days ago", "N week(s) ago", etc.
func formatTimeAgo(timestamp int64) string {
	now := time.Now().Unix()
	daysSince := (now - timestamp) / 86400

	if daysSince == 0 {
		return "Today"
	}
	if daysSince == 1 {
		return "1 day ago"
	}
	if daysSince < 7 {
		return strconv.FormatInt(daysSince, 10) + " days ago"
	}
	if daysSince < 30 {
		weeks := daysSince / 7
		return strconv.FormatInt(weeks, 10) + " week(s) ago"
	}
	if daysSince < 365 {
		months := daysSince / 30
		return strconv.FormatInt(months, 10) + " month(s) ago"
	}

	years := daysSince / 365
	return strconv.FormatInt(years, 10) + " year(s) ago"
}

// getDisplayName returns the registered username from sys/users, or a shortened
// address if no username is registered for the given address.
func getDisplayName(addr address) string {
	userData := users.ResolveAddress(addr)

	if userData != nil {
		return userData.Name()
	}

	return shortenAddress(string(addr), 12, 4)
}

// shortenAddress truncates a long address string to show only the prefix and suffix,
// separated by "..." for display purposes.
func shortenAddress(addr string, prefixLen, suffixLen int) string {
	if len(addr) <= prefixLen+suffixLen {
		return addr
	}
	return addr[:prefixLen] + "..." + addr[len(addr)-suffixLen:]
}

// getConfidenceIcon returns an emoji icon representing the confidence level:
// 🟢 for high (≥0.8), 🟡 for medium (≥0.5), 🔴 for low (<0.5).
func getConfidenceIcon(confidence float64) string {
	if confidence >= 0.8 {
		return "🟢"
	}
	if confidence >= 0.5 {
		return "🟡"
	}
	return "🔴"
}

// getConfidenceColor returns a hex color code based on confidence level for SVG rendering:
// black for high confidence, dark gray for medium, light gray for low.
func getConfidenceColor(confidence float64) string {
	if confidence >= 0.8 {
		return "#000000"
	}
	if confidence >= 0.5 {
		return "#666666"
	}
	return "#CCCCCC"
}
