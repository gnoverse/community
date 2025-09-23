// Package gnov provides functionality to render a scatter plot as an SVG image.
// It takes a list of points (x,y) and draws them as circles on a 2D .
// You can also apply Flags.
package gnov

import (
	"math"

	"gno.land/p/nt/ufmt"
)

func niceStep(rangeVal float64, maxTicks int) float64 {
    var niceBase float64
    rawStep := rangeVal / float64(maxTicks)
    exponent := math.Floor(math.Log10(rawStep))
    fraction := rawStep / math.Pow(10, exponent)

    switch {
    case fraction < 1.5:
        niceBase = 1
    case fraction < 3:
        niceBase = 2
    case fraction < 7:
        niceBase = 5
    default:
        niceBase = 10
    }

    return niceBase * math.Pow(10, exponent)
}

// Use the ideal steps for X and Y axis
func StepXY(maxX, maxY, minX, minY float64) (float64 ,float64, float64, float64, float64, float64) {

	rangeX := maxX - minX
    stepX := niceStep(rangeX, 10)
    startX := math.Floor(minX/stepX) * stepX
    endX := math.Ceil(maxX/stepX) * stepX
    rangeY := maxY - minY
    stepY := niceStep(rangeY, 10)
    startY := math.Floor(minY/stepY) * stepY
    endY := math.Ceil(maxY/stepY) * stepY

	return stepX, startX, endX, stepY, startY, endY
}

// Draw axes and axes titles, return SVG strings
func RenderAxes(X_axe string, Y_axe string, Width, Height int, maxX, maxY, minX, minY float64) string {
    svgOut := ""

	// Axe Y
    svgOut += ufmt.Sprintf(`<rect x="%d" y="%d" width="%d" height="%d" fill="black"/>`, 40, Height-40, Width-60, 1)
    svgOut += ufmt.Sprintf(
        `<text x="%d" y="%d" style="font-family:'Inter var',sans-serif;font-size:%dpx;text-anchor:middle;" transform="rotate(-90 %d %d)" fill="black">%s</text>`,
        10, Height/2, 12, 15, Height/2, Y_axe,
    )

	// Axe X
    svgOut += ufmt.Sprintf(`<rect x="%d" y="%d" width="%d" height="%d" fill="black"/>`, 40, 20, 1, Height-60)
    svgOut += ufmt.Sprintf(
        `<text x="%d" y="%d" style="font-family:'Inter var',sans-serif;font-size:%dpx;text-anchor:middle;" fill="black">%s</text>`,
        Width/2, Height-10, 12, X_axe,
    )

    // Scale helpers
    scaleX := func(val float64) float64 {
        return 40 + (val-minX)/(maxX-minX)*float64(Width-60)
    }
    scaleY := func(val float64) float64 {
        return float64(Height-40) - (val-minY)/(maxY-minY)*float64(Height-60)
    }

    // Nicesteps calcul for graduation
    stepX, startX, endX, stepY, startY, endY := StepXY(maxX, maxY, minX, minY)

    // Graduation X
    for val := startX; val <= endX; val += stepX {
        nx := scaleX(val)
        y := float64(Height - 40)
        svgOut += ufmt.Sprintf(`<rect x="%d" y="%d" width="%d" height="%d" fill="black"/>`, int(nx), int(y), 1, 5)
        svgOut += ufmt.Sprintf(`<text x="%d" y="%d" style="font-size:%dpx;text-anchor:middle;" fill="black">%.1f</text>`, int(nx), int(y)+18, 11, val)
    }

    // Graduation Y
    for val := startY; val <= endY; val += stepY {
        ny := scaleY(val)
        x := float64(40)
        svgOut += ufmt.Sprintf(`<rect x="%d" y="%d" width="%d" height="%d" fill="black"/>`, int(x)-5, int(ny), 5, 1)
        svgOut += ufmt.Sprintf(`<text x="%d" y="%d" style="font-size:%dpx;text-anchor:end;" fill="black">%.1f</text>`, int(x)-8, int(ny)+4, 11, val)
    }

    return svgOut
}

// Returns an img svg markup as a string, including a markdown header if a non-empty title is provided.
// The function need a Point struct, two axes titles and a flag.
// You can see existings flags in the Readme.md
func (sp ScatterPlot) String() string {

	const (
        Width  = 750
        Height = 600
        pointRadius  = 2
    )

    if len(sp.Points) == 0 {
        return "\nscatterplot fails: no data provided"
    }

    // calcul min/max
    minX, minY := sp.Points[0].X, sp.Points[0].Y
    maxX, maxY := sp.Points[0].X, sp.Points[0].Y

    for _, p := range sp.Points {
        if p.X > maxX { maxX = p.X }
        if p.X < minX { minX = p.X }
        if p.Y > maxY { maxY = p.Y }
        if p.Y < minY { minY = p.Y }
    }

    svgOut := ""
    svgOut += RenderAxes(sp.XAxis, sp.YAxis, Width, Height, maxX, maxY, minX, minY)

    // Draw Points and labels
    for _, p := range sp.Points {
        nx := 40 + (p.X-minX)/(maxX-minX)*float64(Width-60)
        ny := float64(Height-40) - (p.Y-minY)/(maxY-minY)*float64(Height-60)

        svgOut += ufmt.Sprintf(`<circle cx="%d" cy="%d" r="%d" fill="%s"/>`, int(nx), int(ny), pointRadius, p.Color)

        if p.Label != "" {
            svgOut += ufmt.Sprintf(
                `<text x="%d" y="%d" style="font-family:'Inter var',sans-serif;font-size:10px;text-anchor:middle;" fill="#333">%s</text>`,
                int(nx)+5, int(ny)+12, p.Label,
            )
        }
    }

    // Flags :
    if sp.Flag == "re" {
        svgOut += RenderReFlag(sp.Points, minX, maxX, minY, maxY, Width, Height)
    }

    // Draw Title
	if sp.Title != "" {
    	svgOut += ufmt.Sprintf(`<text x="%d" y="%d" style="font-family:'Inter var',sans-serif;font-size:16px;text-anchor:middle;" fill="black">%s</text>`,
        	Width/2, 20, sp.Title,
		)
	}

    return svgOut
}
