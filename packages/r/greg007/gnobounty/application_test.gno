package gnobounty

import (
	"testing"

	"gno.land/p/nt/ownable"
	"gno.land/p/nt/testutils"
)

func TestAddValidator(t *testing.T) {
	// Setup owner - use testing.SetOriginCaller to set who is calling
	adminAddr := testutils.TestAddress("admin")
	testing.SetOriginCaller(adminAddr)

	// Initialize ownership with current caller as owner
	ownership = ownable.New()

	// Add a validator
	validator1 := testutils.TestAddress("validator1")
	AddValidator(cross, validator1)

	if !IsValidator(validator1) {
		t.Error("Validator should be active")
	}

	count := GetActiveValidatorCount()
	if count < 1 {
		t.Error("Expected at least 1 active validator")
	}
}

func TestValidatorList(t *testing.T) {
	// Setup owner - reuse same admin from previous test
	adminAddr := testutils.TestAddress("admin")
	testing.SetOriginCaller(adminAddr)

	// Add more validators
	validator2 := testutils.TestAddress("validator2")

	// Check if already exists before adding
	if !IsValidator(validator2) {
		AddValidator(cross, validator2)
	}

	if !IsValidator(validator2) {
		t.Error("Validator2 should be active")
	}

	count := GetActiveValidatorCount()
	if count < 2 {
		t.Errorf("Expected at least 2 active validators, got %d", count)
	}
}

func TestListValidators(t *testing.T) {
	list := ListValidators()
	if list == "" {
		t.Error("Expected non-empty validators list")
	}
}

func TestIsValidatorCheck(t *testing.T) {
	// Test a non-validator address
	nonValidator := testutils.TestAddress("nonvalidator")
	if IsValidator(nonValidator) {
		t.Error("Non-validator should not be recognized as validator")
	}

	// Test existing validator
	validator1 := testutils.TestAddress("validator1")
	if !IsValidator(validator1) {
		t.Error("validator1 should be recognized as validator")
	}
}

func TestGetValidator(t *testing.T) {
	validator1 := testutils.TestAddress("validator1")
	v := GetValidator(validator1)

	if v == nil {
		t.Fatal("Expected to find validator1")
	}

	if v.Address != validator1 {
		t.Error("Validator address mismatch")
	}

	if !v.Active {
		t.Error("Validator should be active")
	}
}
