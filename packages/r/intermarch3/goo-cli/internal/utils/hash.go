package utils

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"time"
)

// GenerateVoteHash generates SHA256 hash from value and salt
func GenerateVoteHash(value, salt string) string {
	data := value + salt
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])
}

// GenerateRandomSalt generates a random salt of specified length
func GenerateRandomSalt(length int) string {
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		// Fallback to timestamp-based salt if crypto/rand fails
		return fmt.Sprintf("%d", time.Now().UnixNano())
	}
	return hex.EncodeToString(bytes)
}

// VerifyVoteHash verifies that a hash matches the value and salt
func VerifyVoteHash(hash, value, salt string) bool {
	expectedHash := GenerateVoteHash(value, salt)
	return hash == expectedHash
}
