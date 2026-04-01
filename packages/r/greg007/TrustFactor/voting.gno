// Package trustfactor provides voting functions for trust score management.
package trustfactor

import (
	"time"

	"chain/runtime"
)

// Upvote increases a user's trust score based on the voter's own reputation
func Upvote(cur realm, target address) {
	caller := runtime.OriginCaller()

	voterValue, voterExists := trustScores.Get(string(caller))
	if !voterExists {
		panic("voter must be registered")
	}
	voterTrust := voterValue.(*TrustScore)

	targetValue, targetExists := trustScores.Get(string(target))
	if !targetExists {
		panic("target user not registered")
	}
	targetTrust := targetValue.(*TrustScore)

	if caller == target {
		panic("cannot vote for yourself")
	}

	voteKey := string(caller) + "_" + string(target)
	if voted, _ := userVotes.Get(voteKey); voted != nil && voted.(bool) {
		panic("already voted for this user")
	}

	// Calculate weighted impact based on voter reputation
	voterWeight := calculateCompositeScore(*voterTrust)
	impact := (voterWeight / 10.0) * 0.3 // Maximum impact of 0.3 points
	if impact < 0.05 {
		impact = 0.05 // Minimum impact to prevent zero effect
	}

	newScore := targetTrust.Score + impact
	if newScore > 10.0 {
		newScore = 10.0
	}

	// Add to vote history with size limit
	voteEntry := VoteHistory{
		Voter:     caller,
		VoteType:  "upvote",
		Weight:    voterWeight,
		Timestamp: time.Now().Unix(),
	}

	var history []VoteHistory
	if historyValue, exists := voteHistory.Get(string(target)); exists {
		history = historyValue.([]VoteHistory)
	}
	if len(history) >= MAX_HISTORY_SIZE {
		history = history[len(history)-(MAX_HISTORY_SIZE-1):]
	}
	history = append(history, voteEntry)
	voteHistory.Set(string(target), history)

	// Save old state for scoreIndex update
	oldTrust := *targetTrust

	// Direct modification - no need to create a new struct and set it back!
	targetTrust.Score = newScore
	targetTrust.LastUpdate = time.Now().Unix()
	targetTrust.Evaluator = caller
	targetTrust.TotalVotes++
	targetTrust.PositiveVotes++
	targetTrust.VoterWeightSum += voterWeight
	targetTrust.Confidence = calculateConfidence(targetTrust.TotalVotes, targetTrust.VoterWeightSum, targetTrust.PositiveVotes)

	userVotes.Set(voteKey, true)

	// Update scoreIndex with new score
	updateScoreIndex(target, oldTrust, *targetTrust)
}

// Downvote decreases a user's trust score based on the voter's own reputation
func Downvote(cur realm, target address) {
	caller := runtime.OriginCaller()

	voterValue, voterExists := trustScores.Get(string(caller))
	if !voterExists {
		panic("voter must be registered")
	}
	voterTrust := voterValue.(*TrustScore)

	targetValue, targetExists := trustScores.Get(string(target))
	if !targetExists {
		panic("target user not registered")
	}
	targetTrust := targetValue.(*TrustScore)

	if caller == target {
		panic("cannot vote for yourself")
	}

	voteKey := string(caller) + "_" + string(target)
	if voted, _ := userVotes.Get(voteKey); voted != nil && voted.(bool) {
		panic("already voted for this user")
	}

	// Calculate weighted impact based on voter reputation
	voterWeight := calculateCompositeScore(*voterTrust)
	impact := (voterWeight / 10.0) * 0.3 // Maximum impact of 0.3 points
	if impact < 0.05 {
		impact = 0.05 // Minimum impact to prevent zero effect
	}

	newScore := targetTrust.Score - impact
	if newScore < 0.0 {
		newScore = 0.0
	}

	// Add to vote history with size limit
	voteEntry := VoteHistory{
		Voter:     caller,
		VoteType:  "downvote",
		Weight:    voterWeight,
		Timestamp: time.Now().Unix(),
	}

	var history []VoteHistory
	if historyValue, exists := voteHistory.Get(string(target)); exists {
		history = historyValue.([]VoteHistory)
	}
	if len(history) >= MAX_HISTORY_SIZE {
		history = history[len(history)-(MAX_HISTORY_SIZE-1):]
	}
	history = append(history, voteEntry)
	voteHistory.Set(string(target), history)

	// Save old state for scoreIndex update
	oldTrust := *targetTrust

	// Direct modification - no need to create a new struct and set it back!
	targetTrust.Score = newScore
	targetTrust.LastUpdate = time.Now().Unix()
	targetTrust.Evaluator = caller
	targetTrust.TotalVotes++
	targetTrust.NegativeVotes++
	targetTrust.VoterWeightSum += voterWeight
	targetTrust.Confidence = calculateConfidence(targetTrust.TotalVotes, targetTrust.VoterWeightSum, targetTrust.PositiveVotes)

	userVotes.Set(voteKey, true)

	// Update scoreIndex with new score
	updateScoreIndex(target, oldTrust, *targetTrust)
}
