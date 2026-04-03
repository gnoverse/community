package georesto

import (
	"chain/runtime"
	"strconv"
	"strings"

	"gno.land/p/moul/txlink"
)

var (
	// locationManager handles all location-related operations
	locationManager = NewLocationManager()
	// visitManager manages user visits and check-ins
	visitManager = NewVisitManager()
	// eventManager handles location-based events and airdrops
	eventManager = NewEventManager()
	// renderer handles the display and formatting of geographic data
	renderer = NewRenderer()
	// authManager handles access control and proof verification
	authManager = NewAuthManager()
)

// Render displays the main interface for the geo-resto application
func Render(path string) string {
	parts := strings.Split(path, "/")
	if len(parts) == 0 {
		return renderer.RenderMainPage()
	}

	switch parts[0] {
	case "locations":
		if len(parts) > 1 {
			return renderer.RenderLocation(parts[1])
		}
		return renderer.RenderAllLocations()
	case "visits":
		if len(parts) > 1 {
			return renderer.RenderUserVisits(parts[1])
		}
		return renderer.RenderRecentVisits()
	case "events":
		if len(parts) > 1 {
			return renderer.RenderEvent(parts[1])
		}
		return renderer.RenderActiveEvents()
	case "map":
		return renderer.RenderWorldMap()
	default:
		return renderer.RenderMainPage()
	}
}

// Helper functions for parsing string arguments

// parseFloat converts a string to float64, returns 0 on error
func parseFloat(s string) float64 {
	if s == "" {
		return 0
	}
	// Simple float parsing (supports decimal notation)
	var result float64
	var decimal float64
	var isDecimal bool
	var divisor float64 = 1
	negative := false

	if s[0] == '-' {
		negative = true
		s = s[1:]
	}

	for i := 0; i < len(s); i++ {
		c := s[i]
		if c == '.' {
			isDecimal = true
			continue
		}
		if c >= '0' && c <= '9' {
			if isDecimal {
				decimal = decimal*10 + float64(c-'0')
				divisor *= 10
			} else {
				result = result*10 + float64(c-'0')
			}
		}
	}

	result += decimal / divisor
	if negative {
		result = -result
	}
	return result
}

// parseInt converts a string to int, returns 0 on error
func parseInt(s string) int {
	if s == "" {
		return 0
	}
	var result int
	negative := false

	if s[0] == '-' {
		negative = true
		s = s[1:]
	}

	for i := 0; i < len(s); i++ {
		c := s[i]
		if c >= '0' && c <= '9' {
			result = result*10 + int(c-'0')
		}
	}

	if negative {
		result = -result
	}
	return result
}

// parseInt64 converts a string to int64, returns 0 on error
func parseInt64(s string) int64 {
	if s == "" {
		return 0
	}
	var result int64
	negative := false

	if s[0] == '-' {
		negative = true
		s = s[1:]
	}

	for i := 0; i < len(s); i++ {
		c := s[i]
		if c >= '0' && c <= '9' {
			result = result*10 + int64(c-'0')
		}
	}

	if negative {
		result = -result
	}
	return result
}

// Public API Functions

// AddLocation allows adding a new geographic location to the system
func AddLocation(name, description string, latitude, longitude float64, category string) string {
	caller := runtime.PreviousRealm().Address()
	if !authManager.CheckRateLimit(caller.String(), "add_location", 60) {
		return "Rate limit exceeded. Please try again later."
	}
	location := locationManager.AddLocation(caller, name, description, latitude, longitude, category)
	if location == nil {
		return "Failed to add location"
	}
	return "Location added with ID: " + location.ID
}

// AddLocationStr is a string-based wrapper for AddLocation (for txlink compatibility)
// The first parameter (_ realm) is automatically provided by Gno runtime
func AddLocationStr(_ realm, name, description, latStr, lonStr, category string) string {
	// Parse latitude and longitude from strings
	lat := parseFloat(latStr)
	lon := parseFloat(lonStr)
	return AddLocation(name, description, lat, lon, category)
}

// CheckIn records a user's visit to a location with proof of presence
// The first parameter (_ realm) is automatically provided by Gno runtime
func CheckIn(_ realm, locationID, proof string) string {
	caller := runtime.PreviousRealm().Address()
	visit := visitManager.CheckIn(caller, locationID, proof)
	if visit == nil {
		return "Failed to check-in"
	}
	return "Check-in successful! Visit ID: " + visit.ID
}

// CreateEvent creates a location-based event (like airdrops)
func CreateEvent(locationID, name, description string, eventType int, startTime, endTime int64) string {
	caller := runtime.PreviousRealm().Address()
	if !authManager.CheckRateLimit(caller.String(), "create_event", 300) { // 5 minute cooldown
		return "Rate limit exceeded. Please try again later."
	}
	event := eventManager.CreateEvent(caller, locationID, name, description, eventType, startTime, endTime)
	if event == nil {
		return "Failed to create event"
	}
	return "Event created with ID: " + event.ID
}

// CreateEventStr is a string-based wrapper for CreateEvent (for txlink compatibility)
// The first parameter (_ realm) is automatically provided by Gno runtime
func CreateEventStr(_ realm, locationID, name, description, eventTypeStr, startTimeStr, endTimeStr string) string {
	eventType := parseInt(eventTypeStr)
	startTime := parseInt64(startTimeStr)
	endTime := parseInt64(endTimeStr)
	return CreateEvent(locationID, name, description, eventType, startTime, endTime)
}

