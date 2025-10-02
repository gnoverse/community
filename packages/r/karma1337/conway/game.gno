package conway

// GameEngine handles the core Conway's Game of Life logic.
type GameEngine struct{}

// NewGameEngine creates a new game engine instance.
func NewGameEngine() *GameEngine {
	return &GameEngine{}
}

// CountNeighbors counts the number of living neighbors for a cell at coordinates (x, y).
func (ge *GameEngine) CountNeighbors(grid *Grid, x, y int) int {
	count := 0
	for dy := -1; dy <= 1; dy++ {
		for dx := -1; dx <= 1; dx++ {
			if dx == 0 && dy == 0 {
				continue // Skip the cell itself
			}
			if grid.GetCell(x+dx, y+dy) {
				count++
			}
		}
	}
	return count
}

// countNeighborsOptimized is an optimized version that avoids function call overhead
// and bounds checking by accessing the cells array directly.
func (ge *GameEngine) countNeighborsOptimized(grid *Grid, x, y int) int {
	count := 0
	
	// Check all 8 neighbors with bounds checking optimized
	for dy := -1; dy <= 1; dy++ {
		for dx := -1; dx <= 1; dx++ {
			if dx == 0 && dy == 0 {
				continue // Skip the cell itself
			}
			
			nx, ny := x+dx, y+dy
			// Inline bounds check for better performance
			if nx >= 0 && nx < GRID_WIDTH && ny >= 0 && ny < GRID_HEIGHT {
				if grid.Cells[ny][nx] {
					count++
				}
			}
		}
	}
	return count
}

// ApplyRules applies Conway's Game of Life rules to determine the next cell state.
// Returns true if the cell should be alive in the next generation, false otherwise.
func (ge *GameEngine) ApplyRules(isAlive bool, neighborCount int) bool {
	// Conway's Game of Life rules:
	// 1. Any live cell with 2-3 live neighbors survives
	// 2. Any dead cell with exactly 3 live neighbors becomes alive
	// 3. All other live cells die, all other dead cells stay dead
	if isAlive {
		return neighborCount == 2 || neighborCount == 3
	}
	return neighborCount == 3
}

// Step advances the game by one generation and returns the new grid state.
func (ge *GameEngine) Step(grid *Grid) *Grid {
	newGrid := NewGrid()
	newGrid.generation = grid.generation + 1

	// Optimize by accessing cells array directly to avoid function call overhead
	for y := 0; y < GRID_HEIGHT; y++ {
		for x := 0; x < GRID_WIDTH; x++ {
			neighbors := ge.countNeighborsOptimized(grid, x, y)
			alive := grid.Cells[y][x]
			newGrid.Cells[y][x] = ge.ApplyRules(alive, neighbors)
		}
	}

	return newGrid
}

// StepInPlace advances the game by one generation using pre-allocated grids to reduce memory allocation.
// The result is stored in the newGrid parameter, and the source grid is preserved.
func (ge *GameEngine) StepInPlace(sourceGrid, newGrid *Grid) {
	newGrid.generation = sourceGrid.generation + 1

	// Optimize by accessing cells array directly to avoid function call overhead
	for y := 0; y < GRID_HEIGHT; y++ {
		for x := 0; x < GRID_WIDTH; x++ {
			neighbors := ge.countNeighborsOptimized(sourceGrid, x, y)
			alive := sourceGrid.Cells[y][x]
			newGrid.Cells[y][x] = ge.ApplyRules(alive, neighbors)
		}
	}
}
