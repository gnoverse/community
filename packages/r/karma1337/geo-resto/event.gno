package georesto

import (
	"crypto/sha256"
	"encoding/hex"
	"strconv"
	"strings"
	"time"

	"gno.land/p/nt/avl"
)

// EventType defines the type of location-based event
type EventType int

const (
	EventTypeMeetup EventType = iota
	EventTypeAirdrop
	EventTypeQuest
	EventTypeContest
	EventTypeCheckpoint
	EventTypeEmergency
)

// Event represents a location-based event (airdrops, meetups, etc.)
type Event struct {
	ID                 string    // Unique event identifier
	LocationID         string    // Associated location ID
	Creator            address   // Event creator
	Name               string    // Event name
	Description        string    // Event description
	EventType          EventType // Type of event
	StartTime          int64     // Event start timestamp
	EndTime            int64     // Event end timestamp
	CreatedAt          int64     // Creation timestamp
	Participants       []string  // List of participant addresses
	MaxParticipants    int       // Maximum number of participants (0 = unlimited)
	IsActive           bool      // Whether the event is currently active
	Rewards            string    // Description of rewards/airdrops
	QRCode             string    // QR code data for event verification
	VerificationSecret string    // Secret key for generating verification codes
	VerifiedAttendees  []string  // List of verified attendee addresses
}

// EventManager handles all event-related operations
type EventManager struct {
	events           *avl.Tree // Event ID -> Event
	eventsByLocation *avl.Tree // Location ID -> []string (Event IDs)
	eventsByCreator  *avl.Tree // Creator address -> []string (Event IDs)
	activeEvents     []string  // Currently active event IDs
	nextID           int
}

// NewEventManager creates a new event manager instance
func NewEventManager() *EventManager {
	return &EventManager{
		events:           avl.NewTree(),
		eventsByLocation: avl.NewTree(),
		eventsByCreator:  avl.NewTree(),
		activeEvents:     make([]string, 0),
		nextID:           1,
	}
}

// CreateEvent creates a new event (password removed for security)
func (em *EventManager) CreateEvent(creator address, locationID, name, description string, eventType int, startTime, endTime int64) *Event {
	// Verify the location exists
	location := locationManager.GetLocation(locationID)
	if location == nil {
		panic("Location does not exist")
	}

	// Validate event times
	currentTime := time.Now().Unix()
	if startTime < currentTime {
		panic("Event start time cannot be in the past")
	}
	if endTime <= startTime {
		panic("Event end time must be after start time")
	}

	// Validate required fields
	if strings.TrimSpace(name) == "" {
		panic("Event name is required")
	}

	// Generate unique event ID
	eventID := "event_" + strconv.Itoa(em.nextID)
	em.nextID++

	// Generate verification secret for QR codes
	verificationSecret := em.generateVerificationSecret(eventID, creator.String())

	// Generate QR code data (contains event ID and verification info)
	qrData := em.generateQRCode(eventID, verificationSecret)

	event := &Event{
		ID:                 eventID,
		LocationID:         locationID,
		Creator:            creator,
		Name:               strings.TrimSpace(name),
		Description:        strings.TrimSpace(description),
		EventType:          EventType(eventType),
		StartTime:          startTime,
		EndTime:            endTime,
		CreatedAt:          currentTime,
		Participants:       make([]string, 0),
		MaxParticipants:    0, // Unlimited by default
		IsActive:           false,
		Rewards:            "",
		QRCode:             qrData,
		VerificationSecret: verificationSecret,
		VerifiedAttendees:  make([]string, 0),
	}

	// Store the event
	em.events.Set(eventID, event)

	// Index by location
	locationEvents := em.getEventIDsForLocation(locationID)
	locationEvents = append(locationEvents, eventID)
	em.eventsByLocation.Set(locationID, locationEvents)

	// Index by creator
	creatorAddr := creator.String()
	creatorEvents := em.getEventIDsForCreator(creatorAddr)
	creatorEvents = append(creatorEvents, eventID)
	em.eventsByCreator.Set(creatorAddr, creatorEvents)

	// Activate event if it should start now
	em.updateEventStatus(event)

	return event
}