// JoinEvent allows a user to join an event with proper authentication
// The first parameter (_ realm) is automatically provided by Gno runtime
func JoinEvent(_ realm, eventID string) string {
	caller := runtime.PreviousRealm().Address()
	if !authManager.CheckRateLimit(caller.String(), "join_event:"+eventID, 60) {
		return "Rate limit exceeded. Please try again later."
	}
	success := eventManager.JoinEvent(eventID, caller)
	if success {
		return "Successfully joined event: " + eventID
	}
	return "Failed to join event"
}

// GetUserStats returns statistics for a specific user
func GetUserStats(userAddress string) string {
	if userAddress == "" {
		userAddress = runtime.PreviousRealm().Address().String()
	}

	visitCount := visitManager.GetUserVisitCount(userAddress)
	locationCount := locationManager.GetUserLocationCount(userAddress)

	return "User " + userAddress + " - Visits: " + strconv.Itoa(visitCount) + ", Locations Added: " + strconv.Itoa(locationCount)
}

// GetEventStats returns statistics for a specific event
func GetEventStats(eventID string) string {
	if eventID == "" {
		return "Error: Event ID is required"
	}

	caller := runtime.PreviousRealm().Address()
	total, verified, rate := eventManager.GetAttendeeVerificationStats(eventID, caller)
	rateStr := strconv.Itoa(int(rate)) + "." + strconv.Itoa(int((rate-float64(int(rate)))*10))
	return "Event " + eventID + " - Total Participants: " + strconv.Itoa(total) +
		", Verified: " + strconv.Itoa(verified) +
		", Verification Rate: " + rateStr + "%"
}

// GetLocationChallenge returns a challenge for a specific location
func GetLocationChallenge(locationID string) string {
	return authManager.GenerateLocationChallenge(locationID)
}

// VerifyPresence allows event organizers to verify attendee presence using a verification code
// The first parameter (_ realm) is automatically provided by Gno runtime
func VerifyPresence(_ realm, eventID, verificationCode, attendeeAddress string) string {
	caller := runtime.PreviousRealm().Address()
	success := eventManager.VerifyAttendeePresence(eventID, verificationCode, caller, attendeeAddress)
	if success {
		return "Successfully verified attendee: " + attendeeAddress
	}
	return "Failed to verify attendee"
}

// AddTrustedVerifier allows the realm owner to add a trusted verifier (organizer)
func AddTrustedVerifierStr(_ realm, addr string) string {
	caller := runtime.PreviousRealm().Address()
	success := authManager.AddTrustedVerifier(addr, caller)
	if success {
		return "Added trusted verifier: " + addr
	}
	return "Failed to add trusted verifier (owner only)"
}

// RemoveTrustedVerifier allows the realm owner to remove a trusted verifier
func RemoveTrustedVerifierStr(_ realm, addr string) string {
	caller := runtime.PreviousRealm().Address()
	success := authManager.RemoveTrustedVerifier(addr, caller)
	if success {
		return "Removed trusted verifier: " + addr
	}
	return "Failed to remove trusted verifier (owner only)"
}

// Transaction Link Helpers - Generate clickable transaction links for wallet integration

// GetAddLocationTxLink generates a transaction link for adding a new location
func GetAddLocationTxLink(name, description string, latitude, longitude float64, category string) string {
	return txlink.NewLink("AddLocationStr").
		AddArgs(
			"name", name,
			"description", description,
			"latStr", strconv.FormatFloat(latitude, 'f', 6, 64),
			"lonStr", strconv.FormatFloat(longitude, 'f', 6, 64),
			"category", category,
		).
		URL()
}

// GetCheckInTxLink generates a transaction link for checking in at a location
func GetCheckInTxLink(locationID, proof string) string {
	return txlink.NewLink("CheckIn").
		AddArgs(
			"locationID", locationID,
			"proof", proof,
		).
		URL()
}

// GetCreateEventTxLink generates a transaction link for creating an event
func GetCreateEventTxLink(locationID, name, description string, eventType int, startTime, endTime int64) string {
	return txlink.NewLink("CreateEventStr").
		AddArgs(
			"locationID", locationID,
			"name", name,
			"description", description,
			"eventTypeStr", strconv.Itoa(eventType),
			"startTimeStr", strconv.FormatInt(startTime, 10),
			"endTimeStr", strconv.FormatInt(endTime, 10),
		).
		URL()
}

// GetJoinEventTxLink generates a transaction link for joining an event
func GetJoinEventTxLink(eventID string) string {
	return txlink.NewLink("JoinEvent").
		AddArgs(
			"eventID", eventID,
		).
		URL()
}

// GetVerifyPresenceTxLink generates a transaction link for verifying attendee presence (organizer only)
func GetVerifyPresenceTxLink(eventID, verificationCode, attendeeAddress string) string {
	// This would be used by event organizers to verify attendee presence
	return txlink.NewLink("VerifyPresence").
		AddArgs(
			"eventID", eventID,
			"verificationCode", verificationCode,
			"attendeeAddress", attendeeAddress,
		).
		URL()
}

// GetAddTrustedVerifierTxLink generates a transaction link for adding a trusted verifier
func GetAddTrustedVerifierTxLink(addr string) string {
	return txlink.NewLink("AddTrustedVerifierStr").
		AddArgs(
			"addr", addr,
		).
		URL()
}

// GetRemoveTrustedVerifierTxLink generates a transaction link for removing a trusted verifier
func GetRemoveTrustedVerifierTxLink(addr string) string {
	return txlink.NewLink("RemoveTrustedVerifierStr").
		AddArgs(
			"addr", addr,
		).
		URL()
}
