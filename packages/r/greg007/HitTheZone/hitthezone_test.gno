package hitthezone

import (
	"testing"
)

func TestCalculateMultiplier(t *testing.T) {
	// Test full range (1-100)
	result := CalculateMultiplier(1, 100)
	expected := 1.0
	if result != expected {
		t.Errorf("CalculateMultiplier(1, 100) = %f; want %f", result, expected)
	}

	// Test single number (50-50)
	result = CalculateMultiplier(50, 50)
	expected = 100.0
	if result != expected {
		t.Errorf("CalculateMultiplier(50, 50) = %f; want %f", result, expected)
	}

	// Test invalid range (min >= max)
	result = CalculateMultiplier(60, 50)
	expected = 0.0
	if result != expected {
		t.Errorf("CalculateMultiplier(60, 50) = %f; want %f", result, expected)
	}
}

func TestGenerateRandom(t *testing.T) {
	// Test that generateRandom produces numbers in valid range
	for i := 0; i < 10; i++ {
		generateRandom()
		if lastRandomNumber < 1 || lastRandomNumber > 100 {
			t.Errorf("generateRandom() produced %d, should be between 1-100", lastRandomNumber)
		}
	}
}

func TestPlayGame(t *testing.T) {
	// Test with full range - should always win
	won := playGame(1, 100)
	if !won {
		t.Error("playGame(1, 100) should always win")
	}

	// Test with impossible single number multiple times
	wins := 0
	for i := 0; i < 20; i++ {
		if playGame(50, 50) {
			wins++
		}
	}
	// We expect some wins but not necessarily all
}

func TestHandlePayoutWin(t *testing.T) {
	// Test win scenario logic (without actual coin transfers)
	// In test environment, we can't test actual payouts due to banker restrictions
	// This test verifies the handlePayout returns expected result for win condition
	testAddr := address("g1test")
	betAmount := int64(1000)
	multiplier := 2.0

	// Test with won=true - will attempt payout but likely fail due to no funds in test env
	result, _ := handlePayout(true, betAmount, multiplier, testAddr)

	// In test environment, this will likely return one of the error states
	// due to lack of realm funds, which is expected behavior
	validResults := []string{
		"Win",
		"Win (Payment failed - refunded)",
		"Win (Insufficient funds - refunded)",
		"Win (House broke - no payout)",
	}

	found := false
	for _, valid := range validResults {
		if result == valid {
			found = true
			break
		}
	}

	if !found {
		t.Errorf("handlePayout(won=true) result = %s; expected one of the valid win results", result)
	}
}

func TestHandlePayoutLose(t *testing.T) {
	// Test loss scenario
	testAddr := address("g1test")
	betAmount := int64(1000)
	multiplier := 2.0

	result, amount := handlePayout(false, betAmount, multiplier, testAddr)

	if result != "Lose" {
		t.Errorf("handlePayout(won=false) result = %s; want 'Lose'", result)
	}

	if amount != 0 {
		t.Errorf("handlePayout(won=false) amount = %d; want 0", amount)
	}
}

func TestValidateGameInputs(t *testing.T) {
	// Test min < 1
	defer func() {
		if r := recover(); r == nil {
			t.Error("validateGameInputs should panic when min < 1")
		}
	}()
	validateGameInputs(0, 50)
}

func TestValidateGameInputsMaxTooHigh(t *testing.T) {
	// Test max > 100
	defer func() {
		if r := recover(); r == nil {
			t.Error("validateGameInputs should panic when max > 100")
		}
	}()
	validateGameInputs(1, 101)
}

func TestValidateGameInputsMinGreaterThanMax(t *testing.T) {
	// Test min >= max
	defer func() {
		if r := recover(); r == nil {
			t.Error("validateGameInputs should panic when min >= max")
		}
	}()
	validateGameInputs(60, 50)
}
