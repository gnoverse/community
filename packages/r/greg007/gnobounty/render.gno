package gnobounty

import (
	"strconv"

	"gno.land/p/moul/md"
	"gno.land/p/moul/txlink"
	"gno.land/p/nt/commondao"
	"gno.land/p/nt/ufmt"
)

// ListBounties returns all active bounties
func ListBounties() string {
	minSend := ufmt.Sprintf("%dugnot", minimumBounty)
	createBountyLink := txlink.NewLink("CreateBounty").
		AddArgs(
			"title", "",
			"issueURL", "",
			"description", "",
		).
		SetSend(minSend).
		URL()

	output := "# GnoBounty - Decentralized Bounty System\n\n"

	output += "## 🎯 Quick Actions\n\n"
	output += md.Link("💰 Create a new bounty", createBountyLink)
	output += ufmt.Sprintf(" _(minimum reward: %s)_", minSend)
	output += " | "
	output += md.Link("📋 View All Validators", "/"+pkgPath+":validators")
	output += " | "
	output += md.Link("🏆 Leaderboard", "/"+pkgPath+":leaderboard")
	output += "\n\n"

	// Add validator stats
	activeValidatorCount := GetActiveValidatorCount()
	output += ufmt.Sprintf("**Active Validators:** %d | **Total Bounties:** %d\n\n", activeValidatorCount, bountyCount)

	output += "---\n\n"
	output += "## 💎 Active Bounties\n\n"
	output += "**How to apply:** To apply to a bounty, you need to give your **MERGED PR** (important) URL in the transaction. You also need to write your Gno address in the description of your PR to verify your identity. If no address is written, the bounty can be refused.\n\n"

	if bountyCount == 0 {
		output += "No bounties available"
		return output
	}

	bounties.Iterate("", "", func(key string, value interface{}) bool {
		bounty := value.(*Bounty)
		if !bounty.IsClaimed {
			output += ufmt.Sprintf("## Bounty #%d: %s\n", bounty.ID, bounty.Title)
			output += ufmt.Sprintf("**Issue:** %s\n", bounty.IssueURL)
			output += ufmt.Sprintf("**Description:** %s\n", bounty.Description)
			output += ufmt.Sprintf("**Reward:** %d ugnot (%.2f GNOT)\n", bounty.Amount, float64(bounty.Amount)/1000000.0)
			output += ufmt.Sprintf("**Creator:** %s\n", bounty.Creator)
			output += ufmt.Sprintf("**Created:** %s\n\n", bounty.CreatedAt.Format("2006-01-02 15:04:05"))

			// Add apply button for this bounty
			applyLink := txlink.NewLink("ApplyForBounty").
				AddArgs(
					"bountyID", ufmt.Sprintf("%d", bounty.ID),
					"prLink", "",
				).
				URL()
			output += md.Link("📝 Apply for this bounty", applyLink)
			output += " | "

			// Add view details link
			detailsPath := ufmt.Sprintf("/%s:%d", pkgPath, bounty.ID)
			output += md.Link("🔍 View details", detailsPath)
			output += "\n\n"
		}
		return false
	})

	return output
}

// GetBountyDetails returns detailed information about a specific bounty
func GetBountyDetails(id uint64) string {
	bounty := GetBounty(id)
	if bounty == nil {
		return "Bounty not found"
	}

	output := ufmt.Sprintf("# Bounty #%d: %s\n\n", bounty.ID, bounty.Title)
	output += ufmt.Sprintf("**Issue URL:** %s\n", bounty.IssueURL)
	output += ufmt.Sprintf("**Description:** %s\n", bounty.Description)
	output += ufmt.Sprintf("**Reward:** %d ugnot (%.2f GNOT)\n", bounty.Amount, float64(bounty.Amount)/1000000.0)
	output += ufmt.Sprintf("**Creator:** %s\n", bounty.Creator)
	output += ufmt.Sprintf("**Created:** %s\n", bounty.CreatedAt.Format("2006-01-02 15:04:05"))

	if bounty.IsClaimed {
		output += ufmt.Sprintf("**Status:** CLAIMED\n")
		output += ufmt.Sprintf("**Claimed by:** %s\n", bounty.Claimer)
		output += ufmt.Sprintf("**Claimed at:** %s\n", bounty.ClaimedAt.Format("2006-01-02 15:04:05"))
	} else {
		output += ufmt.Sprintf("**Status:** OPEN\n\n")
		output += "**How to apply:** To apply to a bounty, you need to give your **MERGED PR** (important) URL in the transaction. You also need to write your Gno address in the description of your PR to verify your identity. If no address is written, the bounty can be refused.\n\n"

		// Add apply button
		applyLink := txlink.NewLink("ApplyForBounty").
			AddArgs(
				"bountyID", ufmt.Sprintf("%d", id),
				"prLink", "",
			).
			URL()
		output += md.Link("Apply for this bounty", applyLink) + "\n\n"

		// Show existing applications
		apps := GetApplicationsForBounty(id)
		if len(apps) > 0 {
			output += "### Applications\n\n"
			for _, app := range apps {
				output += renderApplication(app)
			}
		}
	}

	return output
}

