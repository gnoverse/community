package conway

import (
	"strconv"
	"strings"
)

var (
	// currentGrid holds the current state of the Conway's Game of Life grid
	currentGrid = NewGrid()
	// tempGrid is a reusable grid to avoid memory allocation on each step
	tempGrid = NewGrid()
	// gameEngine handles the game logic and evolution rules
	gameEngine = NewGameEngine()
	// patternManager manages predefined patterns that can be loaded into the grid
	patternManager = NewPatternManager()
	// renderer handles the display and formatting of the game state
	renderer = NewRenderer()
)

// SetCell sets a cell at coordinates (x, y) to alive (true) or dead (false).
func SetCell(_ realm, x, y int, alive bool) {
	currentGrid.SetCell(x, y, alive)
}

// GetCell returns the state of the cell at coordinates (x, y).
func GetCell(_ realm, x, y int) bool {
	return currentGrid.GetCell(x, y)
}

// Step advances the game by one generation according to Conway's rules.
func Step(_ realm) {
	gameEngine.StepInPlace(currentGrid, tempGrid)
	// Swap the grids to avoid copying
	currentGrid, tempGrid = tempGrid, currentGrid
}

// GetGeneration returns the current generation number.
func GetGeneration(_ realm) int {
	return currentGrid.GetGeneration()
}

// Clear resets the grid to all dead cells.
func Clear(_ realm) {
	currentGrid.Clear()
}

// LoadPattern loads a predefined pattern into the grid at the specified position.
// Returns true if the pattern was successfully loaded, false otherwise.
func LoadPattern(_ realm, pattern string, startX, startY int) bool {
	return patternManager.LoadPattern(currentGrid, pattern, startX, startY)
}

// GetAvailablePatterns returns a list of available pattern names.
func GetAvailablePatterns(_ realm) []string {
	return patternManager.GetAvailablePatterns()
}

// SetCellAt sets a cell using letter-number coordinates (e.g., "F5").
// Returns true if the coordinate was valid and the cell was set, false otherwise.
func SetCellAt(_ realm, coordinate string, alive bool) bool {
	col, row, valid := parseCoordinate(coordinate)
	if !valid {
		return false
	}
	currentGrid.SetCell(col, row, alive)
	return true
}

// GetCellAt returns the state of a cell using letter-number coordinates (e.g., "F5").
// Returns the cell state and a boolean indicating if the coordinate was valid.
func GetCellAt(_ realm, coordinate string) (bool, bool) {
	col, row, valid := parseCoordinate(coordinate)
	if !valid {
		return false, false
	}
	return currentGrid.GetCell(col, row), true
}

// LoadPatternAt loads a pattern using letter-number coordinates (e.g., "F5").
// Returns true if the coordinate was valid and the pattern was loaded, false otherwise.
func LoadPatternAt(_ realm, pattern string, coordinate string) bool {
	col, row, valid := parseCoordinate(coordinate)
	if !valid {
		return false
	}
	return patternManager.LoadPattern(currentGrid, pattern, col, row)
}

// Render displays the current state of the game as a formatted string.
func Render(path string) string {
	var output strings.Builder

	output.WriteString("# Conway's Game of Life\n\n")
	output.WriteString("Generation: " + strconv.Itoa(currentGrid.GetGeneration()) + "\n\n")

	output.WriteString(renderer.RenderHelp(patternManager))
	output.WriteString(renderer.RenderGrid(currentGrid))

	return output.String()
}

// letterToColumn converts a letter to column number (A=0, B=1, etc.).
// Returns -1 if the letter is invalid or out of range.
func letterToColumn(letter string) int {
	if len(letter) == 0 {
		return -1
	}
	// Convert to uppercase and get first character
	upper := strings.ToUpper(letter)
	col := int(upper[0] - 'A')
	if col < 0 || col >= GRID_WIDTH {
		return -1
	}
	return col
}

// columnToLetter converts a column number to letter (0=A, 1=B, etc.).
// Returns an empty string if the column is out of range.
func columnToLetter(col int) string {
	if col < 0 || col >= GRID_WIDTH {
		return ""
	}
	return string(rune('A' + col))
}

// parseCoordinate parses coordinates like "F5" into column and row numbers.
// Returns the column, row, and a boolean indicating if the coordinate was valid.
func parseCoordinate(coordinate string) (int, int, bool) {
	if len(coordinate) < 2 {
		return -1, -1, false
	}

	// Extract letter part and number part
	letter := coordinate[:1]
	numberStr := coordinate[1:]

	// Convert letter to column
	col := letterToColumn(letter)
	if col == -1 {
		return -1, -1, false
	}

	// Convert number string to row
	row, err := strconv.Atoi(numberStr)
	if err != nil || row < 0 || row >= GRID_HEIGHT {
		return -1, -1, false
	}

	return col, row, true
}
