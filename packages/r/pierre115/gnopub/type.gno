package gnopub

import (
	"std"
)

// Cells
type Cell struct {
	X     int
	Y     int
	Color string
	Owner std.Address
	url  string
}

// Global Grid
var grid = struct {
	Width  int
	Height int
	Cells  map[string]Cell
}{
	Width:  5, // init params
	Height: 3,
	Cells:  make(map[string]Cell),
}