package hitthezone

import (
	"std"
	"time"
)

type GameHistory struct {
	Player       std.Address
	Min          int
	Max          int
	RandomNumber int
	Result       string
	BetAmount    int64
	WinAmount    int64
	Multiplier   float64
	Timestamp    time.Time
}