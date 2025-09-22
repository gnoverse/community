package gnov

// Points structure
type Point struct {
	X, Y  float64
	Color string
	Label string
}

// Scatterplot structure
type ScatterPlot struct {
    Points       []Point
    Title        string
    XAxis, YAxis string
    Flag         string
}