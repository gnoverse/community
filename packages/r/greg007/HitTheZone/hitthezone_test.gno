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