package gnobounty

import (
	"time"

	"gno.land/p/nt/ufmt"
)

// AddValidator adds a new validator to the system (Admin only)
func AddValidator(_ realm, validatorAddr address) {
	// Check if caller is admin
	ownership.AssertOwnedByPrevious()

	// Check if validator already exists
	if _, exists := validators.Get(string(validatorAddr)); exists {
		panic("validator already exists")
	}

	validator := &Validator{
		Address: validatorAddr,
		AddedAt: time.Now(),
		Active:  true,
	}

	validators.Set(string(validatorAddr), validator)
	validatorList = append(validatorList, validatorAddr)
}

// RemoveValidator removes a validator from the system (Admin only)
func RemoveValidator(_ realm, validatorAddr address) {
	// Check if caller is admin
	ownership.AssertOwnedByPrevious()

	validatorInterface, exists := validators.Get(string(validatorAddr))
	if !exists {
		panic("validator not found")
	}

	validator := validatorInterface.(*Validator)
	validator.Active = false

	// Remove from validator list
	newList := make([]address, 0)
	for _, addr := range validatorList {
		if addr != validatorAddr {
			newList = append(newList, addr)
		}
	}
	validatorList = newList
}

// selectRandomValidators selects N random validators for voting
// Uses a simple pseudo-random selection based on application ID
func selectRandomValidators(appID uint64, count int) []address {
	activeValidators := getActiveValidators()

	if len(activeValidators) < count {
		panic(ufmt.Sprintf("not enough active validators: need %d, have %d", count, len(activeValidators)))
	}

	// Simple pseudo-random selection using appID as seed
	selected := make([]address, 0, count)
	seed := appID

	for i := 0; i < count; i++ {
		index := int((seed + uint64(i)*7) % uint64(len(activeValidators)))
		selected = append(selected, activeValidators[index])

		// Remove selected validator to avoid duplicates
		activeValidators = append(activeValidators[:index], activeValidators[index+1:]...)
	}

	return selected
}

// getActiveValidators returns all active validator addresses
func getActiveValidators() []address {
	active := make([]address, 0)
	for _, addr := range validatorList {
		if IsValidator(addr) {
			active = append(active, addr)
		}
	}
	return active
}

// ListValidators returns information about all validators
func ListValidators() string {
	output := "# Validators\n\n"

	output += ufmt.Sprintf("**Total Active Validators:** %d\n\n", GetActiveValidatorCount())

	if len(validatorList) == 0 {
		output += "No validators registered yet.\n\n"
	} else {
		validators.Iterate("", "", func(key string, value interface{}) bool {
			validator := value.(*Validator)
			status := "✅ ACTIVE"
			if !validator.Active {
				status = "❌ INACTIVE"
			}
			output += ufmt.Sprintf("- %s %s - Added: %s\n",
				status,
				validator.Address,
				validator.AddedAt.Format("2006-01-02"))
			return false
		})
		output += "\n"
	}

	return output
}
