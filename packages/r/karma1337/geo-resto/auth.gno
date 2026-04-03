package georesto

import (
	"crypto/sha256"
	"encoding/hex"
	"math"
	"strconv"
	"time"

	"gno.land/p/nt/avl"
	"gno.land/p/nt/ownable/exts/authorizable"
)

// AuthManager handles access control and proof verification
type AuthManager struct {
	*authorizable.Authorizable           // Handles admin/verifier authorization
	rateLimitTracker           *avl.Tree // key (user:action) -> timestamp
	accessTokens               *avl.Tree // token -> expiration time
	Authorized                 *avl.Tree // address -> bool (trusted verifiers)
}

// NewAuthManager creates a new authentication manager instance
func NewAuthManager() *AuthManager {
	return &AuthManager{
		Authorizable:     authorizable.NewAuthorizable(),
		rateLimitTracker: avl.NewTree(),
		accessTokens:     avl.NewTree(),
		Authorized:       avl.NewTree(),
	}
}

// IsTrustedVerifier checks if an address is authorized (verifier)
func (am *AuthManager) IsTrustedVerifier(addr string) bool {
	v, ok := am.Authorized.Get(addr)
	if !ok {
		return false
	}
	return v.(bool)
}

// AddTrustedVerifier allows the owner to add an address as a trusted verifier
func (am *AuthManager) AddTrustedVerifier(addr string, caller address) bool {
	// Owner-only check
	if am.Authorizable.Owner() != caller {
		return false
	}

	// Add via the authorizable extension and mirror locally.
	err := am.Authorizable.AddToAuthList(address(addr))
	if err != nil {
		return false
	}
	am.Authorized.Set(addr, true)
	return true
}

// RemoveTrustedVerifier allows the owner to remove a trusted verifier
func (am *AuthManager) RemoveTrustedVerifier(addr string, caller address) bool {
	// Owner-only check
	if am.Authorizable.Owner() != caller {
		return false
	}

	err := am.Authorizable.DeleteFromAuthList(address(addr))
	if err != nil {
		return false
	}
	am.Authorized.Remove(addr)
	return true
}

// IsAdmin checks if an address is an admin (owner or authorized)
func (am *AuthManager) IsAdmin(addr string) bool {
	addrType := address(addr)
	return am.Authorizable.Owner() == addrType
}

// VerifyLocationProof verifies a cryptographic proof for location check-in
func (am *AuthManager) VerifyLocationProof(userAddress, locationID, proof string, timestamp int64) bool {
	// In a real implementation, this would involve more complex verification.
	// For now, we'll check if the proof is a valid challenge response.
	return am.VerifyLocationChallenge(locationID, proof)
}

// GenerateLocationProof generates a proof for location check-in
func (am *AuthManager) GenerateLocationProof(userAddress, locationID string, timestamp int64) string {
	return am.generateLocationProof(userAddress, locationID, timestamp)
}

// CanModifyLocation checks if a user can modify a location
func (am *AuthManager) CanModifyLocation(locationID string, user address) bool {
	location := locationManager.GetLocation(locationID)
	if location == nil {
		return false
	}

	userAddr := user.String()

	// Location creator can always modify
	if location.Creator.String() == userAddr {
		return true
	}

	// Admins can modify any location
	if am.IsAdmin(userAddr) {
		return true
	}
	// Trusted verifiers can modify for verification purposes
	if am.IsTrustedVerifier(userAddr) {
		return true
	}
	return false
}

// CanModifyEvent checks if a user can modify an event
func (am *AuthManager) CanModifyEvent(eventID string, user address) bool {
	event := eventManager.GetEvent(eventID)
	if event == nil {
		return false
	}

	userAddr := user.String()

	// Event creator can always modify
	if event.Creator.String() == userAddr {
		return true
	}

	// Admins can modify any event
	if am.IsAdmin(userAddr) {
		return true
	}

	return false
}

// ValidateCoordinates validates GPS coordinates
func (am *AuthManager) ValidateCoordinates(latitude, longitude float64) bool {
	return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
}

