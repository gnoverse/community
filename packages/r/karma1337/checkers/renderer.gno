package checkers

import (
	"bytes"
	"strconv"
	"strings"
)

// renderBoard renders a static ASCII board (used for finished games).
func renderBoard(board [BoardSize][BoardSize]*Piece) string {
	var buf bytes.Buffer
	buf.WriteString("\n```\n")
	buf.WriteString("   a b c d e f g h\n")
	for r := 0; r < BoardSize; r++ {
		buf.WriteString(strconv.Itoa(r) + " ")
		for c := 0; c < BoardSize; c++ {
			buf.WriteByte(' ')
			if (r+c)%2 == 0 {
				buf.WriteByte('.')
				continue
			}
			p := board[r][c]
			if p == nil {
				buf.WriteByte('.')
				continue
			}
			if p.Color == RED {
				if p.King {
					buf.WriteRune('♛')
				} else {
					buf.WriteRune('●')
				}
			} else {
				if p.King {
					buf.WriteRune('♕')
				} else {
					buf.WriteRune('○')
				}
			}
		}
		buf.WriteByte('\n')
	}
	buf.WriteString("```\n")
	return buf.String()
}

func renderInteractiveBoard(board [BoardSize][BoardSize]*Piece, gameID string, selectedRow, selectedCol int, callerAddr string, currentTurn Color, g *Game) string {
	var buf bytes.Buffer
	buf.WriteString("\n### Board\n\n")

	// Column headers
	buf.WriteString("|   | a | b | c | d | e | f | g | h |\n")
	buf.WriteString("|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|\n")

	for r := 0; r < BoardSize; r++ {
		buf.WriteString("| **" + strconv.Itoa(r) + "** |")
		for c := 0; c < BoardSize; c++ {
			if (r+c)%2 == 0 {
				buf.WriteString("   |") // Non-playable square
				continue
			}

			p := board[r][c]
			if p == nil {
				// Empty playable square
				if selectedRow >= 0 && selectedCol >= 0 {
					// Make it a move destination link
					link := "checkers$help&func=Move&.send=&gameID=" + gameID + "&fromRow=" + strconv.Itoa(selectedRow) + "&fromCol=" + strconv.Itoa(selectedCol) + "&toRow=" + strconv.Itoa(r) + "&toCol=" + strconv.Itoa(c)
					buf.WriteString(" [" + "·" + "](" + link + ") |")
				} else {
					buf.WriteString(" · |")
				}
			} else {
				// Piece square - make it selectable if it's the current turn's piece
				var pieceSymbol string
				if p.Color == RED {
					if p.King {
						pieceSymbol = "♛"
					} else {
						pieceSymbol = "●"
					}
				} else {
					if p.King {
						pieceSymbol = "♕"
					} else {
						pieceSymbol = "○"
					}
				}

				// Make pieces of the current turn's color clickable
				// (In local dev, we allow playing both sides)
				canSelect := p.Color == currentTurn

				if canSelect {
					// Make it clickable to select as source
					link := "?game=" + gameID + "&select=" + strconv.Itoa(r) + "," + strconv.Itoa(c)
					buf.WriteString(" [" + pieceSymbol + "](" + link + ") |")
				} else {
					buf.WriteString(" " + pieceSymbol + " |")
				}
			}
		}
		buf.WriteByte('\n')
	}

	return buf.String()
}

func renderGame(g *Game, queryParams map[string]string, callerAddr string) string {
	var output strings.Builder

	output.WriteString("# Game: " + g.ID + "\n\n")

	// Navigation
	output.WriteString("[← Back to Home](?) | ")
	output.WriteString("[All Games](?list) | ")
	if callerAddr != "" {
		output.WriteString("[My Games](?mygames)")
	}
	output.WriteString("\n\n")

	// Game info
	output.WriteString("**Status:** " + string(g.Status))
	if g.Status == StatusActive {
		output.WriteString(" | **Turn:** " + string(g.Turn))
		if isPlayerTurn(g, callerAddr) {
			output.WriteString(" ⭐ *Your turn!*")
		}
	}
	if g.Winner != "" {
		output.WriteString(" | **Winner:** " + string(g.Winner))
	}
	output.WriteString("\n\n")

	output.WriteString("**Red Player:** `" + g.Red + "`  \n")
	output.WriteString("**Black Player:** `" + g.Black + "`  \n\n")

	// Parse query params for selection
	selectedRow, selectedCol := -1, -1
	if selectParam := queryParams["select"]; selectParam != "" {
		coords := strings.Split(selectParam, ",")
		if len(coords) == 2 {
			selectedRow, _ = strconv.Atoi(coords[0])
			selectedCol, _ = strconv.Atoi(coords[1])
		}
	}

	// Interactive board
	if g.Status == StatusActive {
		output.WriteString(renderInteractiveBoard(g.Board, g.ID, selectedRow, selectedCol, callerAddr, g.Turn, g))

		if selectedRow >= 0 && selectedCol >= 0 {
			output.WriteString("\n**Selected:** Row " + strconv.Itoa(selectedRow) + ", Col " + strconv.Itoa(selectedCol) + "  \n")
			output.WriteString("Click a destination square above to make your move.\n\n")
			output.WriteString("[Clear Selection](?game=" + g.ID + ")\n\n")
		} else {
			output.WriteString("\n**Instructions:** Click on one of your pieces (● for Red, ○ for Black) to select it, then click a destination square to move.\n\n")
		}
	} else {
		// Game over - show static board
		output.WriteString(renderBoard(g.Board))
	}

	// Move history
	if len(g.History) > 0 {
		output.WriteString("\n---\n\n")
		output.WriteString("### Move History\n\n")
		output.WriteString("| Move | From | To | Player | Captured |\n")
		output.WriteString("|------|------|----|--------|----------|\n")
		for i, move := range g.History {
			from := string(rune('a'+move.From.Col)) + strconv.Itoa(move.From.Row)
			to := string(rune('a'+move.To.Col)) + strconv.Itoa(move.To.Row)
			captured := strconv.Itoa(len(move.Captured))
			if move.KingPromoted {
				to += " 👑"
			}
			output.WriteString("| " + strconv.Itoa(i+1) + " | " + from + " | " + to + " | " + string(move.Player) + " | " + captured + " |\n")
		}
	} else {
		output.WriteString("\n---\n\n")
		output.WriteString("### Move History\n\n")
		output.WriteString("*No moves yet. Make the first move!*\n")
	}

	return output.String()
}

