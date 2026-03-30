package checkers

import (
	"net/url"
	"strings"

	"chain/runtime"
)

// parsePath normalizes the path and extracts query parameters
func parsePath(path string) (string, map[string]string) {
	// gnoweb passes path after the colon, e.g. "?game=game_0" or "/game/game_0"
	// or just "" for the root

	queryParams := make(map[string]string)

	// Handle query string (starts with ? or contains ?)
	if strings.HasPrefix(path, "?") {
		// Path is just query params like "?game=game_0"
		query, err := url.ParseQuery(path[1:])
		if err == nil {
			for k, v := range query {
				if len(v) > 0 {
					queryParams[k] = v[0]
				}
			}
		}
		return "/", queryParams
	}

	// Handle path with query string
	if strings.Contains(path, "?") {
		parts := strings.SplitN(path, "?", 2)
		path = parts[0]
		if len(parts) > 1 {
			query, err := url.ParseQuery(parts[1])
			if err == nil {
				for k, v := range query {
					if len(v) > 0 {
						queryParams[k] = v[0]
					}
				}
			}
		}
	}

	// Normalize path
	if path == "" {
		path = "/"
	}

	return path, queryParams
}

// getCallerAddress safely gets the caller address, returns empty string if unavailable
func getCallerAddress() string {
	defer func() {
		recover()
	}()
	return runtime.PreviousRealm().Address().String()
}

// isPlayerTurn checks if it's the caller's turn in the game
func isPlayerTurn(g *Game, callerAddr string) bool {
	if callerAddr == "" {
		return false
	}
	if g.Status != StatusActive {
		return false
	}
	if g.Turn == RED && g.Red == callerAddr {
		return true
	}
	if g.Turn == BLACK && g.Black == callerAddr {
		return true
	}
	return false
}
