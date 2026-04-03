package georesto

import (
	"strconv"
	"strings"
	"time"

	"chain/runtime"

	"gno.land/r/sys/users"
)

// Renderer handles the display and formatting of geographic data for web interface
type Renderer struct{}

// NewRenderer creates a new renderer instance
func NewRenderer() *Renderer {
	return &Renderer{}
}

// RenderMainPage displays the main interface
func (r *Renderer) RenderMainPage() string {
	var sb strings.Builder

	sb.WriteString("# 🌍 Geo-Resto - Decentralized Geographic Data\n\n")
	sb.WriteString("Welcome to Geo-Resto, a blockchain-based platform for sharing and verifying geographic data.\n\n")

	// Statistics
	allLocations := locationManager.GetAllLocations()
	activeEvents := eventManager.GetActiveEvents()

	sb.WriteString("## 📊 Platform Statistics\n")
	sb.WriteString("- **Total Locations**: " + strconv.Itoa(len(allLocations)) + "\n")
	sb.WriteString("- **Active Events**: " + strconv.Itoa(len(activeEvents)) + "\n")
	sb.WriteString("- **Total Visits**: " + r.getTotalVisitCount() + "\n\n")

	// Navigation
	sb.WriteString("## 🗺️ Navigation\n")
	sb.WriteString("- [View All Locations](/r/karma1337/georesto:locations)\n")
	sb.WriteString("- [Recent Visits](/r/karma1337/georesto:visits)\n")
	sb.WriteString("- [Active Events](/r/karma1337/georesto:events)\n")
	sb.WriteString("- [World Map](/r/karma1337/georesto:map)\n\n")

	// Quick Actions
	sb.WriteString("## 📲 Quick Actions\n")
	addLocationLink := GetAddLocationTxLink("", "", 0, 0, "")
	checkInLink := GetCheckInTxLink("", "")
	sb.WriteString("- [➕ Add New Location](" + addLocationLink + ")\n\n")
	sb.WriteString("- [🔔 Check In to a Location](" + checkInLink + ")\n\n")

	// Quick create event (user will fill details in wallet UI)
	createEventGenericLink := GetCreateEventTxLink("", "", "", 0, 0, 0)
	sb.WriteString("- [🎯 Create Event](" + createEventGenericLink + ")\n\n")

	// Owner-only actions: add/remove trusted verifiers
	// Use runtime.PreviousRealm() to detect the current caller for the web UI.
	caller := runtime.PreviousRealm().Address()
	if authManager.IsAdmin(caller.String()) {
		addTrusted := GetAddTrustedVerifierTxLink("")
		removeTrusted := GetRemoveTrustedVerifierTxLink("")
		sb.WriteString("- [🔐 Add Trusted Verifier](" + addTrusted + ") (owner only)\n\n")
		sb.WriteString("- [🔓 Remove Trusted Verifier](" + removeTrusted + ") (owner only)\n\n")
	}

	// Recent activity
	sb.WriteString("## 🔥 Recent Activity\n")
	recentVisits := visitManager.GetRecentVisits(5)
	if len(recentVisits) == 0 {
		sb.WriteString("No recent visits.\n")
	} else {
		for _, visit := range recentVisits {
			location := locationManager.GetLocation(visit.LocationID)
			if location != nil {
				sb.WriteString("- " + r.resolveName(visit.UserAddress) + " visited **" + location.Name + "** " + r.timeAgo(visit.Timestamp) + "\n")
			}
		}
	}

	return sb.String()
}

// RenderAllLocations displays all locations in the system
func (r *Renderer) RenderAllLocations() string {
	var sb strings.Builder

	sb.WriteString("# 📍 All Locations\n\n")

	locations := locationManager.GetAllLocations()
	if len(locations) == 0 {
		sb.WriteString("No locations have been added yet.\n")
		return sb.String()
	}

	// Group by category
	categories := make(map[string][]*Location)
	for _, location := range locations {
		category := location.Category
		if category == "" {
			category = "Uncategorized"
		}
		categories[category] = append(categories[category], location)
	}

	for category, categoryLocations := range categories {
		sb.WriteString("## " + category + "\n\n")
		for _, location := range categoryLocations {
			sb.WriteString(r.renderLocationCard(location))
		}
		sb.WriteString("\n")
	}

	return sb.String()
}

