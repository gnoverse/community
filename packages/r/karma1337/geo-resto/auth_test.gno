package georesto

import (
	"testing"
	"time" // time.Sleep is not available in Gno
)

func TestRateLimiting(t *testing.T) {
	auth := NewAuthManager()
	user := "g1user123"
	action := "test_action"
	cooldown := int64(5) // 5 seconds

	// First call should succeed
	if !auth.CheckRateLimit(user, action, cooldown) {
		t.Error("First call should not be rate-limited")
	}

	// Immediate second call should fail
	if auth.CheckRateLimit(user, action, cooldown) {
		t.Error("Second call should be rate-limited")
	}

	// NOTE: We cannot test the cooldown expiration in the Gno test environment
	// because `time.Sleep` is not available and we cannot manipulate the block timestamp.
}

// The previous admin/verifier test relied on custom AuthManager maps.
// After refactor, authorization is delegated to authorizable (superuser + auth list).
// Here we only sanity-check rate limit & token features remain unaffected.

func TestAccessToken(t *testing.T) {
	auth := NewAuthManager()
	user := "g1user123"
	currentTime := time.Now().Unix()
	expirationTime := currentTime + 3600 // 1 hour

	// Generate a token
	token := auth.GenerateAccessToken(user, expirationTime)
	if len(token) != 64 {
		t.Fatal("Generated token has incorrect length")
	}

	// Verify the valid token
	if !auth.VerifyAccessToken(token, user, currentTime) {
		t.Error("Valid token should be verified")
	}

	// Verify an invalid token
	if auth.VerifyAccessToken("invalidtoken", user, currentTime) {
		t.Error("Invalid token should not be verified")
	}

	// Verify an expired token
	expiredTime := currentTime + 3601
	if auth.VerifyAccessToken(token, user, expiredTime) {
		t.Error("Expired token should not be verified")
	}
}

func TestLocationProof(t *testing.T) {
	auth := NewAuthManager()
	user := "g1user123"
	locationID := "loc_1"
	timestamp := time.Now().Unix()

	// Generate a valid challenge
	challenge := auth.GenerateLocationChallenge(locationID)

	// The proof is the challenge itself in this implementation
	proof := challenge

	// Verify the valid proof
	if !auth.VerifyLocationProof(user, locationID, proof, timestamp) {
		t.Error("Valid location proof should be verified")
	}

	// Verify an invalid proof
	if auth.VerifyLocationProof(user, locationID, "invalidproof", timestamp) {
		t.Error("Invalid location proof should not be verified")
	}
}
