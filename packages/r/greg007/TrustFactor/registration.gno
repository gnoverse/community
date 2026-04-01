// Package trustfactor provides user registration functionality.
package trustfactor

import (
	"time"

	"chain/runtime"
)

// Register allows a user to join the TrustFactor system with an initial score of 5.0
func Register(cur realm) {
	caller := runtime.OriginCaller()

	if trustScores.Has(string(caller)) {
		panic("user already registered")
	}

	newTrust := &TrustScore{
		Score:          5.0,
		LastUpdate:     time.Now().Unix(),
		Evaluator:      caller,
		TotalVotes:     0,
		PositiveVotes:  0,
		NegativeVotes:  0,
		VoterWeightSum: 0.0,
		Confidence:     0.0,
	}

	trustScores.Set(string(caller), newTrust)
	addToScoreIndex(caller, *newTrust)
	totalUsers++
}
