package hitthezone

import (
	"time"
)

// GameHistory represents a single game record in the Hit The Zone game.
// It contains all information about a player's game including bet, outcome, and timestamp.
type GameHistory struct {
	Player       address
	Min          int
	Max          int
	RandomNumber int
	Result       string
	BetAmount    int64
	WinAmount    int64
	Multiplier   float64
	Timestamp    time.Time
}
