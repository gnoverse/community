package utils

import (
	"fmt"
	"time"
)

// ParseDeadline parses a deadline string in RFC3339 format
func ParseDeadline(deadline string) (time.Time, error) {
	t, err := time.Parse(time.RFC3339, deadline)
	if err != nil {
		return time.Time{}, fmt.Errorf("invalid deadline format (expected RFC3339): %w", err)
	}
	return t, nil
}

// FormatTimeRFC3339 formats a time in RFC3339 format
func FormatTimeRFC3339(t time.Time) string {
	return t.Format(time.RFC3339)
}

// GetCurrentTimestamp returns the current Unix timestamp
func GetCurrentTimestamp() int64 {
	return time.Now().Unix()
}

// IsExpired checks if a timestamp is in the past
func IsExpired(ts int64) bool {
	return time.Now().Unix() > ts
}

// TimeFromUnix converts Unix timestamp to time.Time
func TimeFromUnix(ts int64) time.Time {
	return time.Unix(ts, 0)
}

// DurationFromSeconds converts seconds to time.Duration
func DurationFromSeconds(seconds int64) time.Duration {
	return time.Duration(seconds) * time.Second
}
