package gnov

import (
	"math"

	"gno.land/p/nt/ufmt"
)

// Function to get slope and intercept with linear way
func LinearRegression(points []Point) (slope, intercept float64) {
	n := float64(len(points))
	sumX := float64(0)
	sumY := float64(0)
	sumXY := float64(0)
	sumX2 := float64(0)

	for _, p := range points {
		sumX += p.X
		sumY += p.Y
		sumXY += p.X * p.Y
		sumX2 += p.X * p.X
	}

	slope = (n*sumXY - sumX*sumY) / (n*sumX2 - sumX*sumX)
	intercept = (sumY - slope*sumX) / n
	return
}

// Function to draw the regression line and return as SVG string
func RenderReFlag(points []Point, minX, maxX, minY, maxY float64, canvasWidth, canvasHeight int) string {
	slope, intercept := LinearRegression(points)

	xStart := minX
	xEnd := maxX
	yStart := slope*xStart + intercept
	yEnd := slope*xEnd + intercept

	// Normalize with the canvas data
	nx1 := 40 + (xStart-minX)/(maxX-minX)*float64(canvasWidth-60)
	ny1 := float64(canvasHeight-40) - (yStart-minY)/(maxY-minY)*float64(canvasHeight-60)
	nx2 := 40 + (xEnd-minX)/(maxX-minX)*float64(canvasWidth-60)
	ny2 := float64(canvasHeight-40) - (yEnd-minY)/(maxY-minY)*float64(canvasHeight-60)

	dx := nx2 - nx1
	dy := ny2 - ny1
	angleRad := math.Atan2(dy, dx)
	angleDeg := angleRad * 180 / math.Pi

	svgOut := ""

	// SVG Rectangle as regression line
	svgOut += ufmt.Sprintf(
		`<rect x="%d" y="%d" width="%d" height="1" fill="black" transform="rotate(%.2f %d %d)"/>`,
		int(nx1), int(ny1),
		int(math.Hypot(nx2-nx1, ny2-ny1)),
		angleDeg, int(nx1), int(ny1),
	)

	// Equation of the line
	equation := ufmt.Sprintf("y = %.2fx + %.2f", slope, intercept)
	svgOut += ufmt.Sprintf(
		`<text x="50" y="20" style="font-size:12px;font-family:'Inter var',sans-serif;" fill="black">Equation : %s</text>`,
		equation,
	)

	return svgOut
}
