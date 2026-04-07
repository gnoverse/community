package goo

import (
	"chain"
	"strconv"
	"testing"
	"time"

	"gno.land/p/nt/testutils"
	"gno.land/p/nt/urequire"
)

var user4 = testutils.TestAddress("user4")

func TestBuyInitialVoteToken(t *testing.T) {
	testing.SetRealm(testing.NewUserRealm(user1))
	urequire.AbortsWithMessage(t, "error: Must send exactly "+strconv.Itoa(int(voteTokenPrice/1_000_000))+" gnot to get a vote token.", func() {
		BuyInitialVoteToken(cross)
	}, "user should not be able to buy a vote token without sending the correct amount")

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: voteTokenPrice}})
	urequire.NotPanics(t, func() {
		BuyInitialVoteToken(cross)
	}, "user should be able to buy a vote token by sending the correct amount")
	amount := VoteToken.BalanceOf(user1)
	urequire.Equal(t, int64(1), amount, "user should have received a vote token")

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: voteTokenPrice}})
	urequire.AbortsWithMessage(t, "error: You already have a vote token.", func() {
		BuyInitialVoteToken(cross)
	}, "user should not be able to buy a second vote token")
}

func TestVoteOnDispute(t *testing.T) {
	// setup: create request and dispute
	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: requesterReward}})
	id := RequestData(cross, "test", true, time.Now().Add(24*time.Hour).Unix())

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	ProposeValue(cross, id, 0)

	testing.SetRealm(testing.NewUserRealm(user2))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	DisputeData(cross, id)

	// buy vote token
	testing.SetRealm(testing.NewUserRealm(user3))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: voteTokenPrice}})
	BuyInitialVoteToken(cross)

	// vote on dispute
	testing.SetRealm(testing.NewUserRealm(user3))
	urequire.NotPanics(t, func() {
		VoteOnDispute(cross, id, "a96e0beb59a16b085a7d2b3b5ffd6e5971870aa2903c6df86f26fa908ded2e21")
	}, "user should be able to vote on dispute")

	testing.SetRealm(testing.NewUserRealm(user4))
	urequire.AbortsWithMessage(t, "error: You need at least 1 vote token to vote.", func() {
		VoteOnDispute(cross, id, "hash")
	}, "user should not be able to vote on dispute without a vote token")

	testing.SetRealm(testing.NewUserRealm(user1))
	urequire.AbortsWithMessage(t, "error: Proposer and Disputer cannot vote in this dispute.", func() {
		VoteOnDispute(cross, id, "hash")
	}, "user should not be able to vote on dispute if they are the proposer or disputer")

	testing.SetRealm(testing.NewUserRealm(user3))
	urequire.AbortsWithMessage(t, "error: Voter has already voted in this dispute.", func() {
		VoteOnDispute(cross, id, "hash")
	}, "user should not be able to vote on dispute if they have already voted")

	testing.SetRealm(testing.NewUserRealm(user4))
	setTime(time.Now().Add(time.Duration(disputeDuration)*time.Second + time.Second))
	urequire.AbortsWithMessage(t, "error: Vote period has ended.", func() {
		VoteOnDispute(cross, id, "hash")
	}, "user should not be able to vote on dispute after the voting period has ended")
}

func TestRevealVote(t *testing.T) {
	// setup: create request and dispute
	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: requesterReward}})
	id := RequestData(cross, "test", true, time.Now().Add(24*time.Hour).Unix())

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	ProposeValue(cross, id, 0)

	testing.SetRealm(testing.NewUserRealm(user2))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	DisputeData(cross, id)

	// vote on dispute
	testing.SetRealm(testing.NewUserRealm(user3))
	VoteOnDispute(cross, id, "a96e0beb59a16b085a7d2b3b5ffd6e5971870aa2903c6df86f26fa908ded2e21")

	testing.SetRealm(testing.NewUserRealm(user3))
	setTime(time.Now().Add(time.Duration(disputeDuration)*time.Second + time.Second))
	urequire.AbortsWithMessage(t, "error: Hash does not match the revealed value and salt.", func() {
		RevealVote(cross, id, 1, "mysalt")
	}, "vote reveal with incorrect value and salt should fail")

	// reveal vote
	testing.SetRealm(testing.NewUserRealm(user3))
	urequire.NotPanics(t, func() {
		RevealVote(cross, id, 0, "test")
	}, "user should be able to reveal their vote")

	testing.SetRealm(testing.NewUserRealm(user3))
	urequire.AbortsWithMessage(t, "error: Vote already revealed.", func() {
		RevealVote(cross, id, 1, "mysalt")
	}, "user should not be able to reveal their vote again")
}

func TestResolveDispute(t *testing.T) {
	// setup: create request and dispute
	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: requesterReward}})
	id := RequestData(cross, "test", true, time.Now().Add(24*time.Hour).Unix())

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	ProposeValue(cross, id, 0)

	testing.SetRealm(testing.NewUserRealm(user2))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	DisputeData(cross, id)

	// vote on dispute
	testing.SetRealm(testing.NewUserRealm(user3))
	VoteOnDispute(cross, id, "a96e0beb59a16b085a7d2b3b5ffd6e5971870aa2903c6df86f26fa908ded2e21")
	setTime(time.Now().Add(time.Duration(disputeDuration)*time.Second + time.Second))
	RevealVote(cross, id, 0, "test")

	setTime(time.Now().Add(time.Duration(revealDuration)*time.Second + time.Second))
	CreateGnotCoins(cross, (bond*2)+requesterReward)
	urequire.NotPanics(t, func() {
		ResolveDispute(cross, id)
	}, "user should be able to resolve dispute after the reveal period has ended")

	urequire.AbortsWithMessage(t, "error: Dispute is already resolved.", func() {
		ResolveDispute(cross, id)
	}, "user should not be able to resolve dispute before the reveal period has ended")
}
