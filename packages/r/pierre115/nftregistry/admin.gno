package nftregistry

import (
	"chain/runtime"
)

// Admin functions

// AddAdmin - Add a new admin address
func AddAdmin(newAdmin address) {
	caller := runtime.PreviousRealm().Address()
	if caller != owner {
		panic("Only owner can add admins")
	}
	admins.Set(newAdmin.String(), true)
}

// RemoveAdmin - Remove an admin address
func RemoveAdmin(admin address) {
	caller := runtime.PreviousRealm().Address()
	if caller != owner {
		panic("Only owner can remove admins")
	}
	if admin == owner {
		panic("Cannot remove owner as admin")
	}
	admins.Remove(admin.String())
}

// SetRegistrationFee - Update the registration fee
func SetRegistrationFee(fee int64) {
	caller := runtime.PreviousRealm().Address()
	if caller != owner {
		panic("Only owner can set registration fee")
	}
	if fee < 0 {
		panic("Fee cannot be negative")
	}
	registrationFee = fee
}
