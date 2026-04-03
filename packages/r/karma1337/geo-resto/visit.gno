package georesto

import (
	"crypto/sha256"
	"encoding/hex"
	"strconv"
	"time"

	"gno.land/p/nt/avl"
)

// Visit represents a user's check-in at a location
type Visit struct {
	ID          string // Unique visit identifier
	UserAddress string // Address of the user who visited
	LocationID  string // ID of the visited location
	Timestamp   int64  // Unix timestamp of the visit
	Proof       string // Cryptographic proof or verification data
	ProofHash   string // Hash of the proof for integrity
	Verified    bool   // Whether the visit has been verified
	Notes       string // Optional notes about the visit
}

// VisitManager handles all visit and check-in related operations
type VisitManager struct {
	visits           *avl.Tree // Visit ID -> Visit
	visitsByUser     *avl.Tree // User address -> []string (Visit IDs)
	visitsByLocation *avl.Tree // Location ID -> []string (Visit IDs)
	nextID           int
}

// NewVisitManager creates a new visit manager instance
func NewVisitManager() *VisitManager {
	return &VisitManager{
		visits:           avl.NewTree(),
		visitsByUser:     avl.NewTree(),
		visitsByLocation: avl.NewTree(),
		nextID:           1,
	}
}

// CheckIn records a user's visit to a location
func (vm *VisitManager) CheckIn(user address, locationID, proof string) *Visit {
	// Verify the location exists
	location := locationManager.GetLocation(locationID)
	if location == nil {
		return nil
	}

	userAddr := user.String()
	currentTime := time.Now().Unix()

	// Check for duplicate recent check-ins (prevent spam)
	if vm.hasRecentCheckIn(userAddr, locationID, currentTime, 3600) { // 1 hour cooldown
		return nil
	}

	// Generate unique visit ID
	visitID := "visit_" + strconv.Itoa(vm.nextID)
	vm.nextID++

	// Create proof hash for integrity
	proofHash := vm.generateProofHash(userAddr, locationID, proof, currentTime)

	visit := &Visit{
		ID:          visitID,
		UserAddress: userAddr,
		LocationID:  locationID,
		Timestamp:   currentTime,
		Proof:       proof,
		ProofHash:   proofHash,
		Verified:    vm.verifyProof(proof, userAddr, locationID),
		Notes:       "",
	}

	// Store the visit
	vm.visits.Set(visitID, visit)

	// Index by user
	userVisits := vm.getUserVisitIDs(userAddr)
	userVisits = append(userVisits, visitID)
	vm.visitsByUser.Set(userAddr, userVisits)

	// Index by location
	locationVisits := vm.getLocationVisitIDs(locationID)
	locationVisits = append(locationVisits, visitID)
	vm.visitsByLocation.Set(locationID, locationVisits)

	// Update location visit count
	locationManager.IncrementVisitCount(locationID)

	return visit
}

// GetVisit retrieves a visit by ID
func (vm *VisitManager) GetVisit(visitID string) *Visit {
	visitValue, exists := vm.visits.Get(visitID)
	if !exists {
		return nil
	}
	return visitValue.(*Visit)
}

// GetUserVisits returns all visits by a specific user
func (vm *VisitManager) GetUserVisits(userAddress string) []*Visit {
	visitIDs := vm.getUserVisitIDs(userAddress)
	if len(visitIDs) == 0 {
		return []*Visit{}
	}

	visits := make([]*Visit, 0, len(visitIDs))
	for _, id := range visitIDs {
		if visit := vm.GetVisit(id); visit != nil {
			visits = append(visits, visit)
		}
	}
	return visits
}

// GetLocationVisits returns all visits to a specific location
func (vm *VisitManager) GetLocationVisits(locationID string) []*Visit {
	visitIDs := vm.getLocationVisitIDs(locationID)
	if len(visitIDs) == 0 {
		return []*Visit{}
	}

	visits := make([]*Visit, 0, len(visitIDs))
	for _, id := range visitIDs {
		if visit := vm.GetVisit(id); visit != nil {
			visits = append(visits, visit)
		}
	}
	return visits
}

// GetUserVisitCount returns the total number of visits by a user
func (vm *VisitManager) GetUserVisitCount(userAddress string) int {
	visitIDs := vm.getUserVisitIDs(userAddress)
	return len(visitIDs)
}

// GetRecentVisits returns the most recent visits across all users
func (vm *VisitManager) GetRecentVisits(limit int) []*Visit {
	allVisits := make([]*Visit, 0)
	vm.visits.Iterate("", "", func(key string, value interface{}) bool {
		allVisits = append(allVisits, value.(*Visit))
		return false // continue iteration
	})

	// Use a more efficient sorting algorithm (insertion sort)
	for i := 1; i < len(allVisits); i++ {
		j := i
		for j > 0 && allVisits[j-1].Timestamp < allVisits[j].Timestamp {
			allVisits[j-1], allVisits[j] = allVisits[j], allVisits[j-1]
			j--
		}
	}

	if limit > 0 && limit < len(allVisits) {
		return allVisits[:limit]
	}
	return allVisits
}

// VerifyVisit provides cryptographic verification that a visit occurred
func (vm *VisitManager) VerifyVisit(userAddress, locationID string, timestamp int64) bool {
	userVisits := vm.GetUserVisits(userAddress)

	for _, visit := range userVisits {
		if visit.LocationID == locationID && visit.Timestamp == timestamp {
			return visit.Verified
		}
	}
	return false
}

// hasRecentCheckIn checks if user has checked in recently to prevent spam
func (vm *VisitManager) hasRecentCheckIn(userAddress, locationID string, currentTime int64, cooldownSeconds int64) bool {
	userVisits := vm.GetUserVisits(userAddress)

	for _, visit := range userVisits {
		if visit.LocationID == locationID {
			timeDiff := currentTime - visit.Timestamp
			if timeDiff < cooldownSeconds {
				return true
			}
		}
	}
	return false
}

// generateProofHash creates a hash for proof integrity
func (vm *VisitManager) generateProofHash(userAddress, locationID, proof string, timestamp int64) string {
	data := userAddress + locationID + proof + strconv.FormatInt(timestamp, 10)
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])
}

// verifyProof validates the provided proof by checking it against a time-based challenge
func (vm *VisitManager) verifyProof(proof, userAddress, locationID string) bool {
	// In a real implementation, this would involve:
	// 1. GPS coordinate verification
	// 2. QR code validation
	// 3. Time-based tokens
	// 4. Cryptographic signatures

	// We now use the challenge-response mechanism from authManager
	return authManager.VerifyLocationChallenge(locationID, proof)
}

// AddVisitNotes allows adding notes to an existing visit
func (vm *VisitManager) AddVisitNotes(visitID, notes string, user address) bool {
	visit := vm.GetVisit(visitID)
	if visit == nil || visit.UserAddress != user.String() {
		return false
	}

	visit.Notes = notes
	return true
}

// Helper: getUserVisitIDs retrieves visit IDs for a user
func (vm *VisitManager) getUserVisitIDs(userAddress string) []string {
	value, exists := vm.visitsByUser.Get(userAddress)
	if !exists {
		return []string{}
	}
	return value.([]string)
}

// Helper: getLocationVisitIDs retrieves visit IDs for a location
func (vm *VisitManager) getLocationVisitIDs(locationID string) []string {
	value, exists := vm.visitsByLocation.Get(locationID)
	if !exists {
		return []string{}
	}
	return value.([]string)
}
