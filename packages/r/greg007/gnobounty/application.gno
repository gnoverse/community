package gnobounty

import (
	"chain/runtime"
	"time"

	"gno.land/p/nt/commondao"
	"gno.land/p/nt/ufmt"
)

// ApplyForBounty allows a user to apply for a bounty with their merged PR link
// This creates an application with a private DAO for 3 random validators to vote
func ApplyForBounty(_ realm, bountyID uint64, prLink string) uint64 {
	caller := runtime.OriginCaller()

	// Validate inputs
	if prLink == "" {
		panic("PR link cannot be empty")
	}

	// Check bounty exists and is not claimed
	bounty := GetBounty(bountyID)
	if bounty == nil {
		panic("bounty not found")
	}

	if bounty.IsClaimed {
		panic("bounty already claimed")
	}

	// Check if there are enough validators
	activeValidatorCount := GetActiveValidatorCount()
	if activeValidatorCount < validatorsPerDAO {
		panic(ufmt.Sprintf("not enough validators: need %d, have %d", validatorsPerDAO, activeValidatorCount))
	}

	// Check if user already has a pending application for this bounty
	applications.Iterate("", "", func(key string, value interface{}) bool {
		app := value.(*Application)
		if app.BountyID == bountyID && app.Applicant == caller && app.Status == StatusPending {
			panic("you already have a pending application for this bounty")
		}
		return false
	})

	// Select 3 random validators for this application
	selectedValidators := selectRandomValidators(applicationCount+1, validatorsPerDAO)

	// Create the DAO for this application
	applicationCount++
	daoName := ufmt.Sprintf("Bounty #%d Application #%d Review DAO", bountyID, applicationCount)
	daoDesc := ufmt.Sprintf("Private DAO to review application for bounty #%d", bountyID)

	// Create DAO with selected validators as members
	// DisableVotingDeadlineCheck allows immediate execution after votes
	dao := commondao.New(
		commondao.WithID(applicationCount),
		commondao.WithName(daoName),
		commondao.WithDescription(daoDesc),
		commondao.DisableVotingDeadlineCheck(),
	)

	// Add selected validators as members
	for _, validatorAddr := range selectedValidators {
		dao.Members().Add(validatorAddr)
	}

	// Create a proposal in the DAO to approve this application BEFORE creating the Application struct
	proposalDef := NewClaimBountyProposal(bountyID, applicationCount, caller, prLink)
	proposal := dao.MustPropose(caller, proposalDef)

	// Create the application with the correct proposalID from the start
	application := &Application{
		ID:         applicationCount,
		BountyID:   bountyID,
		Applicant:  caller,
		PRLink:     prLink,
		AppliedAt:  time.Now(),
		Status:     StatusPending,
		DAO:        dao,
		ProposalID: proposal.ID(),
	}

	// Store application
	applications.Set(ufmt.Sprintf("%d", applicationCount), application)

	return applicationCount
}

// Vote allows a selected validator to vote on an application via the DAO
func Vote(_ realm, applicationID uint64, vote string) {
	caller := runtime.OriginCaller()

	// Check if caller is a validator
	if !IsValidator(caller) {
		panic("only validators can vote")
	}

	// Get application
	app := GetApplication(applicationID)
	if app == nil {
		panic("application not found")
	}

	if app.Status != StatusPending {
		panic("application is no longer pending")
	}

	// Check if caller is a member of this application's DAO
	if !app.DAO.Members().Has(caller) {
		panic("you are not a validator for this application")
	}

	// Get the proposal
	proposal := app.DAO.ActiveProposals().Get(app.ProposalID)
	if proposal == nil {
		panic("proposal not found")
	}

	// Convert string vote to VoteChoice
	var voteChoice commondao.VoteChoice
	switch vote {
	case "yes", "true", "approve":
		voteChoice = commondao.ChoiceYes
	case "no", "false", "reject":
		voteChoice = commondao.ChoiceNo
	case "abstain":
		voteChoice = commondao.ChoiceAbstain
	default:
		panic("invalid vote: must be 'yes', 'no', or 'abstain'")
	}

	// Vote on the proposal using CommonDAO's Vote method
	// This method validates membership, deadline, and vote choice
	err := app.DAO.Vote(caller, app.ProposalID, voteChoice, "")
	if err != nil {
		panic(err)
	}

	// Record vote locally
	app.Votes = append(app.Votes, VoteRecord{
		Voter:  caller,
		Choice: voteChoice,
	})

	// Try to execute the proposal
	// Tally() will return true when all validators have voted
	// Execute() will handle both approval and rejection
	proposal = app.DAO.ActiveProposals().Get(app.ProposalID)
	if proposal != nil {
		totalMembers := app.DAO.Members().Size()
		totalVotes := proposal.VotingRecord().Size()

		// If all validators have voted, execute to finalize
		if totalVotes == totalMembers {
			err = app.DAO.Execute(app.ProposalID)
			// Ignore errors - proposal might already be executed or failed
			// The status will be updated in Execute() regardless
		}
	}
}

// GetApplicationsForBounty returns all applications for a specific bounty
func GetApplicationsForBounty(bountyID uint64) []*Application {
	apps := make([]*Application, 0)

	applications.Iterate("", "", func(key string, value interface{}) bool {
		app := value.(*Application)
		if app.BountyID == bountyID {
			apps = append(apps, app)
		}
		return false
	})

	return apps
}

// GetApplicationsForValidator returns all applications assigned to a validator
func GetApplicationsForValidator(validatorAddr address) []*Application {
	apps := make([]*Application, 0)

	applications.Iterate("", "", func(key string, value interface{}) bool {
		app := value.(*Application)
		// Check if validator is a member of the application's DAO
		if app.DAO != nil && app.Status == StatusPending && app.DAO.Members().Has(validatorAddr) {
			apps = append(apps, app)
		}
		return false
	})

	return apps
}
