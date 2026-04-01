// Package trustfactor provides public API for other realms to query trust scores.
package trustfactor

import "time"

// QueryTrustScore returns the calculated composite trust score for external use
func QueryTrustScore(addr address) (float64, bool) {
	value, exists := trustScores.Get(string(addr))
	if !exists {
		return 0.0, false
	}
	trust := value.(*TrustScore)
	return calculateCompositeScore(*trust), true
}

// QueryUserDetails returns comprehensive user information for external realms
func QueryUserDetails(addr address) (float64, int, float64, bool) {
	value, exists := trustScores.Get(string(addr))
	if !exists {
		return 0.0, 0, 0.0, false
	}
	trust := value.(*TrustScore)

	compositeScore := calculateCompositeScore(*trust)
	return compositeScore, trust.TotalVotes, trust.Confidence, true
}

// IsTrustedUser checks if a user meets a minimum trust threshold
func IsTrustedUser(addr address, minScore float64) bool {
	score, exists := QueryTrustScore(addr)
	return exists && score >= minScore
}

// GetUserRank returns the user's position in the trust leaderboard
// Uses direct AVL iteration - no slice materialization
func GetUserRank(addr address) (int, int, bool) {
	total := scoreIndex.Size()
	rank := 0
	found := false

	IterateSortedUsers(func(userAddr address, index int) bool {
		if userAddr == addr {
			rank = index + 1
			found = true
			return true // Stop iteration
		}
		return false // Continue
	})

	return rank, total, found
}

// GetTopTrustedUsers returns the N most trusted users
// Uses direct AVL iteration - no full slice materialization
func GetTopTrustedUsers(limit int) []address {
	return GetTopUsers(limit, nil)
}

// GetScoreFreshness returns how many days since the user's last score update
func GetScoreFreshness(addr address) (int64, bool) {
	value, exists := trustScores.Get(string(addr))
	if !exists {
		return 0, false
	}
	trust := value.(*TrustScore)

	now := time.Now().Unix()
	daysSince := (now - trust.LastUpdate) / 86400
	return daysSince, true
}
