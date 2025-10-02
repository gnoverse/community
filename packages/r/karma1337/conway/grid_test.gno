package conway

import (
	"testing"
)

// TestGridOperations tests basic grid operations including cell setting and getting.
func TestGridOperations(t *testing.T) {
	// Test basic grid operations
	grid := NewGrid()
	if grid == nil {
		t.Error("Expected NewGrid to return a non-nil grid")
	}

	// Test setting and getting cells
	grid.SetCell(5, 5, true)
	if !grid.GetCell(5, 5) {
		t.Error("Expected cell to be alive after setting to true")
	}

	grid.SetCell(5, 5, false)
	if grid.GetCell(5, 5) {
		t.Error("Expected cell to be dead after setting to false")
	}
}

// TestGridGeneration tests generation tracking and incrementing functionality.
func TestGridGeneration(t *testing.T) {
	grid := NewGrid()

	// Initial generation should be 0
	if grid.GetGeneration() != 0 {
		t.Errorf("Expected initial generation to be 0, got %d", grid.GetGeneration())
	}

	// Test incrementing generation
	grid.IncrementGeneration()
	if grid.GetGeneration() != 1 {
		t.Errorf("Expected generation to be 1 after increment, got %d", grid.GetGeneration())
	}
}

// TestGridClear tests the grid clearing functionality and state reset.
func TestGridClear(t *testing.T) {
	grid := NewGrid()

	// Set some cells alive
	grid.SetCell(1, 1, true)
	grid.SetCell(2, 2, true)
	grid.SetCell(3, 3, true)

	// Clear the grid
	grid.Clear()

	// Check that all cells are dead
	if grid.GetCell(1, 1) || grid.GetCell(2, 2) || grid.GetCell(3, 3) {
		t.Error("Expected all cells to be dead after Clear")
	}

	// Generation should reset to 0
	if grid.GetGeneration() != 0 {
		t.Errorf("Expected generation to be 0 after clear, got %d", grid.GetGeneration())
	}
}