// JoinEvent allows a user to join an event
func (em *EventManager) JoinEvent(eventID string, user address) bool {
	event := em.GetEvent(eventID)
	if event == nil {
		return false
	}

	// Check if event is active
	em.updateEventStatus(event)
	if !event.IsActive {
		return false
	}

	userAddr := user.String()

	// Check if user is already a participant
	for _, participant := range event.Participants {
		if participant == userAddr {
			return true // Already joined
		}
	}

	// Check participant limit
	if event.MaxParticipants > 0 && len(event.Participants) >= event.MaxParticipants {
		return false
	}

	// Add user to participants
	event.Participants = append(event.Participants, userAddr)
	return true
}

// GetEvent retrieves an event by ID
func (em *EventManager) GetEvent(eventID string) *Event {
	eventValue, exists := em.events.Get(eventID)
	if !exists {
		return nil
	}
	return eventValue.(*Event)
}

// GetActiveEvents returns all currently active events
func (em *EventManager) GetActiveEvents() []*Event {
	em.updateActiveEvents()

	events := make([]*Event, 0, len(em.activeEvents))
	for _, eventID := range em.activeEvents {
		if event := em.GetEvent(eventID); event != nil {
			events = append(events, event)
		}
	}
	return events
}

// GetLocationEvents returns all events for a specific location
func (em *EventManager) GetLocationEvents(locationID string) []*Event {
	eventIDs := em.getEventIDsForLocation(locationID)
	if len(eventIDs) == 0 {
		return []*Event{}
	}

	events := make([]*Event, 0, len(eventIDs))
	for _, id := range eventIDs {
		if event := em.GetEvent(id); event != nil {
			events = append(events, event)
		}
	}
	return events
}

// Helper: getEventIDsForLocation retrieves event IDs for a location
func (em *EventManager) getEventIDsForLocation(locationID string) []string {
	value, exists := em.eventsByLocation.Get(locationID)
	if !exists {
		return []string{}
	}
	return value.([]string)
}

// Helper: getEventIDsForCreator retrieves event IDs for a creator
func (em *EventManager) getEventIDsForCreator(creatorAddr string) []string {
	value, exists := em.eventsByCreator.Get(creatorAddr)
	if !exists {
		return []string{}
	}
	return value.([]string)
}

// GetCreatorEvents returns all events by a specific creator
func (em *EventManager) GetCreatorEvents(creatorAddress string) []*Event {
	eventIDs := em.getEventIDsForCreator(creatorAddress)
	if len(eventIDs) == 0 {
		return []*Event{}
	}
	events := make([]*Event, 0, len(eventIDs))
	for _, id := range eventIDs {
		if event := em.GetEvent(id); event != nil {
			events = append(events, event)
		}
	}
	return events
}

// SetEventRewards sets the rewards for an event
func (em *EventManager) SetEventRewards(eventID, rewards string, user address) bool {
	event := em.GetEvent(eventID)
	if event == nil || event.Creator.String() != user.String() {
		return false
	}

	event.Rewards = rewards
	return true
}

// SetMaxParticipants sets the maximum number of participants for an event
func (em *EventManager) SetMaxParticipants(eventID string, maxParticipants int, user address) bool {
	event := em.GetEvent(eventID)
	if event == nil || event.Creator.String() != user.String() {
		return false
	}

	event.MaxParticipants = maxParticipants
	return true
}

// IsUserParticipant checks if a user is a participant in an event
func (em *EventManager) IsUserParticipant(eventID, userAddress string) bool {
	event := em.GetEvent(eventID)
	if event == nil {
		return false
	}

	for _, participant := range event.Participants {
		if participant == userAddress {
			return true
		}
	}
	return false
}

// updateEventStatus updates the active status of an event
func (em *EventManager) updateEventStatus(event *Event) {
	currentTime := time.Now().Unix()
	wasActive := event.IsActive

	event.IsActive = currentTime >= event.StartTime && currentTime <= event.EndTime

	// Update active events list if status changed
	if wasActive != event.IsActive {
		em.updateActiveEvents()
	}
}

// updateActiveEvents rebuilds the list of active events
func (em *EventManager) updateActiveEvents() {
	currentTime := time.Now().Unix()
	em.activeEvents = make([]string, 0)
	em.events.Iterate("", "", func(key string, value interface{}) bool {
		event := value.(*Event)
		if currentTime >= event.StartTime && currentTime <= event.EndTime {
			event.IsActive = true
			em.activeEvents = append(em.activeEvents, key)
		} else {
			event.IsActive = false
		}
		return false // continue
	})
}

