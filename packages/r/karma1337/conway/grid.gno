package conway

const (
	// GRID_WIDTH defines the width of the Conway's Game of Life grid.
	GRID_WIDTH = 20
	// GRID_HEIGHT defines the height of the Conway's Game of Life grid.
	GRID_HEIGHT = 20
)

// Grid represents the game state for Conway's Game of Life.
type Grid struct {
	Cells      [GRID_HEIGHT][GRID_WIDTH]bool // Made public for optimization
	generation int
}

// NewGrid creates a new empty grid with generation 0.
func NewGrid() *Grid {
	return &Grid{
		Cells:      [GRID_HEIGHT][GRID_WIDTH]bool{},
		generation: 0,
	}
}

// SetCell sets a cell at coordinates (x, y) to alive (true) or dead (false).
func (g *Grid) SetCell(x, y int, alive bool) {
	if g.isValidCoordinate(x, y) {
		g.Cells[y][x] = alive
	}
}

// GetCell returns the state of a cell at coordinates (x, y).
func (g *Grid) GetCell(x, y int) bool {
	if g.isValidCoordinate(x, y) {
		return g.Cells[y][x]
	}
	return false
}

// isValidCoordinate checks if coordinates are within grid bounds.
func (g *Grid) isValidCoordinate(x, y int) bool {
	return x >= 0 && x < GRID_WIDTH && y >= 0 && y < GRID_HEIGHT
}

// GetGeneration returns the current generation number.
func (g *Grid) GetGeneration() int {
	return g.generation
}

// IncrementGeneration increases the generation counter by one.
func (g *Grid) IncrementGeneration() {
	g.generation++
}

// Clear resets the grid to all dead cells and generation 0.
func (g *Grid) Clear() {
	g.Cells = [GRID_HEIGHT][GRID_WIDTH]bool{}
	g.generation = 0
}

// Copy creates a deep copy of the grid with the same state and generation.
func (g *Grid) Copy() *Grid {
	newGrid := &Grid{
		generation: g.generation,
	}
	newGrid.Cells = g.Cells // Array copy in Go
	return newGrid
}
