// Package trustfactor provides admin functions for owner-only operations.
package trustfactor

import (
	"strings"

	"gno.land/p/nt/ownable"
)

// RemoveUser removes a malicious user from the system (emergency function)
func RemoveUser(cur realm, target address) {
	owner.AssertOwnedByCurrent()

	// Get trust score before removal for scoreIndex cleanup
	targetValue, exists := trustScores.Get(string(target))
	if exists {
		targetTrust := targetValue.(*TrustScore)
		removeFromScoreIndex(target, *targetTrust)
	}

	trustScores.Remove(string(target))
	voteHistory.Remove(string(target))

	// Clean up all votes involving the target user
	keysToRemove := []string{}
	userVotes.Iterate("", "", func(key string, value interface{}) bool {
		if strings.Contains(key, string(target)) {
			keysToRemove = append(keysToRemove, key)
		}
		return false
	})
	for _, key := range keysToRemove {
		userVotes.Remove(key)
	}

	totalUsers--
}

// GetOwnable returns the ownable object for ownership management
func GetOwnable() *ownable.Ownable {
	return owner
}