func renderList() string {
	if len(games) == 0 {
		return "No games yet. Create one below!\n"
	}
	var buf strings.Builder
	buf.WriteString("### All Games\n\n")
	buf.WriteString("| Game ID | Status | Red | Black |\n")
	buf.WriteString("|---------|--------|-----|-------|\n")
	for id, g := range games {
		redShort := g.Red
		blackShort := g.Black
		if len(redShort) > 12 {
			redShort = redShort[:12] + "…"
		}
		if len(blackShort) > 12 {
			blackShort = blackShort[:12] + "…"
		}
		buf.WriteString("| [" + id + "](?game=" + id + ") | " + string(g.Status) + " | `" + redShort + "` | `" + blackShort + "` |\n")
	}
	return buf.String()
}

func renderMyGames(callerAddr string) string {
	if callerAddr == "" {
		return "### My Games\n\n*Sign in to see your games*\n"
	}

	myGames := GamesByAddress(callerAddr)
	if len(myGames) == 0 {
		return "### My Games\n\n*You have no active games. Create one to get started!*\n"
	}

	var buf strings.Builder
	buf.WriteString("### My Games\n\n")
	buf.WriteString("| Game ID | Status | Your Color | Opponent |\n")
	buf.WriteString("|---------|--------|------------|----------|\n")

	for _, id := range myGames {
		g, ok := games[id]
		if !ok {
			continue
		}

		var myColor string
		var opponent string
		if g.Red == callerAddr {
			myColor = "RED"
			opponent = g.Black
		} else {
			myColor = "BLACK"
			opponent = g.Red
		}

		opponentShort := opponent
		if len(opponentShort) > 12 {
			opponentShort = opponentShort[:12] + "…"
		}

		buf.WriteString("| [" + id + "](?game=" + id + ") | " + string(g.Status) + " | " + myColor + " | `" + opponentShort + "` |\n")
	}

	return buf.String()
}

func renderHome(callerAddr string) string {
	var output strings.Builder

	output.WriteString("# ♟️ Checkers Game\n\n")
	output.WriteString("A complete 1v1 Checkers (Draughts) game implementation in Gno.\n\n")

	output.WriteString("## How to Play\n\n")
	output.WriteString("1. **Create a game** - Challenge another player by entering their address\n")
	output.WriteString("2. **Make moves** - Click your pieces (● for Red, ○ for Black) to select, then click destination\n")
	output.WriteString("3. **Win** - Capture all opponent pieces or block their moves\n\n")

	output.WriteString("## Navigation\n\n")
	output.WriteString("* [All Games](?list) - View all games\n")
	if callerAddr != "" {
		output.WriteString("* [My Games](?mygames) - View your games\n")
	}
	output.WriteString("\n")

	// Create game section
	output.WriteString("## Create New Game\n\n")
	output.WriteString("Challenge another player by providing their Gno address.\n\n")

	output.WriteString("**You play as:** RED (moves first)  \n")
	output.WriteString("**Opponent plays as:** BLACK  \n\n")

	output.WriteString("[📝 Create New Game](checkers$help&func=CreateGame)\n\n")

	output.WriteString("**Instructions:**\n")
	output.WriteString("1. Click the link above to open the transaction dialog\n")
	output.WriteString("2. Enter your opponent's address in the `black` field\n")
	output.WriteString("3. Submit the transaction\n\n")

	// Show user's games if logged in
	if callerAddr != "" {
		output.WriteString("---\n\n")
		output.WriteString(renderMyGames(callerAddr))
		output.WriteString("\n")
	}

	// List all games
	output.WriteString("---\n\n")
	output.WriteString(renderList())

	return output.String()
}
