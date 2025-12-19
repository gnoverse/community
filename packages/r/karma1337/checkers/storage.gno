package checkers

import "strconv"

var games map[string]*Game
var nextGameID int

func init() {
	games = make(map[string]*Game)
	nextGameID = 0
}

func newGameID() string {
	id := "game_" + strconv.Itoa(nextGameID)
	nextGameID++
	return id
}

func saveGame(g *Game) {
	games[g.ID] = g
}

func mustGetGame(id string) *Game {
	g, ok := games[id]
	if !ok {
		panic("game not found")
	}
	return g
}

// copyGame returns a shallow copy safe for exposure.
func copyGame(g *Game) Game {
	var boardCopy [BoardSize][BoardSize]*Piece
	for r := 0; r < BoardSize; r++ {
		for c := 0; c < BoardSize; c++ {
			if g.Board[r][c] != nil {
				p := *g.Board[r][c]
				boardCopy[r][c] = &p
			}
		}
	}
	historyCopy := make([]MoveRecord, len(g.History))
	copy(historyCopy, g.History)
	return Game{
		ID:      g.ID,
		Red:     g.Red,
		Black:   g.Black,
		Board:   boardCopy,
		Turn:    g.Turn,
		Status:  g.Status,
		Winner:  g.Winner,
		History: historyCopy,
	}
}
