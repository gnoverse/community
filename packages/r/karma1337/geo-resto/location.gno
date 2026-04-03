package georesto

import (
	"strconv"
	"strings"
	"time"

	"gno.land/p/nt/avl"
)

// Location represents a geographic point with metadata
type Location struct {
	ID          string  // Unique identifier
	Name        string  // Human-readable name
	Description string  // Detailed description
	Latitude    float64 // GPS latitude
	Longitude   float64 // GPS longitude
	Category    string  // Type of location (restaurant, landmark, etc.)
	Creator     address // Address of the user who added this location
	CreatedAt   int64   // Unix timestamp
	VisitCount  int     // Number of check-ins at this location
	Verified    bool    // Whether location is verified by community
}

// LocationManager handles all location-related operations
type LocationManager struct {
	locations       *avl.Tree // ID -> Location
	locationsByUser *avl.Tree // User address -> []string (Location IDs)
	nextID          int
}

// NewLocationManager creates a new location manager instance
func NewLocationManager() *LocationManager {
	return &LocationManager{
		locations:       avl.NewTree(),
		locationsByUser: avl.NewTree(),
		nextID:          1,
	}
}

// AddLocation adds a new location to the system
func (lm *LocationManager) AddLocation(creator address, name, description string, latitude, longitude float64, category string) *Location {
	// Validate coordinates
	if latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180 {
		panic("Invalid coordinates")
	}

	// Validate required fields
	if strings.TrimSpace(name) == "" {
		panic("Location name is required")
	}

	// Generate unique ID
	id := "loc_" + strconv.Itoa(lm.nextID)
	lm.nextID++

	location := &Location{
		ID:          id,
		Name:        strings.TrimSpace(name),
		Description: strings.TrimSpace(description),
		Latitude:    latitude,
		Longitude:   longitude,
		Category:    category,
		Creator:     creator,
		CreatedAt:   time.Now().Unix(),
		VisitCount:  0,
		Verified:    false,
	}

	lm.locations.Set(id, location)

	// Track locations by user
	userAddr := creator.String()
	userLocations := lm.getUserLocationIDs(userAddr)
	userLocations = append(userLocations, id)
	lm.locationsByUser.Set(userAddr, userLocations)

	return location
}

// GetLocation retrieves a location by its ID
func (lm *LocationManager) GetLocation(id string) *Location {
	locationValue, exists := lm.locations.Get(id)
	if !exists {
		return nil
	}
	return locationValue.(*Location)
}

// GetAllLocations returns all locations
func (lm *LocationManager) GetAllLocations() []*Location {
	all := make([]*Location, 0)
	lm.locations.Iterate("", "", func(key string, value interface{}) bool {
		all = append(all, value.(*Location))
		return false // continue iteration
	})
	return all
}

// Helper: getUserLocationIDs retrieves location IDs for a user
func (lm *LocationManager) getUserLocationIDs(userAddr string) []string {
	value, exists := lm.locationsByUser.Get(userAddr)
	if !exists {
		return []string{}
	}
	return value.([]string)
}

// GetUserLocations returns all locations added by a specific user
func (lm *LocationManager) GetUserLocations(userAddress string) []*Location {
	locationIDs := lm.getUserLocationIDs(userAddress)
	if len(locationIDs) == 0 {
		return []*Location{}
	}
	locations := make([]*Location, 0, len(locationIDs))
	for _, id := range locationIDs {
		if location := lm.GetLocation(id); location != nil {
			locations = append(locations, location)
		}
	}
	return locations
}

// GetUserLocationCount returns the number of locations added by a user
func (lm *LocationManager) GetUserLocationCount(userAddress string) int {
	locationIDs := lm.getUserLocationIDs(userAddress)
	return len(locationIDs)
}

// IncrementVisitCount increments the visit count for a location
func (lm *LocationManager) IncrementVisitCount(id string) {
	if location := lm.GetLocation(id); location != nil {
		location.VisitCount++
	}
}

// VerifyLocation marks a location as verified
func (lm *LocationManager) VerifyLocation(id string, verifier address) bool {
	location := lm.GetLocation(id)
	if location == nil {
		return false
	}

	// Simple verification - in a real system, this would involve community voting
	// or trusted verifier addresses
	location.Verified = true
	return true
}

// GetNearbyLocations returns locations within a given radius using the Haversine formula.
func (lm *LocationManager) GetNearbyLocations(latitude, longitude, radiusKm float64) []*Location {
	nearby := make([]*Location, 0)
	lm.locations.Iterate("", "", func(key string, value interface{}) bool {
		location := value.(*Location)
		distance := haversine(latitude, longitude, location.Latitude, location.Longitude)
		if distance <= radiusKm {
			nearby = append(nearby, location)
		}
		return false
	})
	return nearby
}

// GetLocationsByCategory returns all locations in a specific category
func (lm *LocationManager) GetLocationsByCategory(category string) []*Location {
	byCategory := make([]*Location, 0)
	lm.locations.Iterate("", "", func(key string, value interface{}) bool {
		location := value.(*Location)
		if location.Category == category {
			byCategory = append(byCategory, location)
		}
		return false
	})
	return byCategory
}