// GetEventTypeString returns the string representation of an event type
func (em *EventManager) GetEventTypeString(eventType EventType) string {
	switch eventType {
	case EventTypeMeetup:
		return "Meetup"
	case EventTypeAirdrop:
		return "Airdrop"
	case EventTypeQuest:
		return "Quest"
	case EventTypeContest:
		return "Contest"
	case EventTypeCheckpoint:
		return "Checkpoint"
	case EventTypeEmergency:
		return "Emergency"
	default:
		return "Unknown"
	}
}

// generateQRCode generates QR code data for an event
func (em *EventManager) generateQRCode(eventID, secret string) string {
	// Simple QR code generation logic (placeholder)
	// In a real app, this would be a URL or structured data for a QR code scanner
	return "geo-resto:event?id=" + eventID + "&secret=" + secret
}

// generateVerificationSecret generates a secret key for event verification
func (em *EventManager) generateVerificationSecret(eventID, creatorAddress string) string {
	// Create a unique secret using event ID, creator, and current time
	data := eventID + ":" + creatorAddress + ":" + strconv.Itoa(int(time.Now().UnixNano()))
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])
}

// GenerateAttendeeVerificationCode generates a time-sensitive code for an attendee to prove presence
func (em *EventManager) GenerateAttendeeVerificationCode(eventID string, attendeeAddress address) string {
	event := em.GetEvent(eventID)
	if event == nil {
		return ""
	}

	// Only the event creator can generate verification codes
	if event.Creator.String() != attendeeAddress.String() {
		return ""
	}

	// Generate verification code using event secret and current timestamp
	timestamp := strconv.Itoa(int(time.Now().Unix()))
	data := eventID + ":" + event.VerificationSecret + ":" + timestamp
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])[:12] // 12-character code
}

// VerifyAttendeePresence verifies an attendee's presence using a verification code
func (em *EventManager) VerifyAttendeePresence(eventID, verificationCode string, organizerAddress address, attendeeAddress string) bool {
	event := em.GetEvent(eventID)
	if event == nil {
		return false
	}

	// Only the event creator/organizer can verify attendees
	if event.Creator.String() != organizerAddress.String() {
		return false
	}

	// Check if the verification code is valid (generated within last 5 minutes)
	currentTime := time.Now().Unix()
	for i := 0; i < 5; i++ { // Check last 5 minutes
		checkTime := currentTime - int64(i*60)
		expectedData := eventID + ":" + event.VerificationSecret + ":" + strconv.Itoa(int(checkTime))
		hash := sha256.Sum256([]byte(expectedData))
		expectedCode := hex.EncodeToString(hash[:])[:12]

		if verificationCode == expectedCode {
			// Add to verified attendees if not already verified
			for _, verified := range event.VerifiedAttendees {
				if verified == attendeeAddress {
					return true // Already verified
				}
			}
			event.VerifiedAttendees = append(event.VerifiedAttendees, attendeeAddress)
			return true
		}
	}

	return false
}

// GetEventQRCode returns the QR code for an event (organizer only)
func (em *EventManager) GetEventQRCode(eventID string, requesterAddress address) string {
	event := em.GetEvent(eventID)
	if event == nil {
		return ""
	}

	// Only the event creator can access the QR code
	if event.Creator.String() != requesterAddress.String() {
		return ""
	}

	return event.QRCode
}

// GetVerifiedAttendees returns the list of verified attendees (organizer only)
func (em *EventManager) GetVerifiedAttendees(eventID string, requesterAddress address) []string {
	event := em.GetEvent(eventID)
	if event == nil {
		return []string{}
	}

	// Only the event creator can see verified attendees
	if event.Creator.String() != requesterAddress.String() {
		return []string{}
	}

	return event.VerifiedAttendees
}

// GetAttendeeVerificationStats returns statistics on attendee verification (organizer only)
func (em *EventManager) GetAttendeeVerificationStats(eventID string, requesterAddress address) (int, int, float64) {
	event := em.GetEvent(eventID)
	if event == nil {
		return 0, 0, 0.0
	}

	// Only the event creator can see stats
	if event.Creator.String() != requesterAddress.String() {
		return 0, 0, 0.0
	}

	totalParticipants := len(event.Participants)
	verifiedAttendees := len(event.VerifiedAttendees)
	verificationRate := 0.0

	if totalParticipants > 0 {
		verificationRate = float64(verifiedAttendees) / float64(totalParticipants) * 100.0
	}

	return totalParticipants, verifiedAttendees, verificationRate
}
