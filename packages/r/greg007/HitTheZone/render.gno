package hitthezone

import (
	"net/url"
	"strconv"
	"strings"

	"gno.land/p/leon/svgbtn"
	"gno.land/p/moul/md"
	"gno.land/p/moul/txlink"
)

// Render generates the HTML/markdown UI for the Hit The Zone game.
// It accepts a path parameter that may contain query parameters (min, max, amount)
// and returns a formatted string with the game interface, rules, and history.
func Render(path string) string {
	_, rawQuery, _ := strings.Cut(path, "?")
	query, _ := url.ParseQuery(rawQuery)

	minVal := query.Get("min")
	maxVal := query.Get("max")
	amount := query.Get("amount")

	var out strings.Builder

	out.WriteString(md.H1("🎯 Hit The Zone!"))
	out.WriteString(md.Paragraph(md.Bold("Try to guess if the random number (1-100) falls in your range!")))

	leftColumn := renderQuickPlay(minVal, maxVal, amount)
	rightColumn := renderRules()

	out.WriteString(md.Columns([]string{leftColumn, rightColumn}, false))
	out.WriteString(md.HorizontalRule())
	out.WriteString(renderHistory())

	return out.String()
}

// renderQuickPlay generates the Quick Play section of the UI.
// It displays a form for entering game parameters and shows game info with a play button
// when min, max, and amount values are provided.
func renderQuickPlay(minVal, maxVal, amount string) string {
	var col strings.Builder

	col.WriteString(md.H2("⚡ Quick Play"))
	col.WriteString("<gno-form path=\"\">\n")
	col.WriteString("	<gno-input name=\"min\" type=\"number\" placeholder=\"Enter min (1-100)\" />\n")
	col.WriteString("	<gno-input name=\"max\" type=\"number\" placeholder=\"Enter max (1-100)\" />\n")
	col.WriteString("	<gno-input name=\"amount\" type=\"number\" placeholder=\"Enter amount (ugnot)\" />\n")
	col.WriteString("</gno-form>\n\n")

	if minVal != "" && maxVal != "" {
		min, _ := strconv.Atoi(minVal)
		max, _ := strconv.Atoi(maxVal)
		multiplier := CalculateMultiplier(min, max)
		winChance := float64(max - min + 1)

		col.WriteString(md.H3("🎰 Game Info"))
		col.WriteString(md.Bold("Range:") + " " + minVal + " - " + maxVal + "\n")
		col.WriteString(md.Bold("Win Chance:") + " " + strconv.FormatFloat(winChance, 'f', 1, 64) + "%\n\n")
		col.WriteString(md.Bold("Amount:") + " " + amount + " ugnot\n\n")
		col.WriteString(md.Bold("Multiplier:") + " x" + strconv.FormatFloat(multiplier, 'f', 2, 64) + "\n\n")

		txLink := txlink.NewLink("Game").AddArgs("min", minVal, "max", maxVal).SetSend(amount + "ugnot").URL()
		col.WriteString(svgbtn.Button(300, 40, "blue", "white", "Play and Bet", txLink))
		col.WriteString("\n\n")
	}

	return col.String()
}

// renderRules generates the game rules section of the UI.
// It displays how to play instructions, betting rules, casino bankroll information,
// and a donation button.
func renderRules() string {
	var col strings.Builder

	col.WriteString(md.H2("📋 Game Rules"))
	col.WriteString(md.H3("How to Play"))

	howToPlay := []string{
		md.Bold("Choose your range") + " (min-max)",
		md.Bold("Check the multiplier") + " displayed",
		md.Bold("Send GNOT") + " with your transaction",
		md.Bold("Win if") + " the random number (1-100) falls in your range!",
	}
	col.WriteString(md.OrderedList(howToPlay))
	col.WriteString("\n")

	col.WriteString(md.H3("Betting Rules"))
	bettingRules := []string{
		md.Bold("Minimum bet:") + " 1 ugnot",
		md.Bold("Smaller range") + " = Higher multiplier",
		md.Bold("Range 1-100:") + " x1.00",
		md.Bold("Range 50-50:") + " x100.00",
		md.Bold("Win amount:") + " Bet × Multiplier",
	}
	col.WriteString(md.BulletList(bettingRules))
	col.WriteString("\n")

	col.WriteString(md.H3("🏦 Casino Bankroll"))
	col.WriteString(md.Bold("Available:") + " " + strconv.FormatInt(GetRealmBalance(), 10) + " ugnot\n")
	col.WriteString(md.Bold("Donations:") + " " + strconv.FormatInt(GetTotalDonations(), 10) + " ugnot\n\n")

	col.WriteString(svgbtn.Button(300, 40, "green", "white", "💚 Support the game!", "/r/greg007/hitthezone$help&func=Donate&.send=1000000ugnot"))
	col.WriteString("\n\n")

	return col.String()
}

// renderHistory generates the game history table showing the last 10 games played.
// It displays player addresses, bet ranges, random numbers, results, statuses,
// bet amounts, win amounts, and multipliers in a formatted markdown table.
func renderHistory() string {
	var out strings.Builder

	out.WriteString(md.H2("📜 Complete Game History (Last 10 Games)"))
	fullHistory := GetGameHistory()

	if len(fullHistory) == 0 {
		out.WriteString(md.Paragraph(md.Italic("No games played yet")))
	} else {
		out.WriteString("| Player | Range | Random | Result | Status | Bet | Win | Multiplier |\n")
		out.WriteString("|--------|-------|--------|--------|--------|-----|-----|------------|\n")

		for _, game := range fullHistory {
			out.WriteString("| " + game.Player.String() + " | ")
			out.WriteString(strconv.Itoa(game.Min) + "-" + strconv.Itoa(game.Max) + " | ")
			out.WriteString(strconv.Itoa(game.RandomNumber) + " | ")
			out.WriteString(getResultDisplay(game.Result))
			out.WriteString(strconv.FormatInt(game.BetAmount, 10) + " | ")
			out.WriteString(strconv.FormatInt(game.WinAmount, 10) + " | ")
			out.WriteString("x" + strconv.FormatFloat(game.Multiplier, 'f', 2, 64) + " |\n")
		}
	}

	return out.String()
}

// getResultDisplay returns the formatted display string for a game result and status.
// It takes a result string and returns the corresponding markdown table cells
// with appropriate emoji indicators for win/lose status and payout status.
func getResultDisplay(result string) string {
	switch result {
	case "Win":
		return "✅ Win | ✅ Paid | "
	case "Lose":
		return "❌ Lose | - | "
	case "Win (Insufficient funds - refunded)", "Win (Payment failed - refunded)":
		return "✅ Win | 🔄 Refunded | "
	case "Win (House broke - no payout)":
		return "✅ Win | 💔 No payout | "
	default:
		return result + " | - | "
	}
}