// ValidateProximity checks if user is within acceptable range of location
func (am *AuthManager) ValidateProximity(userLat, userLon, locationLat, locationLon, maxDistanceKm float64) bool {
	distance := haversine(userLat, userLon, locationLat, locationLon)
	return distance <= maxDistanceKm
}

// GenerateAccessToken generates a temporary access token for API access
func (am *AuthManager) GenerateAccessToken(userAddress string, expirationTime int64) string {
	data := userAddress + ":" + strconv.FormatInt(expirationTime, 10)
	hash := sha256.Sum256([]byte(data))
	token := hex.EncodeToString(hash[:])
	am.accessTokens.Set(token, expirationTime)
	return token
}

// VerifyAccessToken verifies an access token
func (am *AuthManager) VerifyAccessToken(token, userAddress string, currentTime int64) bool {
	expirationTimeValue, exists := am.accessTokens.Get(token)
	if !exists {
		return false // Token does not exist
	}

	expirationTime := expirationTimeValue.(int64)
	if currentTime > expirationTime {
		am.accessTokens.Remove(token) // Clean up expired token
		return false                  // Token has expired
	}

	return true
}

// CheckRateLimit implements basic rate limiting for API calls
func (am *AuthManager) CheckRateLimit(userAddress string, action string, cooldownSeconds int64) bool {
	key := userAddress + ":" + action
	lastActionTimeValue, exists := am.rateLimitTracker.Get(key)

	currentTime := time.Now().Unix()

	if exists {
		lastActionTime := lastActionTimeValue.(int64)
		if (currentTime - lastActionTime) < cooldownSeconds {
			return false // Rate limit exceeded
		}
	}

	am.rateLimitTracker.Set(key, currentTime)
	return true
}

// Helper methods

func (am *AuthManager) generateLocationProof(userAddress, locationID string, timestamp int64) string {
	data := userAddress + ":" + locationID + ":" + strconv.FormatInt(timestamp, 10)
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])
}

func (am *AuthManager) hashString(input string) string {
	hash := sha256.Sum256([]byte(input))
	return hex.EncodeToString(hash[:])
}

// VerifyZKProof verifies a zero-knowledge proof (placeholder for future implementation)
func (am *AuthManager) VerifyZKProof(proof string, publicInputs []string) bool {
	// Placeholder for ZK proof verification
	// In a real implementation, this would verify a zk-SNARK or zk-STARK proof
	// allowing users to prove they were at a location without revealing exact coordinates
	return len(proof) > 0 && len(publicInputs) > 0
}

// GenerateLocationChallenge generates a challenge for location verification
func (am *AuthManager) GenerateLocationChallenge(locationID string) string {
	// Generate a time-based challenge that can be solved by someone physically present
	timestamp := time.Now().Unix()
	data := locationID + ":" + strconv.FormatInt(timestamp/300, 10) // 5-minute windows
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:8]) // Return first 8 bytes as challenge
}

// VerifyLocationChallenge verifies a location challenge response
func (am *AuthManager) VerifyLocationChallenge(locationID, response string) bool {
	// Check if response matches any of the last few time windows (for clock drift tolerance)
	currentTime := time.Now().Unix()
	for i := 0; i < 3; i++ { // Check current and previous 2 windows
		timeWindow := (currentTime / 300) - int64(i)
		data := locationID + ":" + strconv.FormatInt(timeWindow, 10)
		hash := sha256.Sum256([]byte(data))
		expectedResponse := hex.EncodeToString(hash[:8])

		if response == expectedResponse {
			return true
		}
	}

	return false
}

// haversine calculates the distance between two points on Earth.
func haversine(lat1, lon1, lat2, lon2 float64) float64 {
	const R = 6371 // Earth radius in kilometers
	dLat := (lat2 - lat1) * (math.Pi / 180.0)
	dLon := (lon2 - lon1) * (math.Pi / 180.0)
	lat1Rad := lat1 * (math.Pi / 180.0)
	lat2Rad := lat2 * (math.Pi / 180.0)

	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1Rad)*math.Cos(lat2Rad)*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	return R * c
}
