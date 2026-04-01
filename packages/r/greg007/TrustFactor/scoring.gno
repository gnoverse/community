package trustfactor

import "time"

// =============================================================================
// SCORE CALCULATION ALGORITHMS
// =============================================================================

// getTimeDecayFactor calculates how much a score should decay based on time elapsed
// More recent updates maintain higher scores
func getTimeDecayFactor(timestamp int64) float64 {
	now := time.Now().Unix()
	daysSince := float64(now-timestamp) / 86400.0

	switch {
	case daysSince <= 7.0:
		return 1.0 // No decay for recent activity
	case daysSince <= 30.0:
		return 0.95 // Slight decay after a week
	case daysSince <= 90.0:
		return 0.85 // Moderate decay after a month
	default:
		return 0.7 // Higher decay for old scores
	}
}

// calculateConfidence determines confidence level based on vote quantity and voter quality
func calculateConfidence(totalVotes int, voterWeightSum float64, positiveVotes int) float64 {
	if totalVotes == 0 {
		return 0.0
	}

	voteConfidence := float64(totalVotes) / (float64(totalVotes) + 5.0)
	avgVoterWeight := voterWeightSum / float64(totalVotes)
	weightConfidence := avgVoterWeight / 10.0
	positiveRatio := float64(positiveVotes) / float64(totalVotes)
	positivityFactor := 0.5 + (positiveRatio-0.5)*1.0
	baseConfidence := (voteConfidence * 0.4) + (weightConfidence * 0.3)
	return baseConfidence * positivityFactor
}

// calculateCompositeScore computes the final score using base score, time decay, and confidence
func calculateCompositeScore(trust TrustScore) float64 {
	baseScore := trust.Score
	timeFactor := getTimeDecayFactor(trust.LastUpdate)
	confidence := calculateConfidence(trust.TotalVotes, trust.VoterWeightSum, trust.PositiveVotes)
	timeAdjustedScore := baseScore * timeFactor
	confidenceMultiplier := 1.0 + (confidence-0.5)*0.4
	finalScore := timeAdjustedScore * confidenceMultiplier

	// Clamp to valid range
	if finalScore > 10.0 {
		return 10.0
	} else if finalScore < 0.0 {
		return 0.0
	}

	return finalScore
}
