package gnopendao

import (
	"chain/runtime"

	"gno.land/p/nt/commondao"
	"gno.land/p/nt/ufmt"
)

// ProposeApproveCollection - Create a proposal to approve a new collection
func ProposeApproveCollection(_ realm, collectionAddr address, collectionName string, reason string) uint64 {
	caller := runtime.PreviousRealm().Address()

	if !IsDAOMember(caller) {
		panic("only DAO members can create proposals")
	}

	propDef := newCollectionProposal(PROPOSAL_TYPE_APPROVE_COLLECTION, collectionAddr, collectionName, reason)

	proposal, err := marketplaceDAO.Propose(caller, propDef)
	if err != nil {
		panic("failed to create proposal: " + err.Error())
	}

	return proposal.ID()
}

// ProposeRemoveCollection - Create a proposal to remove a collection
func ProposeRemoveCollection(_ realm, collectionAddr address, collectionName string, reason string) uint64 {
	caller := runtime.PreviousRealm().Address()

	if !IsDAOMember(caller) {
		panic("only DAO members can create proposals")
	}

	propDef := newCollectionProposal(PROPOSAL_TYPE_REMOVE_COLLECTION, collectionAddr, collectionName, reason)

	proposal, err := marketplaceDAO.Propose(caller, propDef)
	if err != nil {
		panic("failed to create proposal: " + err.Error())
	}

	return proposal.ID()
}

// ProposeUpdateFees - Create a proposal to update marketplace fees
func ProposeUpdateFees(_ realm, newFeeBasisPoints int64, reason string) uint64 {
	caller := runtime.PreviousRealm().Address()

	if !IsDAOMember(caller) {
		panic("only DAO members can create proposals")
	}

	if newFeeBasisPoints < 0 || newFeeBasisPoints > 1000 {
		panic("fees must be between 0 and 1000 basis points (0-10%)")
	}

	propDef := newFeesProposal(newFeeBasisPoints, reason)

	proposal, err := marketplaceDAO.Propose(caller, propDef)
	if err != nil {
		panic("failed to create proposal: " + err.Error())
	}

	return proposal.ID()
}

// ProposeWithdrawTreasury - Create a proposal to withdraw funds from treasury
func ProposeWithdrawTreasury(_ realm, amount int64, recipient address, reason string) uint64 {
	caller := runtime.PreviousRealm().Address()

	if !IsDAOMember(caller) {
		panic("only DAO members can create proposals")
	}

	if amount <= 0 {
		panic("amount must be positive")
	}

	if !recipient.IsValid() {
		panic("invalid recipient address")
	}

	currentBalance := GetBalance()
	if amount > currentBalance {
		panic(ufmt.Sprintf("insufficient treasury balance (available: %d ugnot)", currentBalance))
	}

	propDef := NewTreasuryProposal(amount, recipient, reason)

	proposal, err := marketplaceDAO.Propose(caller, propDef)
	if err != nil {
		panic("failed to create proposal: " + err.Error())
	}

	return proposal.ID()
}

// ProposeForceCancelListing - Create a proposal to force cancel a listing
func ProposeForceCancelListing(_ realm, listingId int, reason string) uint64 {
	caller := runtime.PreviousRealm().Address()

	if !IsDAOMember(caller) {
		panic("only DAO members can create proposals")
	}

	// Verify listing exists and is active
	listing := getListing(listingId)
	if listing == nil {
		panic("listing not found")
	}

	if !listing.Active {
		panic("listing is already inactive")
	}

	propDef := NewForceCancelListingProposal(listingId, reason)

	proposal, err := marketplaceDAO.Propose(caller, propDef)
	if err != nil {
		panic("failed to create proposal: " + err.Error())
	}

	return proposal.ID()
}

