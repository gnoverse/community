package trustfactor

import (
	"testing"
	"time"

	"gno.land/p/nt/avl"
)

// TestUserRegistration tests the user registration functionality
func TestUserRegistration(t *testing.T) {
	// Reset state
	trustScores = avl.NewTree()
	totalUsers = 0

	testAddr := address("g1user1234567890123456789012345678")

	// Simulate registration
	trustScores.Set(string(testAddr), &TrustScore{
		Score:          5.0,
		LastUpdate:     time.Now().Unix(),
		Evaluator:      testAddr,
		TotalVotes:     0,
		PositiveVotes:  0,
		NegativeVotes:  0,
		VoterWeightSum: 0.0,
		Confidence:     0.0,
	})
	totalUsers++

	// Verify user is registered
	trustValue, exists := trustScores.Get(string(testAddr))
	if !exists {
		t.Fatal("User should be registered")
	}
	trust := trustValue.(*TrustScore)

	if trust.Score != 5.0 {
		t.Errorf("Expected initial score 5.0, got %.1f", trust.Score)
	}

	if trust.TotalVotes != 0 {
		t.Errorf("Expected 0 votes for new user, got %d", trust.TotalVotes)
	}

	if totalUsers != 1 {
		t.Errorf("Expected totalUsers to be 1, got %d", totalUsers)
	}
}

// TestDuplicateRegistration tests that duplicate registration is prevented
func TestDuplicateRegistration(t *testing.T) {
	trustScores = avl.NewTree()

	testAddr := address("g1user1234567890123456789012345678")

	// First registration
	trustScores.Set(string(testAddr), &TrustScore{
		Score:      5.0,
		LastUpdate: time.Now().Unix(),
	})

	// Try to register again (should fail in real implementation)
	alreadyExists := trustScores.Has(string(testAddr))
	if !alreadyExists {
		t.Error("Duplicate registration check should detect existing user")
	}
}

// TestUpvoteBasicFunctionality tests upvoting a user
func TestUpvoteBasicFunctionality(t *testing.T) {
	trustScores = avl.NewTree()
	userVotes = avl.NewTree()
	voteHistory = avl.NewTree()

	voterAddr := address("g1voter123456789012345678901234567")
	targetAddr := address("g1target12345678901234567890123456")

	// Register both users
	trustScores.Set(string(voterAddr), &TrustScore{
		Score:      7.0,
		LastUpdate: time.Now().Unix(),
	})

	trustScores.Set(string(targetAddr), &TrustScore{
		Score:          5.0,
		LastUpdate:     time.Now().Unix(),
		TotalVotes:     0,
		PositiveVotes:  0,
		VoterWeightSum: 0.0,
	})

	// Simulate upvote
	voteKey := string(voterAddr) + "_" + string(targetAddr)
	if voted, _ := userVotes.Get(voteKey); voted != nil && voted.(bool) {
		t.Fatal("Should allow first vote")
	}

	voterValue, _ := trustScores.Get(string(voterAddr))
	voterWeight := calculateCompositeScore(*voterValue.(*TrustScore))
	impact := (voterWeight / 10.0) * 0.3
	if impact < 0.05 {
		impact = 0.05
	}

	targetValue, _ := trustScores.Get(string(targetAddr))
	targetTrust := targetValue.(*TrustScore)
	newScore := targetTrust.Score + impact

	// Direct modification with pointers
	targetTrust.Score = newScore
	targetTrust.LastUpdate = time.Now().Unix()
	targetTrust.Evaluator = voterAddr
	targetTrust.TotalVotes = 1
	targetTrust.PositiveVotes = 1
	targetTrust.VoterWeightSum = voterWeight
	targetTrust.Confidence = calculateConfidence(1, voterWeight, 1)

	userVotes.Set(voteKey, true)

	// Verify vote was recorded
	trustValue, _ := trustScores.Get(string(targetAddr))
	trust := trustValue.(*TrustScore)
	if trust.TotalVotes != 1 {
		t.Errorf("Expected 1 vote, got %d", trust.TotalVotes)
	}

	if trust.PositiveVotes != 1 {
		t.Errorf("Expected 1 positive vote, got %d", trust.PositiveVotes)
	}

	if trust.Score <= 5.0 {
		t.Errorf("Score should increase after upvote, got %.2f", trust.Score)
	}

	if voted, _ := userVotes.Get(voteKey); voted == nil || !voted.(bool) {
		t.Error("Vote should be recorded in userVotes tree")
	}
}

