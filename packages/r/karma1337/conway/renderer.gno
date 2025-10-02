package conway

import (
	"strconv"
	"strings"
)

// Renderer handles the display of the game state.
type Renderer struct{}

// NewRenderer creates a new renderer instance.
func NewRenderer() *Renderer {
	return &Renderer{}
}

// RenderGrid converts the grid state to a visual string representation.
func (r *Renderer) RenderGrid(grid *Grid) string {
	var output strings.Builder

	output.WriteString("\n```\n") // Start code block for proper monospace rendering

	// Grid header with column letters (A-T for 20 columns)
	output.WriteString("   ")
	for x := 0; x < GRID_WIDTH; x++ {
		letter := string(rune('A' + x)) // Convert to A, B, C, D...
		output.WriteString(letter + " ")
	}
	output.WriteString("\n")

	// Grid content
	for y := 0; y < GRID_HEIGHT; y++ {
		// Row number with proper spacing
		if y < 10 {
			output.WriteString(" " + strconv.Itoa(y) + " ")
		} else {
			output.WriteString(strconv.Itoa(y) + " ")
		}

		// Cells with spaces between them
		for x := 0; x < GRID_WIDTH; x++ {
			if grid.GetCell(x, y) {
				output.WriteString("● ") // Alive cell with space
			} else {
				output.WriteString(". ") // Dead cell with space
			}
		}
		output.WriteString("\n")
	}

	output.WriteString("```\n") // End code block

	return output.String()
}

// RenderHelp generates the help/action text including available commands and patterns.
func (r *Renderer) RenderHelp(patternManager *PatternManager) string {
	var output strings.Builder

	output.WriteString("Actions:\n")
	output.WriteString("* [Step](conway$help&func=Step) - Advance one generation (optimized for lower gas usage)\n")
	output.WriteString("* [SetCell](conway$help&func=SetCell) x y alive - Set cell state using numbers (alive: true/false)\n")
	output.WriteString("* [SetCellAt](conway$help&func=SetCellAt) coordinate alive - Set cell using letter coordinates (e.g., F5)\n")
	output.WriteString("* [GetCellAt](conway$help&func=GetCellAt) coordinate - Get cell state using letter coordinates\n")
	output.WriteString("* [LoadPattern](conway$help&func=LoadPattern) pattern x y - Load pattern using numeric coordinates\n")
	output.WriteString("* [LoadPatternAt](conway$help&func=LoadPatternAt) pattern coordinate - Load pattern using letter coordinates\n")
	output.WriteString("* [Clear](conway$help&func=Clear) - Clear the grid\n\n")

	output.WriteString("Example commands (use --broadcast for single-step execution):\n")
	output.WriteString("```\n")
	output.WriteString("# Clear the grid\n")
	output.WriteString("gnokey maketx call -pkgpath \"gno.land/r/karma1337/conway\" -func \"Clear\" -gas-fee 1000000ugnot -gas-wanted 5000000 -send \"\" --broadcast ADDRESS\n\n")
	output.WriteString("# Set cell at F5 to alive (using letter coordinates)\n")
	output.WriteString("gnokey maketx call -pkgpath \"gno.land/r/karma1337/conway\" -func \"SetCellAt\" -args \"F5\" -args \"true\" -gas-fee 1000000ugnot -gas-wanted 5000000 -send \"\" --broadcast ADDRESS\n\n")
	output.WriteString("# Load blinker pattern at F5 (using letter coordinates)\n")
	output.WriteString("gnokey maketx call -pkgpath \"gno.land/r/karma1337/conway\" -func \"LoadPatternAt\" -args \"blinker\" -args \"F5\" -gas-fee 1000000ugnot -gas-wanted 5000000 -send \"\" --broadcast ADDRESS\n\n")
	output.WriteString("# Set cell at (5,5) to alive (using numeric coordinates)\n")
	output.WriteString("gnokey maketx call -pkgpath \"gno.land/r/karma1337/conway\" -func \"SetCell\" -args \"5\" -args \"5\" -args \"true\" -gas-fee 1000000ugnot -gas-wanted 5000000 -send \"\" --broadcast ADDRESS\n")
	output.WriteString("```\n\n")

	// List available patterns
	patterns := patternManager.GetAvailablePatterns()
	output.WriteString("Available patterns: ")
	for i, pattern := range patterns {
		if i > 0 {
			output.WriteString(", ")
		}
		output.WriteString(pattern)
	}
	output.WriteString("\n\n")

	return output.String()
}
