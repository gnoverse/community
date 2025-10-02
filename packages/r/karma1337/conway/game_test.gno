package conway

import (
	"testing"
)

// TestGridCreation tests the creation and initial state of a new grid.
func TestGridCreation(t *testing.T) {
	// Test that we can create a new grid
	grid := NewGrid()
	if grid == nil {
		t.Error("Expected NewGrid to return a non-nil grid")
	}

	// Test initial state
	if grid.GetCell(0, 0) {
		t.Error("Expected new grid cells to be dead initially")
	}
}

// TestGameEngineCreation tests the creation of a new game engine instance.
func TestGameEngineCreation(t *testing.T) {
	// Test that we can create a game engine
	engine := NewGameEngine()
	if engine == nil {
		t.Error("Expected NewGameEngine to return a non-nil engine")
	}
}

// TestPatternManagerCreation tests the creation and initialization of a pattern manager.
func TestPatternManagerCreation(t *testing.T) {
	// Test that we can create a pattern manager
	pm := NewPatternManager()
	if pm == nil {
		t.Error("Expected NewPatternManager to return a non-nil pattern manager")
	}

	// Test that it has some patterns
	patterns := pm.GetAvailablePatterns()
	if len(patterns) == 0 {
		t.Error("Expected pattern manager to have at least one pattern")
	}
}

// TestRendererCreation tests the creation of a new renderer instance.
func TestRendererCreation(t *testing.T) {
	// Test that we can create a renderer
	r := NewRenderer()
	if r == nil {
		t.Error("Expected NewRenderer to return a non-nil renderer")
	}
}