// RenderLocation displays details for a specific location
func (r *Renderer) RenderLocation(locationID string) string {
	var sb strings.Builder

	location := locationManager.GetLocation(locationID)
	if location == nil {
		return "Location not found."
	}

	sb.WriteString("# 📍 " + location.Name + "\n\n")

	// Location details
	sb.WriteString("**Description**: " + location.Description + "\n")
	sb.WriteString("**Category**: " + location.Category + "\n")
	sb.WriteString("**Coordinates**: " + strconv.FormatFloat(location.Latitude, 'f', 6, 64) + ", " + strconv.FormatFloat(location.Longitude, 'f', 6, 64) + "\n")
	sb.WriteString("**Created by**: " + r.resolveName(location.Creator.String()) + "\n")
	sb.WriteString("**Created**: " + r.formatTimestamp(location.CreatedAt) + "\n")
	sb.WriteString("**Total Visits**: " + strconv.Itoa(location.VisitCount) + "\n")
	if location.Verified {
		sb.WriteString("**Status**: ✅ Verified\n")
	} else {
		sb.WriteString("**Status**: ⏳ Pending verification\n")
	}
	sb.WriteString("\n")

	// Add transaction link for check-in
	sb.WriteString("## 📲 Actions\n\n")
	challenge := authManager.GenerateLocationChallenge(locationID)
	checkInLink := GetCheckInTxLink(locationID, challenge)
	sb.WriteString("- [🔔 Check In Here](" + checkInLink + ")\n")

	// Add create event link
	createEventLink := GetCreateEventTxLink(locationID, "", "", 0, 0, 0)
	sb.WriteString("- [🎯 Create Event Here](" + createEventLink + ")\n\n")

	// Recent visits
	visits := visitManager.GetLocationVisits(locationID)
	sb.WriteString("## 🔄 Recent Visits (" + strconv.Itoa(len(visits)) + ")\n\n")

	if len(visits) == 0 {
		sb.WriteString("No visits recorded yet.\n")
	} else {
		// Show last 10 visits
		limit := len(visits)
		if limit > 10 {
			limit = 10
		}

		for i := len(visits) - limit; i < len(visits); i++ {
			visit := visits[i]
			sb.WriteString("- " + r.resolveName(visit.UserAddress) + " - " + r.formatTimestamp(visit.Timestamp))
			if visit.Verified {
				sb.WriteString(" ✅")
			}
			sb.WriteString("\n")
		}
	}

	// Associated events
	events := eventManager.GetLocationEvents(locationID)
	if len(events) > 0 {
		sb.WriteString("\n## 🎯 Associated Events\n\n")
		for _, event := range events {
			sb.WriteString(r.renderEventCard(event))
		}
	}

	return sb.String()
}

// RenderUserVisits displays visits for a specific user
func (r *Renderer) RenderUserVisits(userAddress string) string {
	var sb strings.Builder

	sb.WriteString("# 👤 User Visits: " + r.resolveName(userAddress) + "\n\n")

	visits := visitManager.GetUserVisits(userAddress)
	if len(visits) == 0 {
		sb.WriteString("No visits recorded for this user.\n")
		return sb.String()
	}

	sb.WriteString("**Total Visits**: " + strconv.Itoa(len(visits)) + "\n\n")

	for _, visit := range visits {
		location := locationManager.GetLocation(visit.LocationID)
		if location != nil {
			sb.WriteString("## " + location.Name + "\n")
			sb.WriteString("- **Visited**: " + r.formatTimestamp(visit.Timestamp) + "\n")
			sb.WriteString("- **Location**: " + location.Category + " at " + strconv.FormatFloat(location.Latitude, 'f', 4, 64) + ", " + strconv.FormatFloat(location.Longitude, 'f', 4, 64) + "\n")
			if visit.Verified {
				sb.WriteString("- **Status**: ✅ Verified\n")
			} else {
				sb.WriteString("- **Status**: ⏳ Pending verification\n")
			}
			if visit.Notes != "" {
				sb.WriteString("- **Notes**: " + visit.Notes + "\n")
			}
			sb.WriteString("\n")
		}
	}

	return sb.String()
}

// RenderRecentVisits displays recent visits across all users
func (r *Renderer) RenderRecentVisits() string {
	var sb strings.Builder

	sb.WriteString("# 🔄 Recent Visits\n\n")

	visits := visitManager.GetRecentVisits(20)
	if len(visits) == 0 {
		sb.WriteString("No visits recorded yet.\n")
		return sb.String()
	}

	for _, visit := range visits {
		location := locationManager.GetLocation(visit.LocationID)
		if location != nil {
			sb.WriteString("- **" + location.Name + "** visited by " + r.resolveName(visit.UserAddress) + " " + r.timeAgo(visit.Timestamp))
			if visit.Verified {
				sb.WriteString(" ✅")
			}
			sb.WriteString("\n")
		}
	}

	return sb.String()
}

