package gnopub

import (
	"chain/runtime"

	"gno.land/p/nt/ownable"
	"gno.land/p/nt/ufmt"
)

var (
	OwnableAddress = ownable.NewWithAddress("g1e7r5eglptfejknps3xv2kxv6pc8wvd3wwtw6tg")

	colors = []string{"#ffffff", "#f44336", "#2196f3", "#4caf50", "#ff9800"} // blanc, rouge, bleu, vert, orange

	spacingCount = 23

	defaultlink = ufmt.Sprintf("/r/leon/hor:hall")

	grid Grid
)

const (
	cellSize     = 100
	defaultcolor = "#ffffff"
)

// Cell structure init
func init() {
	grid = Grid{
		Width:  5,
		Height: 5,
		Cells:  make(map[string]Cell),
	}
}

// Function to validate the coordinates
func getCoordinate(x, y int) string {
	if x < 0 || x >= grid.Width || y < 0 || y >= grid.Height {
		return ufmt.Sprintf("Invalid coordinate : X=%d, Y=%d", x, y)
	}
	return ""
}

// Function to sell a cell
func SellCell(_ realm, x, y int) string {
	if err := getCoordinate(x, y); err != "" {
		return err
	}

	key := ufmt.Sprintf("%d,%d", x, y)
	caller := runtime.PreviousRealm().Address()
	cell, exists := grid.Cells[key]

	if exists && cell.Owner == caller {
		grid.Cells[key] = Cell{
			X:     x,
			Y:     y,
			Color: "",
			Owner: "",
			Url:   "",
			Label: "",
		}
		return ufmt.Sprintf("The cell was successfully sold.", x, y)
	}

	return "You are not the owner of this cell."
}

// Function to update the Ads and the Label of yours cells
func UpdateCell(_ realm, x, y int, url, label string) string {
	if err := getCoordinate(x, y); err != "" {
		return err
	}

	key := ufmt.Sprintf("%d,%d", x, y)
	caller := runtime.PreviousRealm().Address()
	cell, exists := grid.Cells[key]

	if exists && cell.Owner == caller {
		grid.Cells[key] = Cell{
			X:     x,
			Y:     y,
			Color: cell.Color,
			Owner: cell.Owner,
			Url:   url,
			Label: label,
		}
		return ufmt.Sprintf("The cell Url was successfully Updated!")
	}

	return "You are not the owner of this cell."
}

// Cell clicked function if the cells is not owned
func BuyCell(_ realm, x, y int) string {
	if err := getCoordinate(x, y); err != "" {
		return err
	}

	key := ufmt.Sprintf("%d,%d", x, y)
	caller := runtime.PreviousRealm().Address()

	// If the cells is not owned, buy it
	cell, exists := grid.Cells[key]
	if !exists || cell.Owner == "" {
		grid.Cells[key] = Cell{
			X:     x,
			Y:     y,
			Color: colors[1], // red at first
			Owner: caller,
			Url:   "",
			Label: "",
		}
		return ufmt.Sprintf("The cell was successfully (%d,%d) purchased!", x, y)
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
		return ufmt.Sprintf("The cells (%d,%d) was updated! New color: %s", x, y, getColorName(cell.Color))
	}

	return "This cell is owned."
}

// Reset grid (admin only)
func Reset() string {
	if !isAuthorized(runtime.PreviousRealm().Address()) {
		panic("unauthorized")
	}
	grid.Cells = make(map[string]Cell)
	return "The grid was successfully reset."
}

func isAuthorized(addr address) bool {
	return addr == OwnableAddress.Owner()
}
