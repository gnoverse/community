package gnopub

import (
	"std"

	"gno.land/p/demo/svg"
	"gno.land/p/nt/ufmt"
	"gno.land/p/nt/ownable"
)

var (
	OwnableAddress = ownable.NewWithAddress("g1e7r5eglptfejknps3xv2kxv6pc8wvd3wwtw6tg")

	colors = []string{"#ffffff", "#f44336", "#2196f3", "#4caf50", "#ff9800"} // blanc, rouge, bleu, vert, orange

	espace = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
)

// voir diff avec leon/svgbtn.gno
func myButton(width, height int, btnColor, textColor, text, link string) string {
	canvas := svg.NewCanvas(width, height).
		WithViewBox(0, 0, width, height).
		AddStyle("text", "font-family:sans-serif;font-size:14px;text-anchor:middle;dominant-baseline:middle;")

	bg := svg.NewRectangle(0, 0, width, height, btnColor)
	bg.RX = height / 5
	bg.RY = height / 5
	label := svg.NewText(width/2, height/2, text, textColor)
	canvas.Append(bg, label)

	return ufmt.Sprintf("[%s](%s)", canvas.Render(text), link)
}

// Render the grid
func RenderGrid() string {
	const cellSize = 100

	out := ""

	// Grid cells
	for y := 0; y < grid.Height; y++ {
		for x := 0; x < grid.Width; x++ {
			key := ufmt.Sprintf("%d,%d", x, y)
			color := "#ffffff"
			// If the cell is owned, use its color
			if cell, ok := grid.Cells[key]; ok {
				color = cell.Color
				caller := std.PreviousRealm().Address()

				// If the cell is owned by someone else, link to their pub if set
				if cell.Owner != "" && cell.Owner != caller {
					if cell.Url != "" {
						out += myButton(cellSize, cellSize, color, "#333333", cell.Label, cell.Url)
						out += espace
						continue
					} else {
						link := ufmt.Sprintf("https://gno.land/r/leon/hor:hall")
						out += myButton(cellSize, cellSize, color, "#333333", cell.Label, link)
						out += espace
						continue
					}

				}
			}
			// si on remonte d'une accolade ca marche plus :(
			link := ufmt.Sprintf("/r/gnopixel$help&func=BuyCells&x=%d&y=%d", x, y)
			out += myButton(cellSize, cellSize, color, "#333333", "available", link)
			out += espace
		}
		out += "\n\n"
	}

	return out
}

// Function to sell a cell
func SellCells(_ realm, x, y int) string {
	if x < 0 || x >= grid.Width || y < 0 || y >= grid.Height {
		return ufmt.Sprintf("XY not valid : X=%d, Y=%d", x, y)
	}

	key := ufmt.Sprintf("%d,%d", x, y)
	caller := std.PreviousRealm().Address()
	cell, exists := grid.Cells[key]

	if  exists && cell.Owner == caller {
		grid.Cells[key] = Cell{
			X:     x,
			Y:     y,
			Color: "",
			Owner: "",
			Url: "",
			Label: "",
		}
		return ufmt.Sprintf("Cells selled!", x, y)
	}

	return "You are not the owner of this cell."
}

// Function to update the Pub and the Label of yours cells
func UpdateCells(_ realm, x, y int, url, label string) string {
	if x < 0 || x >= grid.Width || y < 0 || y >= grid.Height {
		return ufmt.Sprintf("XY not valid : X=%d, Y=%d", x, y)
	}

	key := ufmt.Sprintf("%d,%d", x, y)
	caller := std.PreviousRealm().Address()
	cell, exists := grid.Cells[key]

	if  exists && cell.Owner == caller {
		grid.Cells[key] = Cell{
			X:     x,
			Y:     y,
			Color: cell.Color,
			Owner: cell.Owner,
			Url: url,
			Label: label,
		}
		return ufmt.Sprintf("Pub Updated!")
	}

	return "You are not the owner of this cell."
}



// Cell clicked function if the cells is not owned
func BuyCells(_ realm, x, y int) string {
	if x < 0 || x >= grid.Width || y < 0 || y >= grid.Height {
		return ufmt.Sprintf("Coordonnées invalides : X=%d, Y=%d", x, y)
	}

	key := ufmt.Sprintf("%d,%d", x, y)
	caller := std.PreviousRealm().Address()

	// If the cells is not owned, buy it
	cell, exists := grid.Cells[key]
	if !exists || cell.Owner == "" {
		grid.Cells[key] = Cell{
			X:     x,
			Y:     y,
			Color: colors[1], // red at first
			Owner: caller,
			Url: "",
			Label: "",
		}
		return ufmt.Sprintf("Cell (%d,%d) purchased!", x, y)
	}

	// if it is the person who own it, change the color
	if cell.Owner == caller {
		currentColorIndex := 0
		for i, c := range colors {
			if c == cell.Color {
				currentColorIndex = i
				break
			}
		}
		nextColorIndex := (currentColorIndex + 1) % len(colors)
		cell.Color = colors[nextColorIndex]
		grid.Cells[key] = cell
		return ufmt.Sprintf("Cells (%d,%d) updated! Color: %s", x, y, getColorName(cell.Color))
	}

	return "This Cells is owned."
}

// Reset grid (admin)
func reset() string {
	if !isAuthorized(std.PreviousRealm().Address()) {
		panic("unauthorized")
	}
	grid.Cells = make(map[string]Cell)
	return "Grille réinitialisée!"
}

// Stats of the grid (per cells owners)
func getStats() string {
	stats := make(map[std.Address]int)
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

func getColorName(color string) string {
	switch color {
	case "#f44336":
		return "Red"
	case "#2196f3":
		return "Blue"
	case "#4caf50":
		return "Green"
	case "#ff9800":
		return "Orange"
	default:
		return "White"
	}
}

func isAuthorized(addr std.Address) bool {
	return addr == OwnableAddress.Owner()
}