// RenderActiveEvents displays all active events
func (r *Renderer) RenderActiveEvents() string {
	var sb strings.Builder

	sb.WriteString("# 🎯 Active Events\n\n")

	events := eventManager.GetActiveEvents()
	if len(events) == 0 {
		sb.WriteString("No active events at the moment.\n")
		return sb.String()
	}

	for _, event := range events {
		sb.WriteString(r.renderEventCard(event))
	}

	return sb.String()
}

// RenderEvent displays details for a specific event
func (r *Renderer) RenderEvent(eventID string) string {
	var sb strings.Builder

	event := eventManager.GetEvent(eventID)
	if event == nil {
		return "Event not found."
	}

	sb.WriteString("# 🎯 " + event.Name + "\n\n")

	// Event details
	sb.WriteString("**Description**: " + event.Description + "\n")
	sb.WriteString("**Type**: " + eventManager.GetEventTypeString(event.EventType) + "\n")
	sb.WriteString("**Location**: ")

	location := locationManager.GetLocation(event.LocationID)
	if location != nil {
		sb.WriteString("[" + location.Name + "](/r/karma1337/georesto:locations/" + event.LocationID + ")")
	} else {
		sb.WriteString(event.LocationID)
	}
	sb.WriteString("\n")

	sb.WriteString("**Created by**: " + r.resolveName(event.Creator.String()) + "\n")
	sb.WriteString("**Start Time**: " + r.formatTimestamp(event.StartTime) + "\n")
	sb.WriteString("**End Time**: " + r.formatTimestamp(event.EndTime) + "\n")
	sb.WriteString("**Participants**: " + strconv.Itoa(len(event.Participants)))
	if event.MaxParticipants > 0 {
		sb.WriteString(" / " + strconv.Itoa(event.MaxParticipants))
	}
	sb.WriteString("\n")

	if event.IsActive {
		sb.WriteString("**Status**: 🟢 Active\n")
	} else {
		sb.WriteString("**Status**: 🔴 Inactive\n")
	}

	if event.Rewards != "" {
		sb.WriteString("**Rewards**: " + event.Rewards + "\n")
	}

	sb.WriteString("\n")

	// Add transaction link for joining event
	if event.IsActive {
		sb.WriteString("## 📲 Actions\n\n")
		joinLink := GetJoinEventTxLink(eventID)
		sb.WriteString("- [🎟️ Join Event](" + joinLink + ")\n\n")
	}

	// QR Code and Verification Info (for event organizers)
	sb.WriteString("## 📱 Event Verification\n\n")
	sb.WriteString("**QR Code**: `" + event.QRCode + "`\n\n")

	// Organizer-only: Generate a Verify Attendee tx link (organizers use this to verify attendees)
	verifyLink := GetVerifyPresenceTxLink(event.ID, "", "")
	sb.WriteString("- [✅ Verify Attendee (organizer)](" + verifyLink + ")\n\n")

	// Owner-only: add/remove trusted verifier links (prefill target addr with owner as a convenience)
	caller := runtime.PreviousRealm().Address()
	if authManager.IsAdmin(caller.String()) {
		addTrusted := GetAddTrustedVerifierTxLink(caller.String())
		removeTrusted := GetRemoveTrustedVerifierTxLink(caller.String())
		sb.WriteString("- [🔐 Add Trusted Verifier](" + addTrusted + ") (owner only)\n\n")
		sb.WriteString("- [🔓 Remove Trusted Verifier](" + removeTrusted + ") (owner only)\n\n")
	}

	// Verification Statistics
	totalParticipants := len(event.Participants)
	verifiedCount := len(event.VerifiedAttendees)
	if totalParticipants > 0 {
		verificationRate := float64(verifiedCount) / float64(totalParticipants) * 100.0
		rateStr := strconv.Itoa(int(verificationRate)) + "." + strconv.Itoa(int((verificationRate-float64(int(verificationRate)))*10))
		sb.WriteString("**Verification Stats**: " + strconv.Itoa(verifiedCount) + "/" + strconv.Itoa(totalParticipants) + " verified (" + rateStr + "%)\n\n")
	}

	// Verified Attendees List
	if len(event.VerifiedAttendees) > 0 {
		sb.WriteString("### ✅ Verified Attendees\n\n")
		for _, attendee := range event.VerifiedAttendees {
			sb.WriteString("- " + r.resolveName(attendee) + "\n")
		}
		sb.WriteString("\n")
	}

	sb.WriteString("\n")

	// Participants list
	if len(event.Participants) > 0 {
		sb.WriteString("## 👥 Participants\n\n")
		for i, participant := range event.Participants {
			sb.WriteString(strconv.Itoa(i+1) + ". " + r.resolveName(participant) + "\n")
		}
	}

	return sb.String()
}

