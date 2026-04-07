package goo

import (
	"chain"
	"chain/banker"
	"chain/runtime"
	"strconv"
	"time"

	"gno.land/p/nt/avl"
	"gno.land/p/nt/seqid"
	"gno.land/p/nt/ufmt"
)

var (
	admin           address
	resolutionTime  = 2 * int64(time.Minute.Seconds())
	requesterReward = 1 * int64(1_000_000) // in GNOT
	bond            = 2 * int64(1_000_000) // in GNOT
	requests        = avl.NewTree()
	bank            = banker.NewBanker(banker.BankerTypeRealmSend)
	idGenerator     seqid.ID
)

func init() {
	admin = runtime.CurrentRealm().Address()
}

// -- PUBLIC FUNCTIONS --

// RequestData allows a user to request data from the oracle.
// `requesterReward` value needs to be sent to the contract as a reward
// `deadline`is the timestamp in unix format for the deadline of the request.
// You need to ask a question that can be answered with a single number like a yes/no question (0 or 1) or a specific value (e.g. ETH/USD price).
func RequestData(_ realm, ancillaryData string, yesNoQuestion bool, deadline int64) string {
	if ancillaryData == "" {
		panic("error: Ancillary data cannot be empty.")
	}

	if deadline < time.Now().Add(24*time.Hour).Unix() {
		panic("error: Deadline must be at least 24 hours in the future.")
	}

	coins := banker.OriginSend()
	if len(coins) != 1 || coins.AmountOf("ugnot") != requesterReward {
		panic(ufmt.Sprintf("error: Incorrect reward amount sent. Required: %d ugnot.", requesterReward))
	}

	id := idGenerator.Next().String()

	request := &DataRequest{
		Id:            id,
		Timestamp:     time.Now(),
		AncillaryData: ancillaryData,
		YesNoQuestion: yesNoQuestion,
		State:         "Requested",
		Deadline:      time.Unix(deadline, 0),
		Creator:       runtime.PreviousRealm().Address(),
	}
	requests.Set(id, request)
	chain.Emit("DataRequested", "id", id, "timestamp", request.Timestamp.String(), "ancillaryData", ancillaryData)
	return id
}

// ProposeValue allows a user to propose a value for a requested data point.
// `bond` value needs to be sent to the contract as a bond.
func ProposeValue(_ realm, id string, proposedValue int64) {
	request := getRequest(id)
	if request.State != "Requested" {
		panic("error: Request is not in 'Requested' state.")
	}

	if request.YesNoQuestion && proposedValue != 0 && proposedValue != 1 {
		panic("error: Proposed value must be 0 or 1 for yes/no questions.")
	}

	if time.Now().After(request.Deadline) {
		panic("error: Deadline for proposal has passed.")
	}

	coins := banker.OriginSend()
	if len(coins) != 1 || coins.AmountOf("ugnot") != bond {
		panic("error: Incorrect bond amount sent. Required: " + strconv.FormatInt(bond, 10) + " ugnot")
	}

	request.ProposedValue = proposedValue
	request.Proposer = runtime.PreviousRealm().Address()
	request.ProposerBond = bond
	request.ResolutionTime = time.Now().Add(time.Duration(resolutionTime) * time.Second)
	request.State = "Proposed"
	chain.Emit("ValueProposed", "id", id, "proposedValue", strconv.Itoa(int(proposedValue)), "proposer", request.Proposer.String(), "resolutionTime", request.ResolutionTime.String())
}

// DisputeData allows a user to dispute a proposed value.
// `bond` value needs to be sent to the contract as a bond.
func DisputeData(_ realm, id string) string {
	request := getRequest(id)
	if request.Proposer == runtime.PreviousRealm().Address() {
		panic("error: Proposer cannot dispute their own proposal.")
	}

	if request.State != "Proposed" {
		panic("error: Request is not in 'Proposed' state.")
	}

	if time.Now().After(request.ResolutionTime) {
		panic("error: Dispute period has ended.")
	}

	coins := banker.OriginSend()
	if len(coins) != 1 || coins.AmountOf("ugnot") != bond {
		panic("error: Incorrect bond amount sent. Required: " + strconv.FormatInt(bond, 10) + " ugnot")
	}

	request.Disputer = runtime.PreviousRealm().Address()
	request.DisputerBond = bond
	request.State = "Disputed"
	initiateDispute(id)
	chain.Emit("DataDisputed", "id", id, "disputer", request.Disputer.String())
	return "Time: " + time.Now().String()
}