// renderApplication renders a single application
func renderApplication(app *Application) string {
	output := ufmt.Sprintf("**Application #%d**\n", app.ID)
	output += ufmt.Sprintf("- Applicant: %s\n", app.Applicant)
	output += ufmt.Sprintf("- PR Link: %s\n", app.PRLink)
	output += ufmt.Sprintf("- Applied: %s\n", app.AppliedAt.Format("2006-01-02 15:04:05"))

	statusStr := "PENDING"
	if app.Status == StatusApproved {
		statusStr = "APPROVED"
	} else if app.Status == StatusRejected {
		statusStr = "REJECTED"
	}
	output += ufmt.Sprintf("- Status: %s\n", statusStr)

	// Show DAO voting information if DAO exists
	if app.DAO != nil {
		output += ufmt.Sprintf("- Proposal ID: %d\n", app.ProposalID)

		// Get proposal and show detailed validator voting status
		proposal := app.DAO.ActiveProposals().Get(app.ProposalID)
		if proposal != nil {
			// Get vote counts
			yesCount := proposal.VotingRecord().VoteCount(commondao.ChoiceYes)
			noCount := proposal.VotingRecord().VoteCount(commondao.ChoiceNo)
			abstainCount := proposal.VotingRecord().VoteCount(commondao.ChoiceAbstain)
			totalVotes := proposal.VotingRecord().Size()
			totalMembers := app.DAO.Members().Size()

			output += ufmt.Sprintf("\n**Voting Progress:** %d/%d validators have voted\n", totalVotes, totalMembers)
			output += ufmt.Sprintf("- ✅ YES: %d\n", yesCount)
			output += ufmt.Sprintf("- ❌ NO: %d\n", noCount)
			output += ufmt.Sprintf("- 🤷 ABSTAIN: %d\n", abstainCount)
			output += ufmt.Sprintf("- ⏳ PENDING: %d\n", totalMembers-totalVotes)
		}
	}

	// Add vote buttons for validators if application is still pending
	if app.Status == StatusPending && app.DAO != nil {
		output += "\n**Vote on this application:**\n"

		// Add vote buttons (yes/no/abstain)
		yesLink := txlink.NewLink("Vote").
			AddArgs(
				"applicationID", ufmt.Sprintf("%d", app.ID),
				"vote", "yes",
			).
			URL()
		noLink := txlink.NewLink("Vote").
			AddArgs(
				"applicationID", ufmt.Sprintf("%d", app.ID),
				"vote", "no",
			).
			URL()
		abstainLink := txlink.NewLink("Vote").
			AddArgs(
				"applicationID", ufmt.Sprintf("%d", app.ID),
				"vote", "abstain",
			).
			URL()

		output += md.Link("✅ Approve", yesLink) + " | " + md.Link("❌ Reject", noLink) + " | " + md.Link("🤷 Abstain", abstainLink) + "\n"
		output += "\n_Note: Only assigned validators can vote on this application._\n"
	}
	output += "\n"

	return output
}

// RenderMyVotes shows pending votes for a validator
func RenderMyVotes(validatorAddr address) string {
	if !IsValidator(validatorAddr) {
		return "You are not a registered validator"
	}

	output := "# My Pending Votes\n\n"

	apps := GetApplicationsForValidator(validatorAddr)
	pendingCount := 0

	for _, app := range apps {
		if app.Status == StatusPending {
			bounty := GetBounty(app.BountyID)
			if bounty == nil {
				continue
			}

			pendingCount++
			output += ufmt.Sprintf("## Application #%d for Bounty #%d\n", app.ID, app.BountyID)
			output += ufmt.Sprintf("**Bounty:** %s\n", bounty.Description)
			output += ufmt.Sprintf("**Bounty Reward:** %d ugnot (%.2f GNOT)\n", bounty.Amount, float64(bounty.Amount)/1000000.0)
			output += ufmt.Sprintf("**Applicant:** %s\n", app.Applicant)
			output += ufmt.Sprintf("**PR Link:** %s\n", app.PRLink)

			// Show DAO proposal details
			if app.DAO != nil {
				output += ufmt.Sprintf("**Proposal ID:** %d\n", app.ProposalID)

				// Get proposal and show vote count
				proposal := app.DAO.ActiveProposals().Get(app.ProposalID)
				if proposal != nil {
					voteCount := 0
					proposal.VotingRecord().Iterate(0, 0, false, func(v commondao.Vote) bool {
						voteCount++
						return false
					})
					output += ufmt.Sprintf("**Votes Submitted:** %d/%d\n", voteCount, app.DAO.Members().Size())
				}
			}
			output += "\n"

			// Add vote buttons (yes/no/abstain)
			yesLink := txlink.NewLink("Vote").
				AddArgs(
					"applicationID", ufmt.Sprintf("%d", app.ID),
					"vote", "yes",
				).
				URL()
			noLink := txlink.NewLink("Vote").
				AddArgs(
					"applicationID", ufmt.Sprintf("%d", app.ID),
					"vote", "no",
				).
				URL()
			abstainLink := txlink.NewLink("Vote").
				AddArgs(
					"applicationID", ufmt.Sprintf("%d", app.ID),
					"vote", "abstain",
				).
				URL()

			output += md.Link("Approve (Yes)", yesLink) + " | " + md.Link("Reject (No)", noLink) + " | " + md.Link("Abstain", abstainLink) + "\n\n"
			output += "---\n\n"
		}
	}

	if pendingCount == 0 {
		output += "No pending votes"
	}

	return output
}

// RenderValidators shows all validators
func RenderValidators() string {
	return ListValidators()
}

// Render implements the Render() method for the realm
func Render(path string) string {
	if path == "" {
		return ListBounties()
	}

	// Check for special paths
	if path == "validators" {
		return RenderValidators()
	}

	if path == "leaderboard" {
		return RenderLeaderboard()
	}

	// Parse bounty ID from path
	id, err := strconv.Atoi(path)
	if err != nil {
		return ufmt.Sprintf("Invalid path. Use /%s for bounties or /%s:validators for validators list", pkgPath, pkgPath)
	}

	return GetBountyDetails(uint64(id))
}
