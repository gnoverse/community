package checkers

const (
	BoardSize = 8
)

// Color represents which side owns a piece.
type Color string

const (
	RED   Color = "RED"
	BLACK Color = "BLACK"
)

// Status represents lifecycle of a game.
type Status string

const (
	StatusActive   Status = "ACTIVE"
	StatusRedWon   Status = "RED_WON"
	StatusBlackWon Status = "BLACK_WON"
	StatusDraw     Status = "DRAW"
)

type Piece struct {
	Color Color
	King  bool
}

type Coord struct {
	Row int
	Col int
}

type MoveRecord struct {
	From         Coord
	To           Coord
	Captured     []Coord
	Player       Color
	KingPromoted bool
	MoveIndex    int
}

type Game struct {
	ID      string
	Red     string
	Black   string
	Board   [BoardSize][BoardSize]*Piece
	Turn    Color
	Status  Status
	Winner  Color
	History []MoveRecord
}
