package trustfactor

// =============================================================================
// BASIC GETTER FUNCTIONS
// =============================================================================

// GetTrustScore returns the raw trust score for a user
func GetTrustScore(addr address) (float64, bool) {
	value, exists := trustScores.Get(string(addr))
	if !exists {
		return 0.0, false
	}
	trust := value.(*TrustScore)
	return trust.Score, true
}

// GetCompositeScore returns the calculated composite score (with time decay and confidence)
func GetCompositeScore(addr address) (float64, bool) {
	value, exists := trustScores.Get(string(addr))
	if !exists {
		return 0.0, false
	}
	trust := value.(*TrustScore)
	return calculateCompositeScore(*trust), true
}

// GetTrustDetails returns the complete TrustScore struct for a user
func GetTrustDetails(addr address) TrustScore {
	value, exists := trustScores.Get(string(addr))
	if !exists {
		return TrustScore{Score: 0, LastUpdate: 0, Evaluator: ""}
	}
	return *value.(*TrustScore)
}

// =============================================================================
// DATA ACCESS FUNCTIONS
// =============================================================================

// GetTotalUsers returns the total number of registered users
func GetTotalUsers() int {
	return totalUsers
}

// GetVoteHistory returns the voting history for a specific user
func GetVoteHistory(addr address) []VoteHistory {
	if historyValue, exists := voteHistory.Get(string(addr)); exists {
		return historyValue.([]VoteHistory)
	}
	return []VoteHistory{}
}
