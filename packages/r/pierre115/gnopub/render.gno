package gnopub

import (
	"chain/runtime"
	"strings"

	"gno.land/p/leon/svgbtn"
	"gno.land/p/moul/txlink"
	"gno.land/p/nt/ufmt"
)

func Render(path string) string {
	out := "# GnoPUB 📺\n\n"
	out += "### ADS Grid \n\n"

	// Path handling
	if path == "stats" {
		return out + getStats() + "\n\n[← Retour](/r/gnopub)"
	}

	// Main grid
	out += renderGrid() + "\n\n"

	// Tutorial
	out += "## Tuto 📚\n\n"

	out += "### Step 1: Buy a cell\n\n"
	out += "Click on a white cell in the grid or use the BuyCell function:\n\n"
	out += svgbtn.Button(120, 35, "#4caf50", "#ffffff", "Buy Cell (0,0)", "/r/pierre115/gnopub$help&func=BuyCell&x=0&y=0") + "\n\n"
	out += "Replace x and y with your desired coordinates.\n\n"

	out += "### Step 2: Update your cell\n\n"
	out += "Set the ads URL and label for your cell:\n\n"
	out += svgbtn.Button(120, 35, "#4caf50", "#ffffff", "Update Cell (0,0)", "/r/pierre115/gnopub$help&func=UpdateCell&x=0&y=0&url=https://github.com/gnolang/hackerspace/issues/122&label=test") + "\n\n"
	out += "- `x`, `y`: coordinates of your cell\n"
	out += "- `url`: your advertisement URL (must start with http)\n"
	out += "- `label`: text to display\n\n"

	out += "### Step 3: Change color\n\n"
	out += "Click again on your owned cell to cycle through colors:\n\n"
	out += svgbtn.Button(120, 35, "#4caf50", "#ffffff", "Change Color (0,0)", "/r/pierre115/gnopub$help&func=BuyCell&x=0&y=0") + "\n\n"

	out += "### Step 4: Sell your cell\n\n"
	out += "Release your cell back to the grid:\n\n"
	out += svgbtn.Button(120, 35, "#4caf50", "#ffffff", "Sell Cell (0,0)", "/r/pierre115/gnopub$help&func=SellCell&x=0&y=0") + "\n\n"

	// Utility buttons
	out += "---\n\n"
	out += "## Admin Pannel 🛠️\n\n"
	out += svgbtn.DangerButton(100, 30, "Reset", "/r/gnopub$help&func=reset") + "\n\n"

	// Stats
	out += getStats()

	return out
}

// Render the grid
func renderGrid() string {
	out := ""

	// Grid cells
	for y := 0; y < grid.Height; y++ {
		for x := 0; x < grid.Width; x++ {
			key := ufmt.Sprintf("%d,%d", x, y)
			color := defaultcolor
			link := defaultlink
			// If the cell is owned, use its color
			if cell, ok := grid.Cells[key]; ok {
				color = cell.Color
				caller := runtime.PreviousRealm().Address()

				if cell.Url != "" {
					link = cell.Url
				}

				// If the cell is owned by someone else, link to their pub if set
				if cell.Owner != "" && cell.Owner != caller {
					out += svgbtn.Button(cellSize, cellSize, color, "#333333", cell.Label, link)
					out += strings.Repeat("&nbsp;", spacingCount)
					continue
				}
			}
			link = txlink.NewLink("BuyCell").
				AddArgs("x", ufmt.Sprintf("%d", x), "y", ufmt.Sprintf("%d", y)).
				URL()
			out += svgbtn.Button(cellSize, cellSize, color, "#333333", "available", link)
			out += strings.Repeat("&nbsp;", spacingCount)
		}
		out += "\n\n"
	}

	return out
}

// Stats of the grid (per cells owners)
func getStats() string {
	stats := make(map[address]int)
	for _, cell := range grid.Cells {
		if cell.Owner != "" {
			stats[cell.Owner]++
		}
	}

	out := "## Stats 📊:\n"
	if len(stats) == 0 {
		out += "No cells used.\n"
		return out
	}

	for owner, count := range stats {
		out += ufmt.Sprintf("- %s: %d cell(s)\n", owner.String(), count)
	}
	return out
}
