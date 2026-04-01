package gnopendao

import (
	"chain"
	"chain/banker"
	"chain/runtime"
	"errors"
	"strconv"
	"time"

	"gno.land/p/nt/commondao"
	"gno.land/p/nt/ufmt"
)

const (
	PROPOSAL_TYPE_APPROVE_COLLECTION   = "approve_collection"
	PROPOSAL_TYPE_REMOVE_COLLECTION    = "remove_collection"
	PROPOSAL_TYPE_UPDATE_FEES          = "update_fees"
	PROPOSAL_TYPE_WITHDRAW_TREASURY    = "withdraw_treasury"
	PROPOSAL_TYPE_FORCE_CANCEL_LISTING = "force_cancel_listing"

	VOTING_PERIOD = 10 * time.Minute
	QUORUM        = commondao.QuorumOneThird // 33%
)

// CollectionProposal - Proposal to approve or remove a collection
type CollectionProposal struct {
	proposalType   string
	collectionAddr address
	collectionName string
	reason         string
	approved       bool
	executed       bool
}

func newCollectionProposal(propType string, addr address, name string, reason string) *CollectionProposal {
	return &CollectionProposal{
		proposalType:   propType,
		collectionAddr: addr,
		collectionName: name,
		reason:         reason,
		approved:       false,
		executed:       false,
	}
}

func (p *CollectionProposal) Title() string {
	if p.proposalType == PROPOSAL_TYPE_APPROVE_COLLECTION {
		return "Approve Collection: " + p.collectionName
	}
	return "Remove Collection: " + p.collectionName
}

func (p *CollectionProposal) Body() string {
	return ufmt.Sprintf(
		"Type: %s\nCollection: %s\nAddress: %s\nReason: %s\n\nVote YES to approve, NO to reject",
		p.proposalType,
		p.collectionName,
		p.collectionAddr.String(),
		p.reason,
	)
}

func (p *CollectionProposal) VotingPeriod() time.Duration {
	return VOTING_PERIOD
}

func (p *CollectionProposal) Tally(ctx commondao.VotingContext) (bool, error) {
	votes := ctx.VotingRecord
	members := ctx.Members

	yesVotes := 0
	noVotes := 0

	votes.Iterate(0, votes.Size(), false, func(v commondao.Vote) bool {
		if v.Choice == commondao.ChoiceYes {
			yesVotes++
		} else if v.Choice == commondao.ChoiceNo {
			noVotes++
		}
		return false
	})

	// Check quorum
	if !commondao.IsQuorumReached(QUORUM, votes, members) {
		p.approved = false
		return false, commondao.ErrNoQuorum
	}

	// Simple majority
	p.approved = yesVotes > noVotes
	return p.approved, nil
}

func (p *CollectionProposal) Execute(realm) error {
	if p.proposalType == PROPOSAL_TYPE_APPROVE_COLLECTION {
		approvedCollections.Set(p.collectionAddr.String(), true)
	} else if p.proposalType == PROPOSAL_TYPE_REMOVE_COLLECTION {
		approvedCollections.Remove(p.collectionAddr.String())
	}

	p.executed = true
	return nil
}

func (p *CollectionProposal) GetCollectionAddr() address {
	return p.collectionAddr
}

// FeesProposal - Proposal to update marketplace fees
type FeesProposal struct {
	newFee   int64
	reason   string
	approved bool
	executed bool
}

func newFeesProposal(newFee int64, reason string) *FeesProposal {
	return &FeesProposal{
		newFee:   newFee,
		reason:   reason,
		approved: false,
		executed: false,
	}
}

func (p *FeesProposal) Title() string {
	return ufmt.Sprintf("Update Marketplace Fee to %d basis points", p.newFee)
}

func (p *FeesProposal) Body() string {
	currentFeePercent := float64(marketplaceFee) / 100.0
	newFeePercent := float64(p.newFee) / 100.0

	return ufmt.Sprintf(
		"Current Fee: %.2f%%\nProposed Fee: %.2f%%\nReason: %s\n\nVote YES to approve, NO to reject",
		currentFeePercent,
		newFeePercent,
		p.reason,
	)
}

func (p *FeesProposal) VotingPeriod() time.Duration {
	return VOTING_PERIOD
}

func (p *FeesProposal) Tally(ctx commondao.VotingContext) (bool, error) {
	votes := ctx.VotingRecord
	members := ctx.Members

	yesVotes := 0
	noVotes := 0

	votes.Iterate(0, votes.Size(), false, func(v commondao.Vote) bool {
		if v.Choice == commondao.ChoiceYes {
			yesVotes++
		} else if v.Choice == commondao.ChoiceNo {
			noVotes++
		}
		return false
	})

	// Check quorum
	if !commondao.IsQuorumReached(QUORUM, votes, members) {
		p.approved = false
		return false, commondao.ErrNoQuorum
	}

	// Simple majority
	p.approved = yesVotes > noVotes
	return p.approved, nil
}

func (p *FeesProposal) Execute(realm) error {
	marketplaceFee = p.newFee
	p.executed = true
	return nil
}

