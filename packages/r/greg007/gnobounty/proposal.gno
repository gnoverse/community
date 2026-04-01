package gnobounty

import (
	"chain"
	"chain/banker"
	"time"

	"gno.land/p/nt/commondao"
	"gno.land/p/nt/ufmt"
)

// ClaimBountyProposal implements commondao.ProposalDefinition for bounty claim proposals
type ClaimBountyProposal struct {
	BountyID      uint64
	ApplicationID uint64
	Applicant     address
	PRLink        string
	title         string
	description   string
}

// NewClaimBountyProposal creates a new bounty claim proposal definition
func NewClaimBountyProposal(bountyID, applicationID uint64, applicant address, prLink string) *ClaimBountyProposal {
	return &ClaimBountyProposal{
		BountyID:      bountyID,
		ApplicationID: applicationID,
		Applicant:     applicant,
		PRLink:        prLink,
		title:         ufmt.Sprintf("Approve Application #%d for Bounty #%d", applicationID, bountyID),
		description:   ufmt.Sprintf("Review PR: %s\nApplicant: %s", prLink, applicant),
	}
}

// Title returns proposal title
func (p *ClaimBountyProposal) Title() string {
	return p.title
}

// Body returns proposal's body
func (p *ClaimBountyProposal) Body() string {
	return p.description
}

// VotingPeriod returns the period where votes are allowed after proposal creation
func (p *ClaimBountyProposal) VotingPeriod() time.Duration {
	// 7 days voting period
	return 7 * 24 * time.Hour
}

// Tally counts votes and determines if proposal is ready to execute
// Returns true when all validators have voted (regardless of outcome)
func (p *ClaimBountyProposal) Tally(ctx commondao.VotingContext) (bool, error) {
	totalMembers := ctx.Members.Size()
	if totalMembers == 0 {
		return false, ufmt.Errorf("no members in DAO")
	}

	totalVotes := ctx.VotingRecord.Size()

	// Return true when all validators have voted
	// This allows Execute to be called and handle approval/rejection
	if totalVotes == totalMembers {
		return true, nil
	}

	// Not ready yet - waiting for more votes
	return false, nil
}

// Execute executes the proposal after all votes are in
// Determines approval or rejection based on vote counts
func (p *ClaimBountyProposal) Execute(_ realm) error {
	app := GetApplication(p.ApplicationID)
	if app == nil {
		return ufmt.Errorf("application not found")
	}

	bounty := GetBounty(p.BountyID)
	if bounty == nil {
		return ufmt.Errorf("bounty not found")
	}

	if bounty.IsClaimed {
		return ufmt.Errorf("bounty already claimed")
	}

	// Get vote counts from the DAO proposal
	proposal := app.DAO.ActiveProposals().Get(app.ProposalID)
	if proposal == nil {
		return ufmt.Errorf("proposal not found")
	}

	yesCount := proposal.VotingRecord().VoteCount(commondao.ChoiceYes)
	noCount := proposal.VotingRecord().VoteCount(commondao.ChoiceNo)
	totalMembers := app.DAO.Members().Size()

	// Check if unanimous approval (all YES, no NO)
	if yesCount == totalMembers && noCount == 0 {
		// Approve and transfer funds
		app.Status = StatusApproved

		bounty.IsClaimed = true
		bounty.Claimer = p.Applicant
		bounty.ClaimedAt = time.Now()

		// Calculate reward split: 5% to validators, 95% to applicant
		validatorReward := (bounty.Amount * validatorRewardPercent) / 100
		applicantReward := bounty.Amount - validatorReward

		// Split validator reward equally among all validators who voted
		rewardPerValidator := validatorReward / int64(totalMembers)

		// Transfer rewards
		bnk := banker.NewBanker(banker.BankerTypeRealmSend)

		// Pay each validator their share
		app.DAO.Members().IterateByOffset(0, totalMembers, func(member address) bool {
			validatorPayout := chain.Coins{chain.Coin{Denom: "ugnot", Amount: rewardPerValidator}}
			bnk.SendCoins(pkgAddr, member, validatorPayout)
			return false
		})

		// Pay the applicant the remaining 95%
		applicantPayout := chain.Coins{chain.Coin{Denom: "ugnot", Amount: applicantReward}}
		bnk.SendCoins(pkgAddr, p.Applicant, applicantPayout)
	} else {
		// Reject - not unanimous
		app.Status = StatusRejected
	}

	return nil
}
