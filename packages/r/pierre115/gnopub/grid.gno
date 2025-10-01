package gnopub

import (
	"std"
	"strings"

	"gno.land/p/demo/svg"
	"gno.land/p/nt/ufmt"
	"gno.land/p/nt/ownable"
)

var (
	OwnableAddress = ownable.NewWithAddress("g1e7r5eglptfejknps3xv2kxv6pc8wvd3wwtw6tg")

	tablePub = make(map[std.Address]string)

	colors = []string{"#ffffff", "#f44336", "#2196f3", "#4caf50", "#ff9800"} // blanc, rouge, bleu, vert, orange

	espace = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
)

func MyButton(width, height int, btnColor, textColor, text, link string) string {
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


// Génère la grille SVG simple
func RenderGrid() string {
	const cellSize = 100
	
	out := ""
	
	// Grille de boutons serrés
	for y := 0; y < grid.Height; y++ {
		for x := 0; x < grid.Width; x++ {
			key := ufmt.Sprintf("%d,%d", x, y)
			color := "#ffffff"

			if cell, ok := grid.Cells[key]; ok && cell.Color != "" {
				color = cell.Color
				caller := std.PreviousRealm().Address()

				// Si la cellule appartient déjà à quelqu'un
				if cell.Owner != "" && cell.Owner != caller {
					// Rediriger vers la pub si elle existe
					if cell.url != "" {
						//ajouter pseudo sur le bouton
						out += MyButton(cellSize, cellSize, color, "#333333", "", cell.url)
						out += espace
						continue
					} else {
						link := ufmt.Sprintf("https://i.imgflip.com/a6o5jb.jpg")
						out += MyButton(cellSize, cellSize, color, "#333333", "", link)
						out += espace
						continue
					}

				}
			}

			link := ufmt.Sprintf("/r/gnopixel$help&func=Clicked&x=%d&y=%d", x, y)
			
			// Bouton avec juste la couleur, pas de texte
			out += MyButton(cellSize, cellSize, color, "#333333", "", link)
			out += espace
		}
		out += "\n\n"
	}

	return out
}

// Fonction publique pour gérer les clics
func Clicked(_ realm, x, y int) string {
	if x < 0 || x >= grid.Width || y < 0 || y >= grid.Height {
		return ufmt.Sprintf("Coordonnées invalides : X=%d, Y=%d", x, y)
	}
	
	key := ufmt.Sprintf("%d,%d", x, y)
	caller := std.PreviousRealm().Address()
	
	// Si la cellule n'existe pas encore, créer et attribuer
	cell, exists := grid.Cells[key]
	if !exists || cell.Owner == "" {
		grid.Cells[key] = Cell{
			X:     x,
			Y:     y,
			Color: colors[1], // Rouge par défaut
			Owner: caller,
		}
		return ufmt.Sprintf("Cellule (%d,%d) achetée!", x, y)
	}

	// Si c'est le propriétaire, changer la couleur
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

	return ufmt.Sprintf("Cellule (%d,%d) mise à jour! Couleur: %s", x, y, getColorName(cell.Color))
}

// Fonction pour définir la pub et la couleur
func SetPub(url string) string {
	if url == "" || !strings.HasPrefix(url, "http") {
		return "URL invalide (doit commencer par http)"
	}
	caller := std.PreviousRealm().Address()
	tablePub[caller] = url

	// Mettre à jour toutes les cellules du propriétaire

	return ufmt.Sprintf("Pub set")
}

// Reset de la grille (admin uniquement)
func Reset() string {
	if !IsAuthorized(std.PreviousRealm().Address()) {
		panic("unauthorized")
	}
	grid.Cells = make(map[string]Cell)
	return "Grille réinitialisée!"
}

// Stats de la grille
func GetStats() string {
	stats := make(map[std.Address]int)
	for _, cell := range grid.Cells {
		if cell.Owner != "" {
			stats[cell.Owner]++
		}
	}

	out := "### Stats:\n"
	if len(stats) == 0 {
		out += "Aucune cellule n'a été achetée.\n"
		return out
	}

	for owner, count := range stats {
		out += ufmt.Sprintf("- %s: %d cellule(s)\n", owner.String(), count)
	}
	return out
}

func getColorName(color string) string {
	switch color {
	case "#f44336":
		return "Rouge"
	case "#2196f3":
		return "Bleu"
	case "#4caf50":
		return "Vert"
	case "#ff9800":
		return "Orange"
	default:
		return "Blanc"
	}
}

func IsAuthorized(addr std.Address) bool {
	return addr == OwnableAddress.Owner()
}
