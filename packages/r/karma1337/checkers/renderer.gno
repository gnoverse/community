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
	buf.WriteString("    a   b   c   d   e   f   g   h\n")
	buf.WriteString("  +---+---+---+---+---+---+---+---+\n")
	for r := 0; r < BoardSize; r++ {
		buf.WriteString(strconv.Itoa(r) + " |")
		for c := 0; c < BoardSize; c++ {
			if (r+c)%2 == 0 {
				buf.WriteString("   |")
				continue
			}
			p := board[r][c]
			if p == nil {
				buf.WriteString(" · |")
				continue
			}
			if p.Color == RED {
				if p.King {
					buf.WriteString(" ♔ |")
				} else {
					buf.WriteString(" ● |")
				}
			} else {
				if p.King {
					buf.WriteString(" ♚ |")
				} else {
					buf.WriteString(" ○ |")
				}
			}
		}
		buf.WriteString("\n  +---+---+---+---+---+---+---+---+\n")
	}
	buf.WriteString("```\n")
	return buf.String()
}

func renderInteractiveBoard(board [BoardSize][BoardSize]*Piece, gameID string, selectedRow, selectedCol int, callerAddr string, currentTurn Color, g *Game) string {
	var buf bytes.Buffer

	// Board with better styling
	buf.WriteString("|     | a | b | c | d | e | f | g | h |     |\n")
	buf.WriteString("|:---:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:---:|\n")

	for r := 0; r < BoardSize; r++ {
		buf.WriteString("| **" + strconv.Itoa(r) + "** |")
		for c := 0; c < BoardSize; c++ {
			isSelected := r == selectedRow && c == selectedCol

			if (r+c)%2 == 0 {
				// Light square (non-playable)
				buf.WriteString("   |")
				continue
			}

			p := board[r][c]
			if p == nil {
				// Empty dark square
				if selectedRow >= 0 && selectedCol >= 0 {
					// Make it a move destination link - highlight possible moves
					link := "checkers$help&func=Move&.send=&gameID=" + gameID + "&fromRow=" + strconv.Itoa(selectedRow) + "&fromCol=" + strconv.Itoa(selectedCol) + "&toRow=" + strconv.Itoa(r) + "&toCol=" + strconv.Itoa(c)
					buf.WriteString(" [·](" + link + ") |")
				} else {
					buf.WriteString(" · |")
				}
			} else {
				// Piece on square
				var pieceSymbol string
				if p.Color == RED {
					if p.King {
						pieceSymbol = "♔"
					} else {
						pieceSymbol = "🔴"
					}
				} else {
					if p.King {
						pieceSymbol = "♚"
					} else {
						pieceSymbol = "⚫"
					}
				}

				// Highlight selected piece
				if isSelected {
					pieceSymbol = "✦"
				}

				canSelect := p.Color == currentTurn

				if canSelect && !isSelected {
					link := "?game=" + gameID + "&select=" + strconv.Itoa(r) + "," + strconv.Itoa(c)
					buf.WriteString(" [" + pieceSymbol + "](" + link + ") |")
				} else {
					buf.WriteString(" " + pieceSymbol + " |")
				}
			}
		}
		buf.WriteString(" **" + strconv.Itoa(r) + "** |\n")
	}

	buf.WriteString("|     | a | b | c | d | e | f | g | h |     |\n")

	return buf.String()
}

