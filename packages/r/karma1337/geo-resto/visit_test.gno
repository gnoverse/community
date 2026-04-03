package georesto

import (
	"testing"
)

func TestVisitManager(t *testing.T) {
	// Setup - use global managers
	creator := address("g1creator123")

	// Create a test location using global manager
	location := locationManager.AddLocation(creator, "Test Location", "Test", 48.8566, 2.3522, "test")

	// Test check-in
	user := address("g1user123")
	visit := visitManager.CheckIn(user, location.ID, "test-proof")

	if visit == nil {
		t.Fatal("Failed to check in")
	}

	if visit.UserAddress != user.String() {
		t.Errorf("Expected user address %s, got %s", user.String(), visit.UserAddress)
	}

	if visit.LocationID != location.ID {
		t.Errorf("Expected location ID %s, got %s", location.ID, visit.LocationID)
	}

	// Test retrieving visit
	retrieved := visitManager.GetVisit(visit.ID)
	if retrieved == nil {
		t.Fatal("Failed to retrieve visit")
	}

	// Test user visits
	userVisits := visitManager.GetUserVisits(user.String())
	if len(userVisits) != 1 {
		t.Errorf("Expected 1 visit for user, got %d", len(userVisits))
	}

	// Test location visits
	locationVisits := visitManager.GetLocationVisits(location.ID)
	if len(locationVisits) != 1 {
		t.Errorf("Expected 1 visit for location, got %d", len(locationVisits))
	}
}

func TestVisitCooldown(t *testing.T) {

	creator := address("g1creator123")
	location := locationManager.AddLocation(creator, "Test Location", "Test", 48.8566, 2.3522, "test")

	user := address("g1user123")

	// First check-in should succeed
	visit1 := visitManager.CheckIn(user, location.ID, "test-proof-1")
	if visit1 == nil {
		t.Fatal("First check-in should succeed")
	}

	// Immediate second check-in should fail due to cooldown
	visit2 := visitManager.CheckIn(user, location.ID, "test-proof-2")
	if visit2 != nil {
		t.Error("Second check-in should fail due to cooldown")
	}
}

func TestVisitVerification(t *testing.T) {

	creator := address("g1creator123")
	location := locationManager.AddLocation(creator, "Test Location", "Test", 48.8566, 2.3522, "test")

	user := address("g1user123")

	// Generate a valid proof using the challenge-response system
	validProof := authManager.GenerateLocationChallenge(location.ID)
	visit := visitManager.CheckIn(user, location.ID, validProof)

	if visit == nil {
		t.Fatal("Failed to check in")
	}

	if !visit.Verified {
		t.Fatal("Visit should be marked as verified with a valid proof")
	}

	verified := visitManager.VerifyVisit(user.String(), location.ID, visit.Timestamp)
	if !verified {
		t.Error("Visit should be verified")
	}

	// Test non-existent visit
	notVerified := visitManager.VerifyVisit(user.String(), location.ID, visit.Timestamp+1000)
	if notVerified {
		t.Error("Non-existent visit should not be verified")
	}
}

func TestRecentVisits(t *testing.T) {

	creator := address("g1creator123")
	location1 := locationManager.AddLocation(creator, "Location 1", "Test", 48.8566, 2.3522, "test")
	location2 := locationManager.AddLocation(creator, "Location 2", "Test", 48.8600, 2.3500, "test")

	user1 := address("g1user1")
	user2 := address("g1user2")

	// Create visits with slight time differences
	visit1 := visitManager.CheckIn(user1, location1.ID, "proof1")
	// Note: In a real environment, visits would have different timestamps
	visit2 := visitManager.CheckIn(user2, location2.ID, "proof2")

	if visit1 == nil || visit2 == nil {
		t.Fatal("Failed to create visits")
	}

	// Test getting recent visits
	recentVisits := visitManager.GetRecentVisits(5)
	if len(recentVisits) < 2 {
		t.Errorf("Expected at least 2 recent visits, got %d", len(recentVisits))
	}

	// Check that visits are sorted by timestamp (newest first)
	if recentVisits[0].Timestamp < recentVisits[1].Timestamp {
		t.Error("Recent visits should be sorted by timestamp (newest first)")
	}
}

func TestVisitNotes(t *testing.T) {

	creator := address("g1creator123")
	location := locationManager.AddLocation(creator, "Test Location", "Test", 48.8566, 2.3522, "test")

	user := address("g1user123")
	visit := visitManager.CheckIn(user, location.ID, "test-proof")

	if visit == nil {
		t.Fatal("Failed to check in")
	}

	// Add notes
	success := visitManager.AddVisitNotes(visit.ID, "Great place!", user)
	if !success {
		t.Error("Failed to add visit notes")
	}

	// Verify notes were added
	retrieved := visitManager.GetVisit(visit.ID)
	if retrieved.Notes != "Great place!" {
		t.Errorf("Expected notes 'Great place!', got '%s'", retrieved.Notes)
	}

	// Test unauthorized note addition
	otherUser := address("g1other123")
	unauthorized := visitManager.AddVisitNotes(visit.ID, "Unauthorized", otherUser)
	if unauthorized {
		t.Error("Unauthorized user should not be able to add notes")
	}
}
