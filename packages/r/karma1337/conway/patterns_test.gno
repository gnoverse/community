package conway

import (
	"testing"
)

// TestPatternManagerInitialization tests the creation and initialization of a pattern manager.
func TestPatternManagerInitialization(t *testing.T) {
	pm := NewPatternManager()
	if pm == nil {
		t.Error("Expected NewPatternManager to return a non-nil pattern manager")
	}

	// Test that we have available patterns
	patterns := pm.GetAvailablePatterns()
	if len(patterns) == 0 {
		t.Error("Expected at least one available pattern")
	}
}

// TestPatternLoading tests loading valid patterns into a grid.
func TestPatternLoading(t *testing.T) {
	pm := NewPatternManager()
	grid := NewGrid()

	patterns := pm.GetAvailablePatterns()
	if len(patterns) == 0 {
		t.Skip("No patterns available to test")
	}

	// Test loading the first available pattern
	success := pm.LoadPattern(grid, patterns[0], 5, 5)
	if !success {
		t.Errorf("Failed to load pattern: %s", patterns[0])
	}
}

// TestInvalidPatternLoading tests loading non-existent patterns and verifies proper error handling.
func TestInvalidPatternLoading(t *testing.T) {
	pm := NewPatternManager()
	grid := NewGrid()

	// Test loading a non-existent pattern
	success := pm.LoadPattern(grid, "nonexistent_pattern", 5, 5)
	if success {
		t.Error("Expected loading non-existent pattern to fail")
	}
}

// TestBlinkerPatternExists tests the availability and loading of the blinker pattern.
func TestBlinkerPatternExists(t *testing.T) {
	pm := NewPatternManager()
	patterns := pm.GetAvailablePatterns()

	// Check if blinker pattern exists
	found := false
	for _, pattern := range patterns {
		if pattern == "blinker" {
			found = true
			break
		}
	}

	if found {
		// Test loading blinker pattern
		grid := NewGrid()
		success := pm.LoadPattern(grid, "blinker", 5, 5)
		if !success {
			t.Error("Expected blinker pattern to load successfully")
		}
	}
}