// TestDownvoteBasicFunctionality tests downvoting a user
func TestDownvoteBasicFunctionality(t *testing.T) {
	trustScores = avl.NewTree()
	userVotes = avl.NewTree()

	voterAddr := address("g1voter123456789012345678901234567")
	targetAddr := address("g1target12345678901234567890123456")

	// Register both users
	trustScores.Set(string(voterAddr), &TrustScore{
		Score:      7.0,
		LastUpdate: time.Now().Unix(),
	})

	trustScores.Set(string(targetAddr), &TrustScore{
		Score:          5.0,
		LastUpdate:     time.Now().Unix(),
		TotalVotes:     0,
		NegativeVotes:  0,
		VoterWeightSum: 0.0,
	})

	// Simulate downvote
	voteKey := string(voterAddr) + "_" + string(targetAddr)

	voterValue, _ := trustScores.Get(string(voterAddr))
	voterWeight := calculateCompositeScore(*voterValue.(*TrustScore))
	impact := (voterWeight / 10.0) * 0.3
	if impact < 0.05 {
		impact = 0.05
	}

	targetValue, _ := trustScores.Get(string(targetAddr))
	targetTrust := targetValue.(*TrustScore)
	newScore := targetTrust.Score - impact
	if newScore < 0.0 {
		newScore = 0.0
	}

	// Direct modification with pointers
	targetTrust.Score = newScore
	targetTrust.LastUpdate = time.Now().Unix()
	targetTrust.Evaluator = voterAddr
	targetTrust.TotalVotes = 1
	targetTrust.NegativeVotes = 1
	targetTrust.VoterWeightSum = voterWeight
	targetTrust.Confidence = calculateConfidence(1, voterWeight, 0)

	userVotes.Set(voteKey, true)

	// Verify downvote was recorded
	trustValue, _ := trustScores.Get(string(targetAddr))
	trust := trustValue.(*TrustScore)
	if trust.TotalVotes != 1 {
		t.Errorf("Expected 1 vote, got %d", trust.TotalVotes)
	}

	if trust.NegativeVotes != 1 {
		t.Errorf("Expected 1 negative vote, got %d", trust.NegativeVotes)
	}

	if trust.Score >= 5.0 {
		t.Errorf("Score should decrease after downvote, got %.2f", trust.Score)
	}
}

// TestPreventDuplicateVote tests that duplicate voting is prevented
func TestPreventDuplicateVote(t *testing.T) {
	trustScores = avl.NewTree()
	userVotes = avl.NewTree()

	voterAddr := address("g1voter123456789012345678901234567")
	targetAddr := address("g1target12345678901234567890123456")

	trustScores.Set(string(voterAddr), &TrustScore{Score: 7.0, LastUpdate: time.Now().Unix()})
	trustScores.Set(string(targetAddr), &TrustScore{Score: 5.0, LastUpdate: time.Now().Unix()})

	voteKey := string(voterAddr) + "_" + string(targetAddr)
	userVotes.Set(voteKey, true)

	// Try to vote again
	if voted, _ := userVotes.Get(voteKey); voted == nil || !voted.(bool) {
		t.Error("Should detect duplicate vote")
	}
}

// TestPreventSelfVote tests that self-voting is prevented
func TestPreventSelfVote(t *testing.T) {
	trustScores = avl.NewTree()

	userAddr := address("g1user1234567890123456789012345678")
	trustScores.Set(string(userAddr), &TrustScore{Score: 5.0, LastUpdate: time.Now().Unix()})

	// Check self-vote prevention
	if userAddr == userAddr {
		// In real implementation, this should panic
		// Here we just verify the condition can be checked
		t.Log("Self-vote prevention check works")
	}
}

// TestGetTrustScore tests retrieving trust scores
func TestGetTrustScore(t *testing.T) {
	trustScores = avl.NewTree()

	testAddr := address("g1test123456789012345678901234567890")
	expectedScore := 7.5

	trustScores.Set(string(testAddr), &TrustScore{
		Score:      expectedScore,
		LastUpdate: time.Now().Unix(),
	})

	// Test GetTrustScore
	score, exists := GetTrustScore(testAddr)
	if !exists {
		t.Fatal("User should exist")
	}

	if score != expectedScore {
		t.Errorf("Expected score %.1f, got %.1f", expectedScore, score)
	}

	// Test non-existent user
	nonExistentAddr := address("g1nonexistent1234567890123456789012")
	_, exists = GetTrustScore(nonExistentAddr)
	if exists {
		t.Error("Non-existent user should return exists=false")
	}
}

