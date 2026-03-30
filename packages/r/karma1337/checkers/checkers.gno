package checkers

import (
	"strings"

	"chain/runtime"
)

// CreateGame starts a new game where the caller plays RED and the provided
// address plays BLACK. Returns the game id (e.g. "game_0").
//
// Usage: CreateGame("g1opponentaddress...")
// You can use your own address to play both sides for testing.
func CreateGame(_ realm, black string) string {
	if black == "" {
		panic("opponent address is required")
	}

	black = strings.TrimSpace(black)
	if black == "" {
		panic("opponent address cannot be empty")
	}

	caller := runtime.PreviousRealm().Address().String()

	id := newGameID()
	g := &Game{
		ID:     id,
		Red:    caller,
		Black:  black,
		Board:  initialBoard(),
		Turn:   RED,
		Status: StatusActive,
	}
	saveGame(g)
	return id
}

// Move performs a single piece move. Coordinates are 0-based.
func Move(_ realm, gameID string, fromRow, fromCol, toRow, toCol int) MoveRecord {
	g := mustGetGame(gameID)
	record := applyMove(g, fromRow, fromCol, toRow, toCol, runtime.PreviousRealm().Address().String())
	return record
}

// GetGameInfo returns a copy of the game.
func GetGameInfo(gameID string) Game {
	g := mustGetGame(gameID)
	return copyGame(g)
}

// GetMoveHistory returns the recorded move history.
func GetMoveHistory(gameID string) []MoveRecord {
	g := mustGetGame(gameID)
	history := make([]MoveRecord, len(g.History))
	copy(history, g.History)
	return history
}

// ListGames returns the ids of all games.
func ListGames() []string {
	out := make([]string, 0, len(games))
	for id := range games {
		out = append(out, id)
	}
	return out
}

// GamesByAddress returns games where the address participates.
func GamesByAddress(addr string) []string {
	out := []string{}
	for id, g := range games {
		if g.Red == addr || g.Black == addr {
			out = append(out, id)
		}
	}
	return out
}

// Render implements gnoweb entry point.
func Render(path string) string {
	normalizedPath, queryParams := parsePath(path)
	callerAddr := getCallerAddress()

	// Check query params FIRST (they take precedence)
	if gameID := queryParams["game"]; gameID != "" {
		// View specific game
		g, ok := games[gameID]
		if !ok {
			return "# Game Not Found\n\nThe game `" + gameID + "` does not exist.\n\n[← Back to Home](?)\n"
		}
		return renderGame(g, queryParams, callerAddr)
	}

	if queryParams["list"] != "" {
		// List all games
		var output strings.Builder
		output.WriteString("# All Games\n\n")
		output.WriteString(renderList())
		return output.String()
	}

	if queryParams["mygames"] != "" {
		// User's games
		var output strings.Builder
		output.WriteString(renderMyGames(callerAddr))
		output.WriteString("\n\n")
		output.WriteString("[← Back to Home](?)\n")
		return output.String()
	}

	// Then check path-based routes
	switch normalizedPath {
	case "", "/":
		// Home page
		return renderHome(callerAddr)

	case "/list", "/games":
		// List all games
		var output strings.Builder
		output.WriteString("# All Games\n\n")
		output.WriteString(renderList())
		return output.String()

	case "/mygames":
		// User's games
		var output strings.Builder
		output.WriteString(renderMyGames(callerAddr))
		output.WriteString("\n\n")
		output.WriteString("[← Back to Home](?)\n")
		return output.String()

	default:
		return "# Page Not Found\n\nThe requested page does not exist.\n\n[← Back to Home](?)\n"
	}
}
