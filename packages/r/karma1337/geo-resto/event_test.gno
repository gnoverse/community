package georesto

import (
	"testing"
	"time"
)

func TestEventManager(t *testing.T) {
	// Setup - use global managers
	creator := address("g1creator123")

	// Create a test location using global manager
	location := locationManager.AddLocation(creator, "Test Location", "Test", 48.8566, 2.3522, "test")

	// Test creating an event
	startTime := time.Now().Unix() + 100 // Start in 100 seconds
	endTime := startTime + 3600          // End in 1 hour

	event := eventManager.CreateEvent(creator, location.ID, "Test Event", "A test event", int(EventTypeAirdrop), startTime, endTime)

	if event == nil {
		t.Fatal("Failed to create event")
	}

	if event.Name != "Test Event" {
		t.Errorf("Expected event name 'Test Event', got '%s'", event.Name)
	}

	if event.LocationID != location.ID {
		t.Errorf("Expected location ID %s, got %s", location.ID, event.LocationID)
	}

	// Test retrieving event
	retrieved := eventManager.GetEvent(event.ID)
	if retrieved == nil {
		t.Fatal("Failed to retrieve event")
	}
}

func TestEventJoining(t *testing.T) {
	creator := address("g1creator123")
	location := locationManager.AddLocation(creator, "Test Location", "Test", 48.8566, 2.3522, "test")

	// Create an active event (starting now)
	startTime := time.Now().Unix() // Starts right now
	endTime := startTime + 3600    // Ends in ~1 hour

	event := eventManager.CreateEvent(creator, location.ID, "Active Event", "An active event", int(EventTypeMeetup), startTime, endTime)

	user := address("g1user123")

	// Test joining with correct password
	success := eventManager.JoinEvent(event.ID, user)
	if !success {
		t.Error("Should be able to join event with correct password")
	}

	// Test checking if user is participant
	isParticipant := eventManager.IsUserParticipant(event.ID, user.String())
	if !isParticipant {
		t.Error("User should be a participant")
	}
}

func TestEventStatusUpdates(t *testing.T) {
	creator := address("g1creator123")
	location := locationManager.AddLocation(creator, "Test Location", "Test", 48.8566, 2.3522, "test")

	// Create a future event
	currentTime := time.Now().Unix()
	startTime := currentTime + 100
	endTime := startTime + 200

	event := eventManager.CreateEvent(creator, location.ID, "Future Event", "A future event", int(EventTypeMeetup), startTime, endTime)

	// Event should not be active yet
	if event.IsActive {
		t.Error("Future event should not be active")
	}

	// Test active events
	activeEvents := eventManager.GetActiveEvents()
	eventFound := false
	for _, activeEvent := range activeEvents {
		if activeEvent.ID == event.ID {
			eventFound = true
			break
		}
	}
	if eventFound {
		t.Error("Future event should not be in active list")
	}
}

func TestEventsByLocation(t *testing.T) {

	creator := address("g1creator123")
	location1 := locationManager.AddLocation(creator, "Location 1", "Test", 48.8566, 2.3522, "test")
	location2 := locationManager.AddLocation(creator, "Location 2", "Test", 48.8600, 2.3500, "test")

	startTime := time.Now().Unix() + 100
	endTime := startTime + 3600

	// Create events for different locations
	event1 := eventManager.CreateEvent(creator, location1.ID, "Event 1", "Test", int(EventTypeAirdrop), startTime, endTime)
	event2 := eventManager.CreateEvent(creator, location1.ID, "Event 2", "Test", int(EventTypeMeetup), startTime, endTime)
	_ = eventManager.CreateEvent(creator, location2.ID, "Event 3", "Test", int(EventTypeContest), startTime, endTime)

	// Test getting events by location
	location1Events := eventManager.GetLocationEvents(location1.ID)
	if len(location1Events) != 2 {
		t.Errorf("Expected 2 events for location 1, got %d", len(location1Events))
	}

	location2Events := eventManager.GetLocationEvents(location2.ID)
	if len(location2Events) != 1 {
		t.Errorf("Expected 1 event for location 2, got %d", len(location2Events))
	}

	// Verify event IDs
	eventIDs := make(map[string]bool)
	for _, event := range location1Events {
		eventIDs[event.ID] = true
	}

	if !eventIDs[event1.ID] || !eventIDs[event2.ID] {
		t.Error("Location 1 should contain both event 1 and event 2")
	}
}

func TestEventTypeString(t *testing.T) {

	tests := []struct {
		eventType EventType
		expected  string
	}{
		{EventTypeAirdrop, "Airdrop"},
		{EventTypeMeetup, "Meetup"},
		{EventTypeEmergency, "Emergency"},
		{EventTypeContest, "Contest"},
		{EventTypeCheckpoint, "Checkpoint"},
	}

	for _, test := range tests {
		result := eventManager.GetEventTypeString(test.eventType)
		if result != test.expected {
			t.Errorf("Expected event type string '%s', got '%s'", test.expected, result)
		}
	}
}

func TestEventValidation(t *testing.T) {

	creator := address("g1creator123")
	location := locationManager.AddLocation(creator, "Test Location", "Test", 48.8566, 2.3522, "test")

	currentTime := time.Now().Unix()

	// Test creating event with invalid times
	defer func() {
		if r := recover(); r == nil {
			t.Error("Expected panic for past start time")
		}
	}()

	// This should panic
	eventManager.CreateEvent(creator, location.ID, "Invalid Event", "Past start time", int(EventTypeAirdrop), currentTime-100, currentTime+100)
}
