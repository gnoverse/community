package goo

import (
	"chain"
	"chain/runtime"
	"strconv"
	"testing"
	"time"

	"gno.land/p/nt/testutils"
	"gno.land/p/nt/urequire"
)

var (
	user1 = testutils.TestAddress("user1")
	user2 = testutils.TestAddress("user2")
	user3 = testutils.TestAddress("user3")
)

func TestRequestData(t *testing.T) {
	testing.SetRealm(testing.NewUserRealm(user1))
	urequire.AbortsWithMessage(t, "error: Incorrect reward amount sent. Required: "+strconv.FormatInt(requesterReward, 10)+" ugnot.", func() {
		RequestData(cross, "test", true, time.Now().Add(24*time.Hour).Unix())
	}, "user should not be able to request data without sending the requester reward")

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: requesterReward}})
	urequire.AbortsWithMessage(t, "error: Ancillary data cannot be empty.", func() {
		RequestData(cross, "", true, time.Now().Add(24*time.Hour).Unix())
	}, "user should not be able to request data with an empty ancillary data")

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: requesterReward}})
	urequire.AbortsWithMessage(t, "error: Deadline must be at least 24 hours in the future.", func() {
		RequestData(cross, "test", true, time.Now().Unix())
	}, "user should not be able to request data with a deadline less than 24 hours in the future")

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: requesterReward}})
	urequire.NotPanics(t, func() {
		RequestData(cross, "test", true, time.Now().Add(24*time.Hour).Unix())
	}, "user should be able to request data")
}

func TestProposeValue(t *testing.T) {
	testing.SetRealm(testing.NewUserRealm(user1))
	urequire.AbortsWithMessage(t, "error: Request with this ID does not exist.", func() {
		ProposeValue(cross, "test", 0)
	}, "request id does not exist but didn't revert")

	// create a request
	now := time.Now()
	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: requesterReward}})
	id := RequestData(cross, "test", true, time.Now().Add(24*time.Hour).Unix())

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	urequire.AbortsWithMessage(t, "error: Proposed value must be 0 or 1 for yes/no questions.", func() {
		ProposeValue(cross, id, 9)
	}, "user should not be able to propose a value other than 0 or 1 for a yes/no question")

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: 0}})
	urequire.AbortsWithMessage(t, "error: Incorrect bond amount sent. Required: "+strconv.FormatInt(bond, 10)+" ugnot", func() {
		ProposeValue(cross, id, 0)
	}, "user should not be able to propose a value without sending the bond")

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	setTime(time.Now().Add(25 * time.Hour))
	urequire.AbortsWithMessage(t, "error: Deadline for proposal has passed.", func() {
		ProposeValue(cross, id, 0)
	}, "user should not be able to propose a value after the deadline")

	testing.SetRealm(testing.NewUserRealm(user1))
	setTime(now.Add(time.Hour))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	urequire.NotPanics(t, func() {
		ProposeValue(cross, id, 0)
	}, "user should be able to propose a value")

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	urequire.AbortsWithMessage(t, "error: Request is not in 'Requested' state.", func() {
		ProposeValue(cross, id, 0)
	}, "user should not be able to propose a value if the request is not in 'Requested' state")
}

func TestDisputeData(t *testing.T) {
	// setup: create request and propose a value
	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: requesterReward}})
	now := time.Now()
	id := RequestData(cross, "test", true, time.Now().Add(24*time.Hour).Unix())
	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	ProposeValue(cross, id, 0)

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	urequire.AbortsWithMessage(t, "error: Request with this ID does not exist.", func() {
		DisputeData(cross, "test")
	}, "request id does not exist but didn't revert")

	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	urequire.AbortsWithMessage(t, "error: Proposer cannot dispute their own proposal.", func() {
		DisputeData(cross, id)
	}, "proposer cannot dispute their own proposal")

	testing.SetRealm(testing.NewUserRealm(user2))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: 0}})
	urequire.AbortsWithMessage(t, "error: Incorrect bond amount sent. Required: "+strconv.FormatInt(bond, 10)+" ugnot", func() {
		DisputeData(cross, id)
	}, "user should not be able to dispute a value without sending the bond")

	testing.SetRealm(testing.NewUserRealm(user2))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	setTime(time.Now().Add(time.Duration(resolutionTime)*time.Second + time.Second))
	urequire.AbortsWithMessage(t, "error: Dispute period has ended.", func() {
		DisputeData(cross, id)
	}, "user should not be able to dispute a value after the dispute period has ended")

	testing.SetRealm(testing.NewUserRealm(user2))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	setTime(now.Add(time.Second))
	urequire.NotPanics(t, func() {
		DisputeData(cross, id)
	}, "user should be able to dispute a value")

	testing.SetRealm(testing.NewUserRealm(user2))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: bond}})
	urequire.AbortsWithMessage(t, "error: Request is not in 'Proposed' state.", func() {
		DisputeData(cross, id)
	}, "user should not be able to dispute a value if the request is not in 'Proposed' state")
}

func TestResolveRequest(t *testing.T) {
	// setup: create request
	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: requesterReward}})
	now := time.Now()
	id := RequestData(cross, "test", true, time.Now().Add(24*time.Hour).Unix())

	testing.SetRealm(testing.NewUserRealm(user1))
	urequire.AbortsWithMessage(t, "error: Request has not been proposed yet.", func() {
		ResolveRequest(cross, id)
	}, "user should not be able to resolve a request if it has not been proposed yet")

	// propose a value
	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend(chain.Coins{{Denom: "ugnot", Amount: bond}})
	ProposeValue(cross, id, 0)

	testing.SetRealm(testing.NewUserRealm(user1))
	urequire.AbortsWithMessage(t, "error: Resolution period has not ended yet.", func() {
		ResolveRequest(cross, id)
	}, "user should not be able to resolve a request if the resolution period has not ended yet")

	setTime(now.Add(time.Duration(resolutionTime)*time.Second + time.Second))
	CreateGnotCoins(cross, bond+requesterReward)
	urequire.NotPanics(t, func() {
		ResolveRequest(cross, id)
	}, "user should be able to resolve a request")

	testing.SetRealm(testing.NewUserRealm(user1))
	urequire.AbortsWithMessage(t, "error: Request is already resolved.", func() {
		ResolveRequest(cross, id)
	}, "user should not be able to resolve a request if it is already resolved")
}

func TestRequesterRetreiveFund(t *testing.T) {
	// setup: create request
	testing.SetRealm(testing.NewUserRealm(user1))
	testing.SetOriginSend([]chain.Coin{{Denom: "ugnot", Amount: requesterReward}})
	duration := time.Now().Add(24 * time.Hour)
	id := RequestData(cross, "test", true, duration.Unix())

	testing.SetRealm(testing.NewUserRealm(user2))
	urequire.AbortsWithMessage(t, "error: Only the creator of the request can retrieve the fund.", func() {
		RequesterRetreiveFund(cross, id)
	}, "only requester should be able to retrieve funds")

	testing.SetRealm(testing.NewUserRealm(user1))
	setTime(duration.Add(time.Hour))
	CreateGnotCoins(cross, requesterReward)
	urequire.NotPanics(t, func() {
		RequesterRetreiveFund(cross, id)
	}, "requester should be able to retrieve funds")
}

// Helper functions

func setTime(newTime time.Time) {
	ctx := testing.GetContext()
	ctx.Time = newTime
	testing.SetContext(ctx)
}

func CreateGnotCoins(_ realm, amount int64) {
	testing.IssueCoins(runtime.CurrentRealm().Address(), chain.Coins{{Denom: "ugnot", Amount: amount}})
}