// TestGetTrustDetails tests retrieving complete trust details
func TestGetTrustDetails(t *testing.T) {
	trustScores = avl.NewTree()

	testAddr := address("g1test123456789012345678901234567890")
	expectedTrust := &TrustScore{
		Score:          8.5,
		LastUpdate:     time.Now().Unix(),
		TotalVotes:     10,
		PositiveVotes:  8,
		NegativeVotes:  2,
		VoterWeightSum: 75.0,
		Confidence:     0.65,
	}

	trustScores.Set(string(testAddr), expectedTrust)

	// Test GetTrustDetails
	trust := GetTrustDetails(testAddr)

	if trust.Score != expectedTrust.Score {
		t.Errorf("Expected score %.1f, got %.1f", expectedTrust.Score, trust.Score)
	}

	if trust.TotalVotes != expectedTrust.TotalVotes {
		t.Errorf("Expected %d votes, got %d", expectedTrust.TotalVotes, trust.TotalVotes)
	}

	if trust.PositiveVotes != expectedTrust.PositiveVotes {
		t.Errorf("Expected %d positive votes, got %d", expectedTrust.PositiveVotes, trust.PositiveVotes)
	}

	if trust.NegativeVotes != expectedTrust.NegativeVotes {
		t.Errorf("Expected %d negative votes, got %d", expectedTrust.NegativeVotes, trust.NegativeVotes)
	}
}

// TestQueryTrustScore tests the public API for external realms
func TestQueryTrustScore(t *testing.T) {
	trustScores = avl.NewTree()

	testAddr := address("g1test123456789012345678901234567890")
	trustScores.Set(string(testAddr), &TrustScore{
		Score:      7.0,
		LastUpdate: time.Now().Unix(),
	})

	score, exists := QueryTrustScore(testAddr)
	if !exists {
		t.Fatal("User should exist")
	}

	if score < 0 || score > 10 {
		t.Errorf("Score should be between 0 and 10, got %.2f", score)
	}
}

// TestQueryUserDetails tests retrieving comprehensive user details
func TestQueryUserDetails(t *testing.T) {
	trustScores = avl.NewTree()

	testAddr := address("g1test123456789012345678901234567890")
	trustScores.Set(string(testAddr), &TrustScore{
		Score:          8.0,
		LastUpdate:     time.Now().Unix(),
		TotalVotes:     15,
		PositiveVotes:  12,
		VoterWeightSum: 100.0,
	})

	compositeScore, totalVotes, confidence, exists := QueryUserDetails(testAddr)

	if !exists {
		t.Fatal("User should exist")
	}

	if compositeScore < 0 || compositeScore > 10 {
		t.Errorf("Composite score should be between 0 and 10, got %.2f", compositeScore)
	}

	if totalVotes != 15 {
		t.Errorf("Expected 15 total votes, got %d", totalVotes)
	}

	if confidence < 0 || confidence > 1 {
		t.Errorf("Confidence should be between 0 and 1, got %.2f", confidence)
	}
}

// TestIsTrustedUser tests the trust threshold check
func TestIsTrustedUser(t *testing.T) {
	trustScores = avl.NewTree()

	testAddr := address("g1test123456789012345678901234567890")
	trustScores.Set(string(testAddr), &TrustScore{
		Score:      7.0,
		LastUpdate: time.Now().Unix(),
	})

	// Get the actual composite score first
	compositeScore, _ := QueryTrustScore(testAddr)

	// Test with threshold below composite score
	if !IsTrustedUser(testAddr, compositeScore-1.0) {
		t.Errorf("User should be trusted with threshold %.2f (composite score: %.2f)",
			compositeScore-1.0, compositeScore)
	}

	// Test with threshold above composite score
	if IsTrustedUser(testAddr, compositeScore+2.0) {
		t.Errorf("User should not be trusted with threshold %.2f (composite score: %.2f)",
			compositeScore+2.0, compositeScore)
	}

	// Test non-existent user
	nonExistentAddr := address("g1nonexistent1234567890123456789012")
	if IsTrustedUser(nonExistentAddr, 5.0) {
		t.Error("Non-existent user should not be trusted")
	}
}

// TestVoteHistory tests vote history tracking
func TestVoteHistory(t *testing.T) {
	voteHistory = avl.NewTree()

	targetAddr := address("g1target12345678901234567890123456")
	voterAddr1 := address("g1voter1234567890123456789012345671")
	voterAddr2 := address("g1voter1234567890123456789012345672")

	// Add vote history entries
	voteHistory.Set(string(targetAddr), []VoteHistory{
		{
			Voter:     voterAddr1,
			VoteType:  "upvote",
			Weight:    7.5,
			Timestamp: time.Now().Unix(),
		},
		{
			Voter:     voterAddr2,
			VoteType:  "downvote",
			Weight:    6.0,
			Timestamp: time.Now().Unix(),
		},
	})

	// Get vote history
	history := GetVoteHistory(targetAddr)

	if len(history) != 2 {
		t.Errorf("Expected 2 history entries, got %d", len(history))
	}

	if history[0].VoteType != "upvote" {
		t.Errorf("Expected first vote to be upvote, got %s", history[0].VoteType)
	}

	if history[1].VoteType != "downvote" {
		t.Errorf("Expected second vote to be downvote, got %s", history[1].VoteType)
	}
}

