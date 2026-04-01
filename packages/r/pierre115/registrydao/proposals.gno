package registrydao

import (
	"errors"
	"time"

	"gno.land/p/nt/commondao"
	"gno.land/p/nt/ufmt"
)

const (
	PROPOSAL_TYPE_VERIFY_COLLECTION   = "verify_collection"
	PROPOSAL_TYPE_UNVERIFY_COLLECTION = "unverify_collection"

	REGISTRY_VOTING_PERIOD = 5 * time.Minute
	REGISTRY_QUORUM        = commondao.QuorumOneThird // 33%
)

// NewVerifyCollectionProposal creates a new VerifyCollectionProposal instance.
func NewVerifyCollectionProposal(addr address, name string, reason string) *VerifyCollectionProposal {
	return &VerifyCollectionProposal{
		collectionAddr: addr,
		collectionName: name,
		reason:         reason,
		approved:       false,
		executed:       false,
	}
}

func (p *VerifyCollectionProposal) Title() string {
	return "Verify Collection: " + p.collectionName
}

func (p *VerifyCollectionProposal) Body() string {
	return ufmt.Sprintf(
		"Collection: %s\nAddress: %s\nReason: %s\n\nVote YES to verify, NO to reject",
		p.collectionName,
		p.collectionAddr.String(),
		p.reason,
	)
}

func (p *VerifyCollectionProposal) VotingPeriod() time.Duration {
	return REGISTRY_VOTING_PERIOD
}

func (p *VerifyCollectionProposal) Tally(ctx commondao.VotingContext) (bool, error) {
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
	if !commondao.IsQuorumReached(REGISTRY_QUORUM, votes, members) {
		p.approved = false
		return false, commondao.ErrNoQuorum
	}

	// Simple majority
	p.approved = yesVotes > noVotes
	return p.approved, nil
}

func (p *VerifyCollectionProposal) Execute(realm) error {
	info := GetCollection(p.collectionAddr)
	if info == nil {
		return errors.New("collection not found")
	}

	if info.Verified {
		return errors.New("collection already verified")
	}

	info.Verified = true
	collections.Set(p.collectionAddr.String(), info)

	p.executed = true
	return nil
}

// UnverifyCollectionProposal - Proposal to unverify a collection
type UnverifyCollectionProposal struct {
	collectionAddr address
	collectionName string
	reason         string
	approved       bool
	executed       bool
}

func NewUnverifyCollectionProposal(addr address, name string, reason string) *UnverifyCollectionProposal {
	return &UnverifyCollectionProposal{
		collectionAddr: addr,
		collectionName: name,
		reason:         reason,
		approved:       false,
		executed:       false,
	}
}

func (p *UnverifyCollectionProposal) Title() string {
	return "Unverify Collection: " + p.collectionName
}

func (p *UnverifyCollectionProposal) Body() string {
	return ufmt.Sprintf(
		"Collection: %s\nAddress: %s\nReason: %s\n\nVote YES to unverify, NO to reject",
		p.collectionName,
		p.collectionAddr.String(),
		p.reason,
	)
}

func (p *UnverifyCollectionProposal) VotingPeriod() time.Duration {
	return REGISTRY_VOTING_PERIOD
}

func (p *UnverifyCollectionProposal) Tally(ctx commondao.VotingContext) (bool, error) {
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
	if !commondao.IsQuorumReached(REGISTRY_QUORUM, votes, members) {
		p.approved = false
		return false, commondao.ErrNoQuorum
	}

	// Simple majority
	p.approved = yesVotes > noVotes
	return p.approved, nil
}

func (p *UnverifyCollectionProposal) Execute(realm) error {
	info := GetCollection(p.collectionAddr)
	if info == nil {
		return errors.New("collection not found")
	}

	if !info.Verified {
		return errors.New("collection not verified")
	}

	info.Verified = false
	collections.Set(p.collectionAddr.String(), info)

	p.executed = true
	return nil
}
