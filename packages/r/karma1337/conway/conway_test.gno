package conway

import (
	"testing"
)

// TestCoordinateParsing tests the parseCoordinate function with valid and invalid inputs.
func TestCoordinateParsing(t *testing.T) {
	// Test valid coordinate parsing
	col, row, valid := parseCoordinate("F5")
	if !valid {
		t.Error("Expected F5 to be valid coordinate")
	}
	if col != 5 || row != 5 {
		t.Errorf("Expected F5 to parse to (5,5), got (%d,%d)", col, row)
	}

	// Test invalid coordinates
	_, _, valid = parseCoordinate("")
	if valid {
		t.Error("Expected empty string to be invalid")
	}

	_, _, valid = parseCoordinate("AA")
	if valid {
		t.Error("Expected coordinate without number to be invalid")
	}
}

// TestLetterColumnConversion tests the letterToColumn and columnToLetter conversion functions.
func TestLetterColumnConversion(t *testing.T) {
	// Test letter to column conversion
	col := letterToColumn("A")
	if col != 0 {
		t.Errorf("Expected A to convert to 0, got %d", col)
	}

	col = letterToColumn("F")
	if col != 5 {
		t.Errorf("Expected F to convert to 5, got %d", col)
	}

	// Test invalid input
	col = letterToColumn("")
	if col != -1 {
		t.Errorf("Expected empty string to return -1, got %d", col)
	}

	// Test column to letter conversion
	letter := columnToLetter(0)
	if letter != "A" {
		t.Errorf("Expected 0 to convert to A, got %s", letter)
	}

	letter = columnToLetter(5)
	if letter != "F" {
		t.Errorf("Expected 5 to convert to F, got %s", letter)
	}

	// Test invalid column
	letter = columnToLetter(-1)
	if letter != "" {
		t.Errorf("Expected -1 to return empty string, got %s", letter)
	}
}