func renderGame(g *Game, queryParams map[string]string, callerAddr string) string {
	var output strings.Builder

	// Header with game ID
	output.WriteString("# 🎮 Game: `" + g.ID + "`\n\n")

	// Navigation bar
	output.WriteString("> [🏠 Home](?) • [📋 All Games](?list)")
	if callerAddr != "" {
		output.WriteString(" • [👤 My Games](?mygames)")
	}
	output.WriteString("\n\n")

	// Game status box
	output.WriteString("---\n\n")

	if g.Status == StatusActive {
		turnEmoji := "🔴"
		turnText := "RED"
		if g.Turn == BLACK {
			turnEmoji = "⚫"
			turnText = "BLACK"
		}
		output.WriteString("### " + turnEmoji + " " + turnText + "'s Turn")
		if isPlayerTurn(g, callerAddr) {
			output.WriteString(" — *It's your move!*")
		}
		output.WriteString("\n\n")
	} else {
		// Game over
		var statusEmoji string
		switch g.Status {
		case StatusRedWon:
			statusEmoji = "🏆 RED WINS!"
		case StatusBlackWon:
			statusEmoji = "🏆 BLACK WINS!"
		case StatusDraw:
			statusEmoji = "🤝 DRAW"
		}
		output.WriteString("### " + statusEmoji + "\n\n")
	}

	// Players info
	output.WriteString("| Player | Address |\n")
	output.WriteString("|:------:|:--------|\n")
	redIndicator := "🔴"
	blackIndicator := "⚫"
	if g.Turn == RED && g.Status == StatusActive {
		redIndicator = "▶️ 🔴"
	} else if g.Turn == BLACK && g.Status == StatusActive {
		blackIndicator = "▶️ ⚫"
	}
	output.WriteString("| " + redIndicator + " RED | `" + g.Red + "` |\n")
	output.WriteString("| " + blackIndicator + " BLACK | `" + g.Black + "` |\n\n")

	// Parse query params for selection
	selectedRow, selectedCol := -1, -1
	if selectParam := queryParams["select"]; selectParam != "" {
		coords := strings.Split(selectParam, ",")
		if len(coords) == 2 {
			selectedRow, _ = strconv.Atoi(coords[0])
			selectedCol, _ = strconv.Atoi(coords[1])
		}
	}

	output.WriteString("---\n\n")

	// Board section
	output.WriteString("### 📋 Board\n\n")

	if g.Status == StatusActive {
		output.WriteString(renderInteractiveBoard(g.Board, g.ID, selectedRow, selectedCol, callerAddr, g.Turn, g))

		// Legend
		output.WriteString("\n**Legend:** 🔴 Red • ⚫ Black • ♔ Red King • ♚ Black King • · Empty\n\n")

		if selectedRow >= 0 && selectedCol >= 0 {
			col := string(rune('a' + selectedCol))
			output.WriteString("> ✦ **Selected:** `" + col + strconv.Itoa(selectedRow) + "` — Click a ◌ to move there\n\n")
			output.WriteString("[❌ Clear Selection](?game=" + g.ID + ")\n\n")
		} else {
			output.WriteString("> 💡 **Tip:** Click one of your pieces to select it, then click where to move\n\n")
		}
	} else {
		output.WriteString(renderBoard(g.Board))
	}

	// Move history
	output.WriteString("---\n\n")
	output.WriteString("### 📜 Move History\n\n")

	if len(g.History) > 0 {
		output.WriteString("| # | From | To | Player | Capture |\n")
		output.WriteString("|:-:|:----:|:--:|:------:|:-------:|\n")
		for i, move := range g.History {
			from := string(rune('a'+move.From.Col)) + strconv.Itoa(move.From.Row)
			to := string(rune('a'+move.To.Col)) + strconv.Itoa(move.To.Row)

			playerEmoji := "🔴"
			if move.Player == BLACK {
				playerEmoji = "⚫"
			}

			captureText := "—"
			if len(move.Captured) > 0 {
				captureText = "💥 " + strconv.Itoa(len(move.Captured))
			}

			if move.KingPromoted {
				to += " 👑"
			}

			output.WriteString("| " + strconv.Itoa(i+1) + " | " + from + " | " + to + " | " + playerEmoji + " | " + captureText + " |\n")
		}
	} else {
		output.WriteString("*No moves yet — make the first move!*\n")
	}

	return output.String()
}

