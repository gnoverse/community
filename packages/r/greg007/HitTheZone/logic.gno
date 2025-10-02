package hitthezone

import (
	"math/rand"
	"std"
	"strconv"
	"time"

	"gno.land/p/demo/entropy"
	"gno.land/p/moul/fifo"
)

var (
	lastRandomNumber int = 1
	counter          uint64
	gameHistory      = fifo.New(10)
	totalDonations   int64
	ownerAddress     = std.OriginCaller()
)

// generateRandom generates a random number between 1 and 100 using entropy-based seeding.
// The generated number is stored in the global lastRandomNumber variable.
func generateRandom() {
	counter++
	seed1 := uint64(entropy.New().Seed())
	seed2 := uint64(entropy.New().Seed())

	r := rand.New(rand.NewPCG(seed1, seed2))
	lastRandomNumber = r.IntN(100) + 1
}

// safeSendCoins safely sends coins to a recipient with error handling and event emission.
// It returns true if the transfer was successful, false otherwise.
// Failed transfers are logged via events and recovered from panics.
func safeSendCoins(recipient std.Address, amount int64) bool {
	defer func() {
		if r := recover(); r != nil {
			std.Emit("PaymentFailed",
				"recipient", recipient.String(),
				"amount", strconv.FormatInt(amount, 10),
				"reason", "transaction_failed")
		}
	}()

	if amount <= 0 {
		return false
	}

	banker := std.NewBanker(std.BankerTypeRealmSend)
	coins := std.NewCoins(std.NewCoin("ugnot", amount))
	banker.SendCoins(std.CurrentRealm().Address(), recipient, coins)

	std.Emit("PaymentSent",
		"recipient", recipient.String(),
		"amount", strconv.FormatInt(amount, 10),
		"timestamp", strconv.FormatInt(time.Now().Unix(), 10))

	return true
}

// Game executes the main game logic for Hit The Zone.
// Players specify a min and max range, and a random number (1-100) is generated.
// If the random number falls within the range, the player wins based on the multiplier.
// The function validates inputs, plays the game, handles payouts, and records the result.
func Game(cur realm, min int, max int) {
	std.AssertOriginCall()

	betAmount := validateGameInputs(min, max)
	multiplier := CalculateMultiplier(min, max)
	won := playGame(min, max)

	caller := std.OriginCaller()
	result, actualWinAmount := handlePayout(won, betAmount, multiplier, caller)

	recordGame(caller, min, max, betAmount, actualWinAmount, multiplier, result)
}

// validateGameInputs validates all game inputs and returns the bet amount.
// It checks that min >= 1, max <= 100, min < max, and bet amount >= 1 ugnot.
// Panics if any validation fails.
func validateGameInputs(min, max int) int64 {
	if min < 1 {
		panic("min must be >= 1")
	}
	if max > 100 {
		panic("max must be <= 100")
	}
	if min >= max {
		panic("min must be < max")
	}

	coins := std.OriginSend()
	betAmount := int64(0)
	if len(coins) > 0 {
		betAmount = coins[0].Amount
	}

	if betAmount < 1 {
		panic("minimum bet is 1 ugnot")
	}

	return betAmount
}

// playGame generates a random number and checks if it falls within the player's range.
// Returns true if the player won, false otherwise.
func playGame(min, max int) bool {
	generateRandom()
	return lastRandomNumber >= min && lastRandomNumber <= max
}

// handlePayout handles all payout logic and returns the result message and actual payout amount.
// If the player won, it attempts to pay winnings based on the multiplier.
// If insufficient funds exist, it refunds the bet. All outcomes are logged via events.
// Uses early returns to minimize gas costs.
func handlePayout(won bool, betAmount int64, multiplier float64, caller std.Address) (string, int64) {
	if !won {
		return "Lose", 0
	}

	currentBalance := GetRealmBalance()

	if currentBalance < betAmount {
		return "Win (House broke - no payout)", 0
	}

	winAmount := int64(float64(betAmount) * multiplier)

	if currentBalance < winAmount {
		safeSendCoins(caller, betAmount)
		std.Emit("GamePayout",
			"player", caller.String(),
			"type", "refund_insufficient_funds",
			"bet_amount", strconv.FormatInt(betAmount, 10),
			"refund_amount", strconv.FormatInt(betAmount, 10),
			"required_amount", strconv.FormatInt(winAmount, 10))
		return "Win (Insufficient funds - refunded)", betAmount
	}

	return handleWinPayout(caller, betAmount, winAmount, multiplier)
}