// Vote - Vote on a proposal (yes or no)
func Vote(_ realm, proposalID uint64, choice string) string {
	caller := runtime.PreviousRealm().Address()

	var voteChoice commondao.VoteChoice
	if choice == "yes" {
		voteChoice = commondao.ChoiceYes
	} else if choice == "no" {
		voteChoice = commondao.ChoiceNo
	} else {
		panic("choice must be 'yes' or 'no'")
	}

	// Use DAO's Vote method - it handles all validations automatically
	err := marketplaceDAO.Vote(
		caller,
		proposalID,
		voteChoice,
		"", // reason (optional)
	)
	if err != nil {
		panic("vote failed: " + err.Error())
	}

	return "Vote recorded: " + choice
}

// TallyProposal - Execute a proposal after voting period
func TallyProposal(_ realm, proposalID uint64) string {
	err := marketplaceDAO.Execute(proposalID)
	if err != nil {
		panic("execution failed: " + err.Error())
	}

	return ufmt.Sprintf("Proposal %d executed successfully", proposalID)
}

// GetProposalInfo - Get information about a proposal
func GetProposalInfo(proposalID uint64) string {
	proposal := marketplaceDAO.ActiveProposals().Get(proposalID)
	if proposal == nil {
		return "Proposal not found"
	}

	yesVotes := 0
	noVotes := 0

	proposal.VotingRecord().Iterate(0, proposal.VotingRecord().Size(), false, func(v commondao.Vote) bool {
		if v.Choice == commondao.ChoiceYes {
			yesVotes++
		} else if v.Choice == commondao.ChoiceNo {
			noVotes++
		}
		return false
	})

	output := ufmt.Sprintf(`Proposal #%d
Title: %s
Body: %s
Yes Votes: %d
No Votes: %d
Total Votes: %d
Voting Ended: %t`,
		proposalID,
		proposal.Definition().Title(),
		proposal.Definition().Body(),
		yesVotes,
		noVotes,
		yesVotes+noVotes,
		proposal.HasVotingDeadlinePassed(),
	)

	return output
}

// GetAllActiveProposals - Get all active proposals
func GetAllActiveProposals() string {
	proposals := marketplaceDAO.ActiveProposals()

	if proposals.Size() == 0 {
		return "No active proposals"
	}

	output := "=== Active Proposals ===\n\n"

	proposals.Iterate(0, proposals.Size(), false, func(p *commondao.Proposal) bool {
		// Count votes
		yesVotes := 0
		noVotes := 0
		p.VotingRecord().Iterate(0, p.VotingRecord().Size(), false, func(v commondao.Vote) bool {
			if v.Choice == commondao.ChoiceYes {
				yesVotes++
			} else if v.Choice == commondao.ChoiceNo {
				noVotes++
			}
			return false
		})

		// Get voting deadline as Unix timestamp
		deadlineUnix := p.VotingDeadline().Unix()
		votingEnded := p.HasVotingDeadlinePassed()

		output += ufmt.Sprintf("ID: %d | %s | Yes: %d | No: %d | Deadline: %d | Ended: %t\n",
			p.ID(),
			p.Definition().Title(),
			yesVotes,
			noVotes,
			deadlineUnix,
			votingEnded)
		return false
	})

	return output
}

// GetAllFinishedProposals - Get all finished proposals
func GetAllFinishedProposals() string {
	proposals := marketplaceDAO.FinishedProposals()

	if proposals.Size() == 0 {
		return "No finished proposals"
	}

	output := "=== Finished Proposals ===\n\n"

	proposals.Iterate(0, proposals.Size(), false, func(p *commondao.Proposal) bool {
		// Count votes
		yesVotes := 0
		noVotes := 0
		p.VotingRecord().Iterate(0, p.VotingRecord().Size(), false, func(v commondao.Vote) bool {
			if v.Choice == commondao.ChoiceYes {
				yesVotes++
			} else if v.Choice == commondao.ChoiceNo {
				noVotes++
			}
			return false
		})

		output += ufmt.Sprintf("ID: %d | %s | Yes: %d | No: %d | Status: %s\n",
			p.ID(),
			p.Definition().Title(),
			yesVotes,
			noVotes,
			string(p.Status()))
		return false
	})

	return output
}
