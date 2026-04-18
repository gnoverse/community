package gnopub

// Cell structure
type Cell struct {
	X     int
	Y     int
	Color string  // Colors of the cells if owned
	Owner address // Address of the owner
	Url   string  // Url of the ads
	Label string  // Pseudo of the owner / name of the ads
}

// Global grid variable
type Grid struct {
	Width  int
	Height int
	Cells  map[string]Cell
}
