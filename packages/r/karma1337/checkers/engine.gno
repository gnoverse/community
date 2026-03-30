package checkers

var forwardDirs = map[Color]int{
	RED:   1,  // rows increase going "down" the board
	BLACK: -1, // rows decrease going "up" the board
}

func initialBoard() [BoardSize][BoardSize]*Piece {
	var b [BoardSize][BoardSize]*Piece
	for r := 0; r < BoardSize; r++ {
		for c := 0; c < BoardSize; c++ {
			if (r+c)%2 == 0 {
				continue
			}
			switch {
			case r <= 2:
				b[r][c] = &Piece{Color: RED}
			case r >= 5:
				b[r][c] = &Piece{Color: BLACK}
			}
		}
	}
	return b
}

func isOnBoard(row, col int) bool {
	return row >= 0 && row < BoardSize && col >= 0 && col < BoardSize
}

func hasAnyMoves(g *Game, color Color) bool {
	for r := 0; r < BoardSize; r++ {
		for c := 0; c < BoardSize; c++ {
			p := g.Board[r][c]
			if p == nil || p.Color != color {
				continue
			}
			if canPieceMove(g, r, c) {
				return true
			}
		}
	}
	return false
}

func canPieceMove(g *Game, row, col int) bool {
	p := g.Board[row][col]
	if p == nil {
		return false
	}
	if pieceHasCapture(g, row, col) {
		return true
	}
	dirs := moveDirs(p)
	for _, d := range dirs {
		nr, nc := row+d.Row, col+d.Col
		if isOnBoard(nr, nc) && g.Board[nr][nc] == nil {
			return true
		}
	}
	return false
}

type dir struct {
	Row int
	Col int
}

func moveDirs(p *Piece) []dir {
	if p.King {
		return []dir{{1, 1}, {1, -1}, {-1, 1}, {-1, -1}}
	}
	forward := forwardDirs[p.Color]
	return []dir{{forward, 1}, {forward, -1}}
}

func captureDirs(p *Piece) []dir {
	steps := moveDirs(p)
	out := make([]dir, len(steps))
	for i, d := range steps {
		out[i] = dir{Row: d.Row * 2, Col: d.Col * 2}
	}
	return out
}

func pieceHasCapture(g *Game, row, col int) bool {
	p := g.Board[row][col]
	if p == nil {
		return false
	}
	for _, d := range captureDirs(p) {
		midR, midC := row+d.Row/2, col+d.Col/2
		nr, nc := row+d.Row, col+d.Col
		if !isOnBoard(nr, nc) {
			continue
		}
		mid := g.Board[midR][midC]
		if mid != nil && mid.Color != p.Color && g.Board[nr][nc] == nil {
			return true
		}
	}
	return false
}

func anyCaptureAvailable(g *Game, color Color) bool {
	for r := 0; r < BoardSize; r++ {
		for c := 0; c < BoardSize; c++ {
			if p := g.Board[r][c]; p != nil && p.Color == color {
				if pieceHasCapture(g, r, c) {
					return true
				}
			}
		}
	}
	return false
}

func applyMove(g *Game, fromRow, fromCol, toRow, toCol int, caller string) MoveRecord {
	if g.Status != StatusActive {
		panic("game not active")
	}
	if !isOnBoard(fromRow, fromCol) || !isOnBoard(toRow, toCol) {
		panic("out of bounds")
	}
	p := g.Board[fromRow][fromCol]
	if p == nil {
		panic("no piece at source")
	}
	expectAddr := g.Red
	if g.Turn == BLACK {
		expectAddr = g.Black
	}
	if caller != expectAddr {
		panic("not your turn")
	}
	if p.Color != g.Turn {
		panic("wrong color piece")
	}
	if g.Board[toRow][toCol] != nil {
		panic("destination occupied")
	}

	moveDelta := dir{Row: toRow - fromRow, Col: toCol - fromCol}
	isCapture := abs(moveDelta.Row) == 2 && abs(moveDelta.Col) == 2

	// Mandatory capture rule.
	if anyCaptureAvailable(g, g.Turn) && !isCapture {
		panic("capture required")
	}

	// Validate move direction and distance.
	if !isCapture {
		valid := false
		for _, d := range moveDirs(p) {
			if d.Row == moveDelta.Row && d.Col == moveDelta.Col {
				valid = true
				break
			}
		}
		if !valid {
			panic("invalid move")
		}
	} else {
		// Capture validation.
		capR := fromRow + moveDelta.Row/2
		capC := fromCol + moveDelta.Col/2
		mid := g.Board[capR][capC]
		if mid == nil || mid.Color == p.Color {
			panic("nothing to capture")
		}
		valid := false
		for _, d := range captureDirs(p) {
			if d.Row == moveDelta.Row && d.Col == moveDelta.Col {
				valid = true
				break
			}
		}
		if !valid {
			panic("invalid capture direction")
		}
		g.Board[capR][capC] = nil
	}

	// Apply move.
	g.Board[fromRow][fromCol] = nil
	wasKing := p.King
	promoted := maybePromote(p, toRow)
	g.Board[toRow][toCol] = p

	record := MoveRecord{
		From:         Coord{Row: fromRow, Col: fromCol},
		To:           Coord{Row: toRow, Col: toCol},
		Player:       p.Color,
		KingPromoted: promoted && !wasKing,
		MoveIndex:    len(g.History),
	}
	if isCapture {
		record.Captured = []Coord{{Row: (fromRow + toRow) / 2, Col: (fromCol + toCol) / 2}}
	}
	g.History = append(g.History, record)

	// Switch turn and check game end.
	g.Turn = opposite(g.Turn)
	checkGameEnded(g)
	return record
}

func checkGameEnded(g *Game) {
	redPieces := 0
	blackPieces := 0
	for r := 0; r < BoardSize; r++ {
		for c := 0; c < BoardSize; c++ {
			if p := g.Board[r][c]; p != nil {
				if p.Color == RED {
					redPieces++
				} else {
					blackPieces++
				}
			}
		}
	}

	if redPieces == 0 {
		g.Status = StatusBlackWon
		g.Winner = BLACK
		return
	}
	if blackPieces == 0 {
		g.Status = StatusRedWon
		g.Winner = RED
		return
	}

	redHasMoves := hasAnyMoves(g, RED)
	blackHasMoves := hasAnyMoves(g, BLACK)

	switch {
	case !redHasMoves && !blackHasMoves:
		g.Status = StatusDraw
	case !redHasMoves:
		g.Status = StatusBlackWon
		g.Winner = BLACK
	case !blackHasMoves:
		g.Status = StatusRedWon
		g.Winner = RED
	}
}

func maybePromote(p *Piece, toRow int) bool {
	if p.King {
		return false
	}
	if p.Color == RED && toRow == BoardSize-1 {
		p.King = true
		return true
	}
	if p.Color == BLACK && toRow == 0 {
		p.King = true
		return true
	}
	return false
}

func opposite(c Color) Color {
	if c == RED {
		return BLACK
	}
	return RED
}

func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}