// RenderWorldMap displays a text-based world map representation
func (r *Renderer) RenderWorldMap() string {
	var sb strings.Builder

	sb.WriteString("# 🗺️ World Map\n\n")
	sb.WriteString("*Text-based representation of location distribution*\n\n")

	locations := locationManager.GetAllLocations()
	if len(locations) == 0 {
		sb.WriteString("No locations to display on the map.\n")
		return sb.String()
	}

	// Group locations by region (simplified)
	regions := make(map[string][]*Location)
	for _, location := range locations {
		region := r.getRegionFromCoordinates(location.Latitude, location.Longitude)
		regions[region] = append(regions[region], location)
	}

	sb.WriteString("## 🌍 Locations by Region\n\n")
	for region, regionLocations := range regions {
		sb.WriteString("### " + region + " (" + strconv.Itoa(len(regionLocations)) + " locations)\n")
		for _, location := range regionLocations {
			sb.WriteString("- **" + location.Name + "** (" + strconv.FormatFloat(location.Latitude, 'f', 2, 64) + ", " + strconv.FormatFloat(location.Longitude, 'f', 2, 64) + ")\n")
		}
		sb.WriteString("\n")
	}

	return sb.String()
}

// Helper methods

func (r *Renderer) renderLocationCard(location *Location) string {
	var sb strings.Builder

	sb.WriteString("### [" + location.Name + "](/r/karma1337/georesto:locations/" + location.ID + ")\n")
	sb.WriteString(location.Description + "\n\n")
	sb.WriteString("📍 *" + strconv.FormatFloat(location.Latitude, 'f', 4, 64) + ", " + strconv.FormatFloat(location.Longitude, 'f', 4, 64) + "*")
	sb.WriteString(" | 👥 " + strconv.Itoa(location.VisitCount) + " visits")
	if location.Verified {
		sb.WriteString(" | ✅ Verified")
	}
	sb.WriteString("\n\n")

	return sb.String()
}

func (r *Renderer) renderEventCard(event *Event) string {
	var sb strings.Builder

	sb.WriteString("### [" + event.Name + "](/r/karma1337/georesto:events/" + event.ID + ")\n")
	sb.WriteString(event.Description + "\n\n")
	sb.WriteString("📅 " + r.formatTimestamp(event.StartTime) + " - " + r.formatTimestamp(event.EndTime) + "\n")
	sb.WriteString("👥 " + strconv.Itoa(len(event.Participants)) + " participants")
	if event.IsActive {
		sb.WriteString(" | 🟢 Active")
	}
	sb.WriteString("\n\n")

	return sb.String()
}

func (r *Renderer) truncateAddress(address string) string {
	if len(address) <= 12 {
		return address
	}
	return address[:6] + "..." + address[len(address)-6:]
}

func (r *Renderer) resolveName(addr string) string {
	// Try to resolve a human-readable username for the given address.
	data := users.ResolveAddress(address(addr))
	if data != nil {
		name := data.Name()
		if name != "" {
			return name
		}
	}
	// If no username is registered, return the full address so users can
	// identify or copy it for registration. Previously we truncated here.
	return addr
}

func (r *Renderer) formatTimestamp(timestamp int64) string {
	t := time.Unix(timestamp, 0)
	return t.Format("2006-01-02 15:04:05")
}

func (r *Renderer) timeAgo(timestamp int64) string {
	now := time.Now().Unix()
	diff := now - timestamp

	if diff < 60 {
		return "just now"
	} else if diff < 3600 {
		return strconv.FormatInt(diff/60, 10) + " minutes ago"
	} else if diff < 86400 {
		return strconv.FormatInt(diff/3600, 10) + " hours ago"
	} else {
		return strconv.FormatInt(diff/86400, 10) + " days ago"
	}
}

func (r *Renderer) getTotalVisitCount() string {
	count := 0
	for _, location := range locationManager.GetAllLocations() {
		count += location.VisitCount
	}
	return strconv.Itoa(count)
}

func (r *Renderer) getRegionFromCoordinates(lat, lon float64) string {
	// Simplified region mapping
	if lat >= 30 && lat <= 70 && lon >= -10 && lon <= 50 {
		return "Europe"
	} else if lat >= 25 && lat <= 50 && lon >= -130 && lon <= -60 {
		return "North America"
	} else if lat >= -35 && lat <= 15 && lon >= -85 && lon <= -35 {
		return "South America"
	} else if lat >= -35 && lat <= 35 && lon >= 10 && lon <= 55 {
		return "Africa"
	} else if lat >= 5 && lat <= 80 && lon >= 50 && lon <= 180 {
		return "Asia"
	} else if lat >= -50 && lat <= -10 && lon >= 110 && lon <= 180 {
		return "Australia/Oceania"
	} else {
		return "Other"
	}
}
