package hitthezone

import (
	"strconv"
	"strings"

	"gno.land/p/leon/svgbtn"
	"gno.land/p/moul/txlink"
)

func Render(path string) string {

	// Parser les paramètres du formulaire si présents
	minVal := ""
	maxVal := ""
	amount := ""

	if strings.Contains(path, "?") {
		parts := strings.Split(path, "?")
		if len(parts) > 1 {
			params := strings.Split(parts[1], "&")
			for _, param := range params {
				keyVal := strings.Split(param, "=")
				if len(keyVal) == 2 {
					if keyVal[0] == "min" {
						minVal = keyVal[1]
					} else if keyVal[0] == "max" {
						maxVal = keyVal[1]
					} else if keyVal[0] == "amount" {
						amount = keyVal[1]
					}
				}
			}
		}
	}

	out := "# 🎯 Hit The Zone!\n\n"
	out += "**Try to guess if the random number (1-100) falls in your range!**\n\n"

	out += "<gno-columns>\n\n"

	// Colonne de gauche - Quick Play
	out += "## ⚡ Quick Play\n\n"
	out += "<gno-form path=\"\">\n"
	out += "	<gno-input name=\"min\" type=\"number\" placeholder=\"Enter min (1-100)\" />\n"
	out += "	<gno-input name=\"max\" type=\"number\" placeholder=\"Enter max (1-100)\" />\n"
	out += "	<gno-input name=\"amount\" type=\"number\" placeholder=\"Enter amount (ugnot)\" />\n"
	out += "</gno-form>\n\n"

	// Afficher le bouton de transaction si des valeurs sont disponibles
	if minVal != "" && maxVal != "" {
		min, _ := strconv.Atoi(minVal)
		max, _ := strconv.Atoi(maxVal)
		multiplier := CalculateMultiplier(min, max)
		winChance := float64(max-min+1)

		out += "### 🎰 Game Info\n"
		out += "**Range: " + minVal + " - " + maxVal + "**\n"
		out += "**Win Chance: " + strconv.FormatFloat(winChance, 'f', 1, 64) + "%**\n\n"
		out += "**Amount: " + amount + " ugnot**\n\n"
		out += "**Multiplier: x" + strconv.FormatFloat(multiplier, 'f', 2, 64) + "**\n\n"

		txLink := txlink.NewLink("Game").AddArgs("min", minVal, "max", maxVal).SetSend(amount + "ugnot").URL()
		out += svgbtn.Button(
		300,
		40,
		"blue",
		"white",
		"Play and Bet",
		txLink,
		) + "\n\n"
	}

	out += "|||\n\n"

	// Colonne de droite - Rules
	out += "## 📋 Game Rules\n\n"
	out += "### How to Play\n"
	out += "1. **Choose your range** (min-max)\n"
	out += "2. **Check the multiplier** displayed\n"
	out += "3. **Send GNOT** with your transaction\n"
	out += "4. **Win if** the random number (1-100) falls in your range!\n\n"

	out += "### Betting Rules\n"
	out += "- **Minimum bet:** 1 ugnot\n"
	out += "- **Smaller range** = Higher multiplier\n"
	out += "- **Range 1-100** = x1.00\n"
	out += "- **Range 50-50** = x100.00\n"
	out += "- **Win amount** = Bet × Multiplier\n\n"

	// Informations financières
	out += "### 🏦 Casino Bankroll\n"
	out += "**Available:** " + strconv.FormatInt(GetRealmBalance(), 10) + " ugnot\n"
	out += "**Donations:** " + strconv.FormatInt(GetTotalDonations(), 10) + " ugnot\n\n"

	// Bouton pour supporter le développeur
	out += svgbtn.Button(
		300,
		40,
		"green",
		"white",
		"💚 Support the game!",
		"/r/greg007/hitthezone$help&func=Donate&.send=1000000ugnot",
	) + "\n\n"

	out += "</gno-columns>\n\n"


	out += "---\n\n"

	// Tableau complet de l'historique
	out += "## 📜 Complete Game History (Last 10 Games)\n\n"
	fullHistory := GetGameHistory()

	if len(fullHistory) == 0 {
		out += "*No games played yet*\n\n"
	} else {
		out += "| Player | Range | Random | Result | Bet | Win | Multiplier |\n"
		out += "|--------|-------|--------|--------|-----|-----|------------|\n"

		for _, game := range fullHistory {
			out += "| " + game.Player.String() + " | "
			out += strconv.Itoa(game.Min) + "-" + strconv.Itoa(game.Max) + " | "
			out += strconv.Itoa(game.RandomNumber) + " | "

			if game.Result == "Win" {
				out += "✅ Win | "
			} else {
				out += "❌ Lose | "
			}

			out += strconv.FormatInt(game.BetAmount, 10) + " | "
			out += strconv.FormatInt(game.WinAmount, 10) + " | "
			out += "x" + strconv.FormatFloat(game.Multiplier, 'f', 2, 64) + " |\n"
		}
	}

	return out
}