// handleWinPayout attempts to pay the full winnings to the player.
// If payment fails, it refunds the bet instead.
func handleWinPayout(caller std.Address, betAmount, winAmount int64, multiplier float64) (string, int64) {
	if !safeSendCoins(caller, winAmount) {
		safeSendCoins(caller, betAmount)
		std.Emit("GamePayout",
			"player", caller.String(),
			"type", "refund_after_failed_payout",
			"bet_amount", strconv.FormatInt(betAmount, 10),
			"refund_amount", strconv.FormatInt(betAmount, 10))
		return "Win (Payment failed - refunded)", betAmount
	}

	std.Emit("GamePayout",
		"player", caller.String(),
		"type", "win_payout",
		"bet_amount", strconv.FormatInt(betAmount, 10),
		"win_amount", strconv.FormatInt(winAmount, 10),
		"multiplier", strconv.FormatFloat(multiplier, 'f', 2, 64))
	return "Win", winAmount
}

// recordGame records the game result in the game history.
// History is stored in a FIFO queue that keeps the last 10 games.
func recordGame(player std.Address, min, max int, betAmount, winAmount int64, multiplier float64, result string) {
	game := GameHistory{
		Player:       player,
		Min:          min,
		Max:          max,
		RandomNumber: lastRandomNumber,
		Result:       result,
		BetAmount:    betAmount,
		WinAmount:    winAmount,
		Multiplier:   multiplier,
		Timestamp:    time.Now(),
	}

	gameHistory.Append(game)
}

// Donate allows users to send donations to the game owner.
// The donated amount is transferred to the owner's address and tracked in totalDonations.
// Panics if the donation amount is invalid or the transfer fails.
func Donate(cur realm) {
	std.AssertOriginCall()

	coins := std.OriginSend()
	if len(coins) == 0 || coins[0].Amount <= 0 {
		panic("invalid donation")
	}

	success := safeSendCoins(ownerAddress, coins[0].Amount)
	if !success {
		panic("donation transfer failed")
	}

	totalDonations += coins[0].Amount

	std.Emit("Donation",
		"amount", strconv.FormatInt(coins[0].Amount, 10),
		"from", std.OriginCaller().String())
}

// GetRealmBalance returns the current balance of ugnot held by the realm.
func GetRealmBalance() int64 {
	banker := std.NewBanker(std.BankerTypeReadonly)
	coins := banker.GetCoins(std.CurrentRealm().Address())
	return coins.AmountOf("ugnot")
}

// GetTotalDonations returns the total amount of donations received by the game.
func GetTotalDonations() int64 {
	return totalDonations
}

// GetGameHistory returns the last 10 games played, ordered from most recent to oldest.
func GetGameHistory() []GameHistory {
	history := make([]GameHistory, 0, 10)

	for i := 0; i < 10; i++ {
		item := gameHistory.Get(i)
		if item == nil {
			break
		}
		if gameData, ok := item.(GameHistory); ok {
			history = append(history, gameData)
		}
	}

	for i, j := 0, len(history)-1; i < j; i, j = i+1, j-1 {
		history[i], history[j] = history[j], history[i]
	}

	return history
}

// CalculateMultiplier calculates the payout multiplier based on the chosen range.
// A smaller range results in a higher multiplier (up to x100 for a single number).
// Returns 0.0 if the range is invalid.
func CalculateMultiplier(min, max int) float64 {
	if min < 0 || max > 100 || min > max {
		return 0.0
	}
	rangeSize := max - min + 1
	return 100.0 / float64(rangeSize)
}

// WithdrawAll allows the owner to withdraw all funds from the realm.
// Only the owner can call this function.
// Panics if called by a non-owner or if the withdrawal fails.
func WithdrawAll(cur realm) {
	std.AssertOriginCall()

	if std.OriginCaller() != ownerAddress {
		panic("only owner can withdraw")
	}

	realmBalance := GetRealmBalance()
	if realmBalance <= 0 {
		panic("no funds to withdraw")
	}

	success := safeSendCoins(ownerAddress, realmBalance)
	if !success {
		panic("withdrawal failed")
	}
}
