package conway

// Pattern represents a Conway's Game of Life pattern with a name and cell configuration.
type Pattern struct {
	Name  string
	Cells [][]bool
}

// PatternManager handles pattern definitions and operations.
type PatternManager struct {
	patterns map[string]Pattern
}

// NewPatternManager creates a new pattern manager with predefined patterns.
func NewPatternManager() *PatternManager {
	pm := &PatternManager{
		patterns: make(map[string]Pattern),
	}
	pm.initializePatterns()
	return pm
}

// initializePatterns loads all predefined patterns into the pattern manager.
func (pm *PatternManager) initializePatterns() {
	// Still Life patterns
	pm.patterns["block"] = Pattern{
		Name: "Block",
		Cells: [][]bool{
			{true, true},
			{true, true},
		},
	}

	// Oscillator patterns
	pm.patterns["blinker"] = Pattern{
		Name: "Blinker",
		Cells: [][]bool{
			{true, true, true},
		},
	}
	// Toad pattern
	pm.patterns["toad"] = Pattern{
		Name: "Toad",
		Cells: [][]bool{
			{false, true, true, true},
			{true, true, true, false},
		},
	}
	// Beacon pattern
	pm.patterns["beacon"] = Pattern{
		Name: "Beacon",
		Cells: [][]bool{
			{true, true, false, false},
			{true, true, false, false},
			{false, false, true, true},
			{false, false, true, true},
		},
	}

	// Spaceship patterns
	pm.patterns["glider"] = Pattern{
		Name: "Glider",
		Cells: [][]bool{
			{false, true, false},
			{false, false, true},
			{true, true, true},
		},
	}

	// Pulsar pattern
	pm.patterns["pulsar"] = Pattern{
		Name: "Pulsar",
		Cells: [][]bool{
			{false, false, true, true, true, false, false, false, true, true, true, false, false},
			{false, false, false, false, false, false, false, false, false, false, false, false, false},
			{true, false, false, false, false, true, false, true, false, false, false, false, true},
			{true, false, false, false, false, true, false, true, false, false, false, false, true},
			{true, false, false, false, false, true, false, true, false, false, false, false, true},
			{false, false, true, true, true, false, false, false, true, true, true, false, false},
			{false, false, false, false, false, false, false, false, false, false, false, false, false},
			{false, false, true, true, true, false, false, false, true, true, true, false, false},
			{true, false, false, false, false, true, false, true, false, false, false, false, true},
			{true, false, false, false, false, true, false, true, false, false, false, false, true},
			{true, false, false, false, false, true, false, true, false, false, false, false, true},
			{false, false, false, false, false, false, false, false, false, false, false, false, false},
			{false, false, true, true, true, false, false, false, true, true, true, false, false},
		},
	}
}

// GetPattern returns a pattern by name and a boolean indicating if it exists.
func (pm *PatternManager) GetPattern(name string) (Pattern, bool) {
	pattern, exists := pm.patterns[name]
	return pattern, exists
}

// LoadPattern loads a pattern into the grid at the specified position.
// Returns true if the pattern was successfully loaded, false if the pattern doesn't exist.
func (pm *PatternManager) LoadPattern(grid *Grid, patternName string, startX, startY int) bool {
	pattern, exists := pm.GetPattern(patternName)
	if !exists {
		return false
	}

	for y, row := range pattern.Cells {
		for x, cell := range row {
			grid.SetCell(startX+x, startY+y, cell)
		}
	}
	return true
}

// GetAvailablePatterns returns a list of all available pattern names.
func (pm *PatternManager) GetAvailablePatterns() []string {
	var patterns []string
	for name := range pm.patterns {
		patterns = append(patterns, name)
	}
	return patterns
}
