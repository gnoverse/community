package gnopub

import (
	"gno.land/p/leon/svgbtn"
)

func Render(path string) string {
	out := "# GnoPUB 📺\n\n"
	out += "### Pub Grid 🔲:\n\n"

	// Path handling
	if path == "stats" {
		return out + getStats() + "\n\n[← Retour](/r/gnopixel)"
	}

	// Main grid
	out += RenderGrid() + "\n\n"

	// tutorial
	out += "## Tuto 📚:\n\n"
	out += "### Step 1 :\n\n"
	out += "Buy a cell with the function `BuyCells`.\n\n"
	out += "### Step 2 :\n\n"
	out += "Set the pub and the label with the function `UpdateCells` on yours cells.\n\n"
	out += "### Step 3 :\n\n"
	out += "Sell your cells with the function `SellCells`.\n\n"

	// Utility buttons
	out += "---\n\n"
	out += "## Admin Pannel 🛠️:\n\n"
	out += svgbtn.DangerButton(100, 30, "Reset", "/r/gnopixel$help&func=reset") + "\n\n"
	//out += svgbtn.SuccessButton(100, 30, "Stats", "/r/gnopixel:Stats") + "\n\n"

	// Stats
	out += getStats()

	return out
}