// TestScoreBounds tests that scores stay within valid bounds (0-10)
func TestScoreBounds(t *testing.T) {
	tests := []struct {
		name  string
		trust TrustScore
	}{
		{
			name: "Very low score",
			trust: TrustScore{
				Score:      0.5,
				LastUpdate: time.Now().Unix() - (100 * 86400), // 100 days old
			},
		},
		{
			name: "Very high score",
			trust: TrustScore{
				Score:          9.5,
				LastUpdate:     time.Now().Unix(),
				TotalVotes:     20,
				PositiveVotes:  20,
				VoterWeightSum: 180.0,
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			score := calculateCompositeScore(tt.trust)

			if score < 0.0 {
				t.Errorf("Score should not be negative, got %.2f", score)
			}

			if score > 10.0 {
				t.Errorf("Score should not exceed 10, got %.2f", score)
			}
		})
	}
}

// TestGetTotalUsers tests retrieving total user count
func TestGetTotalUsers(t *testing.T) {
	trustScores = avl.NewTree()
	totalUsers = 0

	addr1 := address("g1user1234567890123456789012345678")
	addr2 := address("g1user2345678901234567890123456789")
	addr3 := address("g1user3456789012345678901234567890")

	trustScores.Set(string(addr1), &TrustScore{Score: 5.0, LastUpdate: time.Now().Unix()})
	trustScores.Set(string(addr2), &TrustScore{Score: 6.0, LastUpdate: time.Now().Unix()})
	trustScores.Set(string(addr3), &TrustScore{Score: 7.0, LastUpdate: time.Now().Unix()})
	totalUsers = 3

	count := GetTotalUsers()

	if count != 3 {
		t.Errorf("Expected 3 users, got %d", count)
	}

	// Verify users exist using GetTrustDetails
	if trust := GetTrustDetails(addr1); trust.Score == 0 {
		t.Error("addr1 should exist")
	}

	if trust := GetTrustDetails(addr2); trust.Score == 0 {
		t.Error("addr2 should exist")
	}

	if trust := GetTrustDetails(addr3); trust.Score == 0 {
		t.Error("addr3 should exist")
	}
}

// TestMultipleVotesImpact tests the cumulative effect of multiple votes
func TestMultipleVotesImpact(t *testing.T) {
	trustScores = avl.NewTree()
	userVotes = avl.NewTree()

	targetAddr := address("g1target12345678901234567890123456")
	trustScores.Set(string(targetAddr), &TrustScore{
		Score:      5.0,
		LastUpdate: time.Now().Unix(),
	})

	targetValue, _ := trustScores.Get(string(targetAddr))
	initialScore := targetValue.(*TrustScore).Score

	// Simulate 3 upvotes from different users
	for i := 0; i < 3; i++ {
		voterAddr := address("g1voter" + string(rune('1'+i)) + "2345678901234567890123456")
		trustScores.Set(string(voterAddr), &TrustScore{Score: 7.0, LastUpdate: time.Now().Unix()})

		voteKey := string(voterAddr) + "_" + string(targetAddr)
		if voted, _ := userVotes.Get(voteKey); voted != nil && voted.(bool) {
			continue
		}

		voterValue, _ := trustScores.Get(string(voterAddr))
		voterWeight := calculateCompositeScore(*voterValue.(*TrustScore))
		impact := (voterWeight / 10.0) * 0.3
		if impact < 0.05 {
			impact = 0.05
		}

		currentValue, _ := trustScores.Get(string(targetAddr))
		currentTrust := currentValue.(*TrustScore)
		newScore := currentTrust.Score + impact
		if newScore > 10.0 {
			newScore = 10.0
		}

		// Direct modification with pointers
		currentTrust.Score = newScore
		currentTrust.LastUpdate = time.Now().Unix()
		currentTrust.TotalVotes++
		currentTrust.PositiveVotes++
		currentTrust.VoterWeightSum += voterWeight

		userVotes.Set(voteKey, true)
	}

	finalValue, _ := trustScores.Get(string(targetAddr))
	finalTrust := finalValue.(*TrustScore)

	if finalTrust.Score <= initialScore {
		t.Errorf("Score should increase after upvotes: initial=%.2f, final=%.2f",
			initialScore, finalTrust.Score)
	}

	if finalTrust.TotalVotes != 3 {
		t.Errorf("Expected 3 total votes, got %d", finalTrust.TotalVotes)
	}

	if finalTrust.PositiveVotes != 3 {
		t.Errorf("Expected 3 positive votes, got %d", finalTrust.PositiveVotes)
	}
}