func (p *FeesProposal) GetNewFee() int64 {
	return p.newFee
}

// TreasuryProposal - Proposal to withdraw funds from treasury
type TreasuryProposal struct {
	amount    int64
	recipient address
	reason    string
	approved  bool
	executed  bool
}

func NewTreasuryProposal(amount int64, recipient address, reason string) *TreasuryProposal {
	return &TreasuryProposal{
		amount:    amount,
		recipient: recipient,
		reason:    reason,
		approved:  false,
		executed:  false,
	}
}

func (p *TreasuryProposal) Title() string {
	return ufmt.Sprintf("Withdraw %d ugnot from Treasury", p.amount)
}

func (p *TreasuryProposal) Body() string {
	currentBalance := GetBalance()

	return ufmt.Sprintf(
		"Withdraw: %s\nRecipient: %s\nCurrent Treasury: %s\nReason: %s\n\nVote YES to approve, NO to reject",
		formatPrice(p.amount),
		p.recipient.String(),
		formatPrice(currentBalance),
		p.reason,
	)
}

func (p *TreasuryProposal) VotingPeriod() time.Duration {
	return VOTING_PERIOD
}

func (p *TreasuryProposal) Tally(ctx commondao.VotingContext) (bool, error) {
	votes := ctx.VotingRecord
	members := ctx.Members

	yesVotes := 0
	noVotes := 0

	votes.Iterate(0, votes.Size(), false, func(v commondao.Vote) bool {
		if v.Choice == commondao.ChoiceYes {
			yesVotes++
		} else if v.Choice == commondao.ChoiceNo {
			noVotes++
		}
		return false
	})

	// Check quorum
	if !commondao.IsQuorumReached(QUORUM, votes, members) {
		p.approved = false
		return false, commondao.ErrNoQuorum
	}

	// Simple majority
	p.approved = yesVotes > noVotes
	return p.approved, nil
}

func (p *TreasuryProposal) Execute(realm) error {
	currentBalance := GetBalance()
	if currentBalance < p.amount {
		return errors.New("insufficient treasury balance")
	}

	bnkr := banker.NewBanker(banker.BankerTypeRealmSend)
	realmAddr := runtime.CurrentRealm().Address()

	coins := chain.Coins{chain.Coin{"ugnot", p.amount}}
	bnkr.SendCoins(realmAddr, p.recipient, coins)

	p.executed = true
	return nil
}

func (p *TreasuryProposal) GetAmount() int64 {
	return p.amount
}

func (p *TreasuryProposal) GetRecipient() address {
	return p.recipient
}

// ForceCancelListingProposal - Proposal to force cancel a problematic listing
type ForceCancelListingProposal struct {
	listingId int
	reason    string
	approved  bool
	executed  bool
}

func NewForceCancelListingProposal(listingId int, reason string) *ForceCancelListingProposal {
	return &ForceCancelListingProposal{
		listingId: listingId,
		reason:    reason,
		approved:  false,
		executed:  false,
	}
}

func (p *ForceCancelListingProposal) Title() string {
	return ufmt.Sprintf("Force Cancel Listing #%d", p.listingId)
}

func (p *ForceCancelListingProposal) Body() string {
	listing := getListing(p.listingId)
	if listing == nil {
		return ufmt.Sprintf("Listing #%d\nStatus: NOT FOUND\nReason: %s\n\nVote YES to approve, NO to reject", p.listingId, p.reason)
	}

	return ufmt.Sprintf(
		"Listing ID: %d\nToken ID: %s\nSeller: %s\nPrice: %s\nReason for cancellation: %s\n\nVote YES to force cancel, NO to reject",
		p.listingId,
		listing.TokenId.String(),
		listing.Seller.String(),
		formatPrice(listing.Price),
		p.reason,
	)
}

func (p *ForceCancelListingProposal) VotingPeriod() time.Duration {
	return VOTING_PERIOD
}

func (p *ForceCancelListingProposal) Tally(ctx commondao.VotingContext) (bool, error) {
	votes := ctx.VotingRecord
	members := ctx.Members

	yesVotes := 0
	noVotes := 0

	votes.Iterate(0, votes.Size(), false, func(v commondao.Vote) bool {
		if v.Choice == commondao.ChoiceYes {
			yesVotes++
		} else if v.Choice == commondao.ChoiceNo {
			noVotes++
		}
		return false
	})

	// Check quorum
	if !commondao.IsQuorumReached(QUORUM, votes, members) {
		p.approved = false
		return false, commondao.ErrNoQuorum
	}

	// Simple majority
	p.approved = yesVotes > noVotes
	return p.approved, nil
}

func (p *ForceCancelListingProposal) Execute(realm) error {
	listing := getListing(p.listingId)
	if listing == nil {
		return errors.New("listing not found")
	}

	if !listing.Active {
		return errors.New("listing already inactive")
	}

	listing.Active = false
	listings.Set(strconv.Itoa(p.listingId), listing)

	p.executed = true
	return nil
}

func (p *ForceCancelListingProposal) GetListingId() int {
	return p.listingId
}
