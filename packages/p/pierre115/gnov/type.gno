package gnov

// Points structure
type Point struct {
	X, Y  float64 //Coordinate of the point
	Color string // Color of the point
	Label string // Associate a label to the point
}

// Scatterplot structure
type ScatterPlot struct {
    Points       []Point // Points structure (points clouds)
    Title        string  // Title of the scatter plot
    XAxis, YAxis string  // Title of X and Y axis
    FlagRe         bool  // Optional flag for regression "re"
    maxTicks       int   // Optional max ticks for axis (default 10)
    Width, Height int   // Optional width and height of the svg (default 750x600)
}
