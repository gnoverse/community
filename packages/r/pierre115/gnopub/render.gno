package gnopub

import (
	"gno.land/p/leon/svgbtn"
)

func Render(path string) string {
	out := "# GnoPUB\n\n"
	out += "### Pub Grid:\n\n"

	// Path handling
	if path == "stats" {
		return out + GetStats() + "\n\n[← Retour](/r/gnopixel)"
	}

	// Main grid
	out += RenderGrid() + "\n\n"

	out += "### Tuto:\n\n"

	out += "You need to set a pub before buy a cells \n\n"



	// Utility buttons
	out += "---\n\n"
	out += svgbtn.DangerButton(100, 30, "Reset", "/r/gnopixel$help&func=Reset") + " "
	out += svgbtn.SuccessButton(100, 30, "Stats", "/r/gnopixel:stats") + "\n\n"

	out += GetStats()

	return out
}