func renderList() string {
	if len(games) == 0 {
		return "*No games yet. Be the first to create one!*\n"
	}

	var buf strings.Builder
	buf.WriteString("| Game | Status | 🔴 Red | ⚫ Black |\n")
	buf.WriteString("|:-----|:------:|:-------|:--------|\n")

	for id, g := range games {
		redShort := g.Red
		blackShort := g.Black
		if len(redShort) > 10 {
			redShort = redShort[:10] + "…"
		}
		if len(blackShort) > 10 {
			blackShort = blackShort[:10] + "…"
		}

		statusEmoji := "🎮"
		switch g.Status {
		case StatusRedWon:
			statusEmoji = "🔴🏆"
		case StatusBlackWon:
			statusEmoji = "⚫🏆"
		case StatusDraw:
			statusEmoji = "🤝"
		}

		buf.WriteString("| [" + id + "](?game=" + id + ") | " + statusEmoji + " | `" + redShort + "` | `" + blackShort + "` |\n")
	}
	return buf.String()
}

func renderMyGames(callerAddr string) string {
	if callerAddr == "" {
		return "### 👤 My Games\n\n*Connect wallet to see your games*\n"
	}

	myGames := GamesByAddress(callerAddr)
	if len(myGames) == 0 {
		return "### 👤 My Games\n\n*No games yet — create one to get started!*\n"
	}

	var buf strings.Builder
	buf.WriteString("### 👤 My Games\n\n")
	buf.WriteString("| Game | Status | You | Opponent |\n")
	buf.WriteString("|:-----|:------:|:---:|:---------|\n")

	for _, id := range myGames {
		g, ok := games[id]
		if !ok {
			continue
		}

		var myColor string
		var opponent string
		if g.Red == callerAddr {
			myColor = "🔴"
			opponent = g.Black
		} else {
			myColor = "⚫"
			opponent = g.Red
		}

		opponentShort := opponent
		if len(opponentShort) > 10 {
			opponentShort = opponentShort[:10] + "…"
		}

		statusEmoji := "🎮"
		if g.Status != StatusActive {
			if (g.Winner == RED && g.Red == callerAddr) || (g.Winner == BLACK && g.Black == callerAddr) {
				statusEmoji = "🏆"
			} else if g.Status == StatusDraw {
				statusEmoji = "🤝"
			} else {
				statusEmoji = "💀"
			}
		} else if isPlayerTurn(g, callerAddr) {
			statusEmoji = "⏳"
		}

		buf.WriteString("| [" + id + "](?game=" + id + ") | " + statusEmoji + " | " + myColor + " | `" + opponentShort + "` |\n")
	}

	return buf.String()
}

func renderHome(callerAddr string) string {
	var output strings.Builder

	// Hero section
	output.WriteString("# ♟️ Gno Checkers\n\n")
	output.WriteString("> A fully on-chain 1v1 Checkers game built on Gno\n\n")

	output.WriteString("---\n\n")

	// Quick actions
	output.WriteString("## 🎮 Play Now\n\n")
	output.WriteString("[**➕ Create New Game**](checkers$help&func=CreateGame)\n\n")

	// How it works
	output.WriteString("### How to Play\n\n")
	output.WriteString("| Step | Action |\n")
	output.WriteString("|:----:|:-------|\n")
	output.WriteString("| 1️⃣ | Create a game with opponent's address |\n")
	output.WriteString("| 2️⃣ | 🔴 RED moves first, then ⚫ BLACK |\n")
	output.WriteString("| 3️⃣ | Click your piece, then click destination |\n")
	output.WriteString("| 4️⃣ | Capture all enemy pieces to win! |\n\n")

	// Rules summary
	output.WriteString("### Rules\n\n")
	output.WriteString("- Pieces move **diagonally forward**\n")
	output.WriteString("- **Jump** over enemies to capture them\n")
	output.WriteString("- Reach the end to become a **King** 👑\n")
	output.WriteString("- Kings move in **all diagonal directions**\n")
	output.WriteString("- **Captures are mandatory** when available\n\n")

	output.WriteString("---\n\n")

	// Navigation
	output.WriteString("## 📋 Games\n\n")
	output.WriteString("[View All Games](?list)")
	if callerAddr != "" {
		output.WriteString(" • [My Games](?mygames)")
	}
	output.WriteString("\n\n")

	// Show user's games if logged in
	if callerAddr != "" {
		output.WriteString(renderMyGames(callerAddr))
		output.WriteString("\n")
	}

	// List all games
	output.WriteString("### 🌐 All Games\n\n")
	output.WriteString(renderList())

	return output.String()
}