// ResolveRequest finalizes an undisputed request after the resolution period has passed.
func ResolveRequest(_ realm, id string) {
	request := getRequest(id)
	if request.State == "Disputed" {
		panic("error: Request is in 'Disputed' state.")
	}

	if request.State == "Proposed" && request.ResolutionTime.After(time.Now()) {
		panic("error: Resolution period has not ended yet.")
	}

	if request.State == "Requested" {
		panic("error: Request has not been proposed yet.")
	}

	if request.State == "Resolved" {
		panic("error: Request is already resolved.")
	}

	request.State = "Resolved"
	request.WinningValue = request.ProposedValue

	from := runtime.CurrentRealm().Address()
	to := request.Proposer
	totalPayout := request.ProposerBond + requesterReward
	payout := chain.Coins{chain.Coin{Denom: "ugnot", Amount: totalPayout}}
	bank.SendCoins(from, to, payout)

	chain.Emit("RequestResolved", "id", id, "winningValue", strconv.Itoa(int(request.WinningValue)))
}

// RequestResult returns the winning value of a resolved request.
func RequestResult(_ realm, id string) int64 {
	request := getRequest(id)
	if request.State != "Resolved" {
		panic("error: Request is not resolved.")
	}
	return request.WinningValue
}

// RequesterRetreiveFund allows the original requester to get their reward back if the deadline passed without a proposal.
func RequesterRetreiveFund(_ realm, id string) {
	request := getRequest(id)
	if request.State != "Requested" {
		panic("error: cannot retreive fund as requests fulfilled.")
	}

	if request.Creator != runtime.PreviousRealm().Address() {
		panic("error: Only the creator of the request can retrieve the fund.")
	}

	if request.Deadline.After(time.Now()) {
		panic("error: Cannot retrieve fund before the deadline.")
	}

	from := runtime.CurrentRealm().Address()
	to := request.Creator
	refund := chain.Coins{chain.Coin{Denom: "ugnot", Amount: requesterReward}}
	bank.SendCoins(from, to, refund)

	request.State = "Expired"
	chain.Emit("RequestExpired", "id", id)
}

// -- ADMIN FUNCTIONS --

// SetResolutionDuration sets the duration (in seconds) for the resolution period.
func SetResolutionDuration(_ realm, duration int64) {
	if runtime.OriginCaller() == admin {
		resolutionTime = duration
		chain.Emit("resolutionTimeSet", "duration", strconv.Itoa(int(duration)))
	} else {
		panic("error: Only the admin can set the resolution time.")
	}
}

// SetrequesterReward sets the reward amount for a successful proposal.
func SetrequesterReward(_ realm, reward int64) {
	if runtime.OriginCaller() == admin {
		requesterReward = reward
		chain.Emit("requesterRewardSet", "reward", strconv.Itoa(int(reward)))
	} else {
		panic("error: Only the admin can set the requester reward.")
	}
}

// SetBond sets the bond amount required for proposals and disputes.
func SetBond(_ realm, newBond int64) {
	if runtime.OriginCaller() == admin {
		bond = newBond
		chain.Emit("bondSet", "bond", strconv.Itoa(int(bond)))
	} else {
		panic("error: Only the admin can set the proposer bond.")
	}
}

// ChangeAdmin transfers admin privileges to a new address.
func ChangeAdmin(_ realm, newAdmin address) {
	if runtime.OriginCaller() == admin {
		admin = newAdmin
		chain.Emit("AdminChanged", "newAdmin", newAdmin.String())
	} else {
		panic("error: Only the admin can change the admin.")
	}
}

// -- VIEW FUNCTIONS --

// GetRequest returns the details of a specific data request.
func GetRequest(id string) *DataRequest {
	return getRequest(id)
}

// GetBond returns the current bond amount.
func GetBond() int64 {
	return bond
}

// GetResolutionTime returns the current resolution time duration.
func GetResolutionTime() int64 {
	return resolutionTime
}

// GetRequesterReward returns the current requester reward amount.
func GetRequesterReward() int64 {
	return requesterReward
}

// GetRequeststate returns the current state of a specific data request.
func GetRequeststate(id string) string {
	request := getRequest(id)
	return request.State
}

// GetAdmin returns the current admin address.
func GetAdmin() address {
	return admin
}

// Utils functions

func getRequest(id string) *DataRequest {
	request, exists := requests.Get(id)
	if !exists {
		panic("error: Request with this ID does not exist.")
	}
	return request.(*DataRequest)
}
