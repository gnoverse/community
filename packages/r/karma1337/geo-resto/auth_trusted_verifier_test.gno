package georesto

import (
	"testing"
)

func TestTrustedVerifierOwnerFlow(t *testing.T) {
	// Owner should be able to add and remove trusted verifiers
	owner := authManager.Authorizable.Owner()
	addr := "g1verifier_test"

	added := authManager.AddTrustedVerifier(addr, owner)
	if !added {
		t.Fatal("Owner should be able to add trusted verifier")
	}

	if !authManager.IsTrustedVerifier(addr) {
		t.Fatal("Added address should be trusted")
	}

	removed := authManager.RemoveTrustedVerifier(addr, owner)
	if !removed {
		t.Fatal("Owner should be able to remove trusted verifier")
	}

	if authManager.IsTrustedVerifier(addr) {
		t.Fatal("Removed address should not be trusted")
	}
}

func TestTrustedVerifierNonOwnerRejected(t *testing.T) {
	owner := authManager.Authorizable.Owner()
	nonOwner := address("g1notowner")
	addr := "g1verifier_test2"

	added := authManager.AddTrustedVerifier(addr, nonOwner)
	if added {
		t.Error("Non-owner should not be able to add trusted verifier")
	}

	// Ensure owner can add, then non-owner cannot remove
	addedOwner := authManager.AddTrustedVerifier(addr, owner)
	if !addedOwner {
		t.Fatal("Owner should be able to add trusted verifier")
	}

	removedByNonOwner := authManager.RemoveTrustedVerifier(addr, nonOwner)
	if removedByNonOwner {
		t.Error("Non-owner should not be able to remove trusted verifier")
	}

	// Clean up
	authManager.RemoveTrustedVerifier(addr, owner)
}
