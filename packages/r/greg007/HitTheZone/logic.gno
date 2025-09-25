package hitthezone

import (
	"math/rand"
	"std"
	"strconv"
	"time"

	"gno.land/p/demo/entropy"
	"gno.land/p/moul/fifo"
)

// ========== VARIABLES GLOBALES ==========

var (
	lastRandomNumber int = 1
	counter          uint64
	gameHistory      = fifo.New(10)
	totalDonations   int64
	ownerAddress     std.Address
)

func init() {
	ownerAddress = std.OriginCaller()
}

// ========== CORE FUNCTIONS ==========

func generateRandom() {
	counter++
	seed1 := uint64(entropy.New().Seed())
	seed2 := uint64(entropy.New().Seed())

	r := rand.New(rand.NewPCG(seed1, seed2))
	lastRandomNumber = r.IntN(100) + 1
}

func safeSendCoins(recipient std.Address, amount int64) bool {
	defer func() {
		if r := recover(); r != nil {
			// Payment failed - log the failure
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

	// Log successful payment
	std.Emit("PaymentSent",
		"recipient", recipient.String(),
		"amount", strconv.FormatInt(amount, 10),
		"timestamp", strconv.FormatInt(time.Now().Unix(), 10))

	return true
}

func Game(cur realm, min int, max int) {
	std.AssertOriginCall()
	
	// 1. Validate inputs
	betAmount := validateGameInputs(min, max)
	
	// 2. Play the game
	multiplier := CalculateMultiplier(min, max)
	won := playGame(min, max)
	
	// 3. Handle payout
	caller := std.OriginCaller()
	result, actualWinAmount := handlePayout(won, betAmount, multiplier, caller)
	
	// 4. Record game
	recordGame(caller, min, max, betAmount, actualWinAmount, multiplier, result)
}

// Validate all game inputs and return bet amount
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

// Play the game and return if player won
func playGame(min, max int) bool {
	generateRandom()
	return lastRandomNumber >= min && lastRandomNumber <= max
}

// Handle all payout logic and return result message and actual payout
func handlePayout(won bool, betAmount int64, multiplier float64, caller std.Address) (string, int64) {
	if !won {
		return "Lose", 0
	}

	// Player won - calculate and try to pay
	winAmount := int64(float64(betAmount) * multiplier)
	currentBalance := GetRealmBalance() - betAmount
	
	if currentBalance >= winAmount {
		// Can pay full winnings
		success := safeSendCoins(caller, winAmount)
		if success {
			std.Emit("GamePayout",
				"player", caller.String(),
				"type", "win_payout",
				"bet_amount", strconv.FormatInt(betAmount, 10),
				"win_amount", strconv.FormatInt(winAmount, 10),
				"multiplier", strconv.FormatFloat(multiplier, 'f', 2, 64))
			return "Win", winAmount
		} else {
			// Payment failed, refund bet
			safeSendCoins(caller, betAmount)
			std.Emit("GamePayout",
				"player", caller.String(),
				"type", "refund_after_failed_payout",
				"bet_amount", strconv.FormatInt(betAmount, 10),
				"refund_amount", strconv.FormatInt(betAmount, 10))
			return "Win (Payment failed - refunded)", betAmount
		}
	} else if currentBalance >= betAmount {
		// Can't pay winnings, but can refund bet
		safeSendCoins(caller, betAmount)
		std.Emit("GamePayout",
			"player", caller.String(),
			"type", "refund_insufficient_funds",
			"bet_amount", strconv.FormatInt(betAmount, 10),
			"refund_amount", strconv.FormatInt(betAmount, 10),
			"required_amount", strconv.FormatInt(winAmount, 10))
		return "Win (Insufficient funds - refunded)", betAmount
	} else {
		// House is completely broke
		std.Emit("GamePayout",
			"player", caller.String(),
			"type", "no_payout_house_broke",
			"bet_amount", strconv.FormatInt(betAmount, 10),
			"required_amount", strconv.FormatInt(winAmount, 10))
		return "Win (House broke - no payout)", 0
	}
}

// Record the game in history
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

// ========== GETTERS (Used in Render) ==========

func GetRealmBalance() int64 {
	banker := std.NewBanker(std.BankerTypeReadonly)
	coins := banker.GetCoins(std.CurrentRealm().Address())
	return coins.AmountOf("ugnot")
}

func GetTotalDonations() int64 {
	return totalDonations
}

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

	// Reverse to show most recent first
	for i, j := 0, len(history)-1; i < j; i, j = i+1, j-1 {
		history[i], history[j] = history[j], history[i]
	}

	return history
}

func CalculateMultiplier(min, max int) float64 {
	if min < 0 || max > 100 || min > max {
		return 0.0
	}
	rangeSize := max - min + 1
	return 100.0 / float64(rangeSize)
}

// ========== ADMIN FUNCTIONS (Optional - keep for emergencies) ==========

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