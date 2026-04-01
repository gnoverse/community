package registrydao

import (
	"strconv"
	"strings"

	"gno.land/p/leon/svgbtn"
	"gno.land/p/moul/txlink"
	"gno.land/p/nt/commondao"
	"gno.land/p/nt/ufmt"
)

func Render(path string) string {
	if path == "" {
		return renderHome()
	}

	if path == "proposals" {
		return renderProposals()
	}

	if path == "archive" {
		return renderArchive()
	}

	if strings.HasPrefix(path, "proposal/") {
		idStr := strings.TrimPrefix(path, "proposal/")
		id, _ := strconv.Atoi(idStr)
		return renderProposal(uint64(id))
	}

	if strings.HasPrefix(path, "archived/") {
		idStr := strings.TrimPrefix(path, "archived/")
		id, _ := strconv.Atoi(idStr)
		return renderArchivedProposal(uint64(id))
	}

	if strings.HasPrefix(path, "collection/") {
		addrStr := strings.TrimPrefix(path, "collection/")
		addr := address(addrStr)
		return renderCollection(addr)
	}

	return "Page not found"
}

func renderHome() string {
	output := "# NFT Registry\n\n"
	output += "Decentralized NFT Collection Registry with DAO Governance\n\n"
	output += "---\n\n"

	output += "## Statistics\n\n"
	output += ufmt.Sprintf("- Total registered collections: %d\n", GetTotalCollections())
	output += ufmt.Sprintf("- Verified collections: %d\n\n", GetVerifiedCount())

	output += "---\n\n"

	// DAO Section
	output += "## DAO Governance\n\n"
	output += ufmt.Sprintf("**Total DAO Members:** %d\n\n", GetTotalRegistryMembers())

	activeProposals := registryDAO.ActiveProposals()
	if activeProposals.Size() > 0 {
		output += ufmt.Sprintf("**Active Proposals:** %d\n\n", activeProposals.Size())
		output += "[View all proposals](/r/pierre115/registrydao:proposals)\n\n"
	} else {
		output += "**Active Proposals:** 0\n\n"
		output += "[View proposals](/r/pierre115/registrydao:proposals) | "
	}

	finishedProposals := registryDAO.FinishedProposals()
	output += ufmt.Sprintf("[View archive (%d)](/r/pierre115/registrydao:archive)\n\n", finishedProposals.Size())
	output += "---\n\n"

	// Vote Join button
	linkjoin := txlink.NewLink("JoinRegistryDAO").
		URL()
	output += svgbtn.SuccessButton(100, 30, "Join DAO", linkjoin) + "\n\n"
	output += "---\n\n"

	// Collections list
	output += "## Registered Collections\n\n"

	hasCollections := false
	collections.Iterate("", "", func(key string, value interface{}) bool {
		hasCollections = true
		info := value.(*CollectionInfo)
		output += renderCollectionPreview(info)
		return false
	})

	if !hasCollections {
		output += "No collections registered yet.\n\n"
	}

	return output
}

func renderCollectionPreview(info *CollectionInfo) string {
	output := ufmt.Sprintf("### %s (%s)\n\n", info.Name, info.Symbol)

	if info.Verified {
		output += "Status: VERIFIED\n\n"
	} else {
		output += "Status: Not verified\n\n"
	}

	output += ufmt.Sprintf("Category: %s\n\n", info.Category)
	output += ufmt.Sprintf("[View details](/r/pierre115/registrydao:collection/%s)\n\n", info.Address.String())
	output += "---\n\n"

	return output
}

func renderCollection(addr address) string {
	info := GetCollection(addr)
	if info == nil {
		return "# Collection not found"
	}

	output := ufmt.Sprintf("# %s\n\n", info.Name)

	if info.Verified {
		output += "**Status:** VERIFIED\n\n"
	} else {
		output += "**Status:** Not verified\n\n"
	}

	output += "## Details\n\n"
	output += ufmt.Sprintf("**Symbol:** %s\n\n", info.Symbol)
	output += ufmt.Sprintf("**Address:** %s\n\n", info.Address.String())
	output += ufmt.Sprintf("**Creator:** %s\n\n", info.Creator.String())
	output += ufmt.Sprintf("**Category:** %s\n\n", info.Category)
	output += ufmt.Sprintf("**Description:** %s\n\n", info.Description)

	if info.ExternalURL != "" {
		output += ufmt.Sprintf("**External URL:** %s\n\n", info.ExternalURL)
	}

	output += ufmt.Sprintf("**Registered at block:** %d\n\n", info.RegisteredAt)
	output += ufmt.Sprintf("**Supports onchain metadata:** %t\n\n", info.SupportsMetadata)

	output += "[Back to registry](/r/pierre115/registrydao)\n"

	return output
}

func renderProposals() string {
	output := "# Active Registry Proposals\n\n"

	proposals := registryDAO.ActiveProposals()

	if proposals.Size() == 0 {
		output += "No active proposals at the moment.\n\n"
		output += "DAO members can create proposals to:\n"
		output += "- Verify collections\n"
		output += "- Unverify collections\n\n"
		output += "[Back](/r/pierre115/registrydao)\n"
		return output
	}

	proposals.Iterate(0, proposals.Size(), false, func(p *commondao.Proposal) bool {
		output += renderProposalPreview(p)
		return false
	})

	output += "\n[View archive](/r/pierre115/registrydao:archive) | [Back](/r/pierre115/registrydao)\n"

	return output
}

func renderProposalPreview(p *commondao.Proposal) string {
	output := ufmt.Sprintf("## Proposal #%d\n\n", p.ID())
	output += ufmt.Sprintf("**%s**\n\n", p.Definition().Title())

	// Count votes
	yesVotes := 0
	noVotes := 0
	p.VotingRecord().Iterate(0, p.VotingRecord().Size(), false, func(v commondao.Vote) bool {
		if string(v.Choice) == "yes" || string(v.Choice) == "YES" {
			yesVotes++
		} else if string(v.Choice) == "no" || string(v.Choice) == "NO" {
			noVotes++
		}
		return false
	})

	output += ufmt.Sprintf("**Yes:** %d | **No:** %d | **Total:** %d\n\n", yesVotes, noVotes, yesVotes+noVotes)

	if p.HasVotingDeadlinePassed() {
		output += "Status: Voting ended\n\n"
	} else {
		output += "Status: Voting open\n\n"
	}

	output += ufmt.Sprintf("[View and Vote](/r/pierre115/registrydao:proposal/%d)\n\n", p.ID())
	output += "---\n\n"

	return output
}

func renderProposal(proposalID uint64) string {
	proposal := registryDAO.ActiveProposals().Get(proposalID)
	if proposal == nil {
		return "# Proposal not found"
	}

	output := ufmt.Sprintf("# Proposal #%d\n\n", proposalID)
	output += ufmt.Sprintf("## %s\n\n", proposal.Definition().Title())
	output += ufmt.Sprintf("%s\n\n", proposal.Definition().Body())

	output += "---\n\n"

	// Vote counts
	yesVotes := 0
	noVotes := 0
	totalVotes := 0

	proposal.VotingRecord().Iterate(0, proposal.VotingRecord().Size(), false, func(v commondao.Vote) bool {
		if string(v.Choice) == "yes" || string(v.Choice) == "YES" {
			yesVotes++
		} else if string(v.Choice) == "no" || string(v.Choice) == "NO" {
			noVotes++
		}
		totalVotes++
		return false
	})

	output += "## Current Results\n\n"
	output += ufmt.Sprintf("- **Yes votes:** %d\n", yesVotes)
	output += ufmt.Sprintf("- **No votes:** %d\n", noVotes)
	output += ufmt.Sprintf("- **Total votes:** %d\n", totalVotes)

	totalMembers := GetTotalRegistryMembers()
	quorumRequired := int(float64(totalMembers) * REGISTRY_QUORUM)
	output += ufmt.Sprintf("- **Quorum required:** %d/%d votes\n\n", totalVotes, quorumRequired)

	if proposal.HasVotingDeadlinePassed() {
		output += "**Voting period has ended**\n\n"
	} else {
		output += "**Voting is open**\n\n"

		output += "---\n\n"
		output += "## Cast Your Vote\n\n"

		// Vote YES button
		linkyes := txlink.NewLink("VoteRegistry").
			AddArgs("proposalID", ufmt.Sprintf("%d", proposalID)).
			AddArgs("choice", "yes").
			URL()
		output += svgbtn.SuccessButton(100, 30, "YES", linkyes) + "\n\n"

		// Vote NO button
		linkno := txlink.NewLink("VoteRegistry").
			AddArgs("proposalID", ufmt.Sprintf("%d", proposalID)).
			AddArgs("choice", "no").
			URL()
		output += svgbtn.DangerButton(100, 30, "NO", linkno) + "\n\n"
	}

	output += "---\n\n"
	output += "[Back to proposals](/r/pierre115/registrydao:proposals) | [Home](/r/pierre115/registrydao)\n"

	return output
}

func renderArchive() string {
	output := "# Proposal Archive\n\n"

	finishedProposals := registryDAO.FinishedProposals()

	if finishedProposals.Size() == 0 {
		output += "No finished proposals yet.\n\n"
		output += "[Back](/r/pierre115/registrydao)\n"
		return output
	}

	output += ufmt.Sprintf("**Total archived proposals:** %d\n\n", finishedProposals.Size())
	output += "---\n\n"

	finishedProposals.Iterate(0, finishedProposals.Size(), false, func(p *commondao.Proposal) bool {
		output += renderArchivedProposalPreview(p)
		return false
	})

	output += "\n[Back](/r/pierre115/registrydao)\n"

	return output
}

func renderArchivedProposalPreview(p *commondao.Proposal) string {
	output := ufmt.Sprintf("## Proposal #%d - %s\n\n", p.ID(), string(p.Status()))
	output += ufmt.Sprintf("**%s**\n\n", p.Definition().Title())

	// Count final votes
	yesVotes := 0
	noVotes := 0
	p.VotingRecord().Iterate(0, p.VotingRecord().Size(), false, func(v commondao.Vote) bool {
		if string(v.Choice) == "yes" || string(v.Choice) == "YES" {
			yesVotes++
		} else if string(v.Choice) == "no" || string(v.Choice) == "NO" {
			noVotes++
		}
		return false
	})

	output += ufmt.Sprintf("**Final Result:** Yes: %d | No: %d\n\n", yesVotes, noVotes)

	statusLabel := "PASSED"
	if p.Status() == "failed" {
		statusLabel = "FAILED"
	}
	output += ufmt.Sprintf("**Status:** %s\n\n", statusLabel)

	if p.StatusReason() != "" {
		output += ufmt.Sprintf("**Reason:** %s\n\n", p.StatusReason())
	}

	output += ufmt.Sprintf("[View details](/r/pierre115/registrydao:archived/%d)\n\n", p.ID())
	output += "---\n\n"

	return output
}

func renderArchivedProposal(proposalID uint64) string {
	proposal := registryDAO.FinishedProposals().Get(proposalID)
	if proposal == nil {
		return "# Archived proposal not found"
	}

	output := ufmt.Sprintf("# Proposal #%d - %s\n\n", proposalID, string(proposal.Status()))
	output += ufmt.Sprintf("## %s\n\n", proposal.Definition().Title())
	output += ufmt.Sprintf("%s\n\n", proposal.Definition().Body())

	output += "---\n\n"

	// Final vote counts
	yesVotes := 0
	noVotes := 0
	totalVotes := 0

	proposal.VotingRecord().Iterate(0, proposal.VotingRecord().Size(), false, func(v commondao.Vote) bool {
		if string(v.Choice) == "yes" || string(v.Choice) == "YES" {
			yesVotes++
		} else if string(v.Choice) == "no" || string(v.Choice) == "NO" {
			noVotes++
		}
		totalVotes++
		return false
	})

	output += "## Final Results\n\n"
	output += ufmt.Sprintf("- **Yes votes:** %d\n", yesVotes)
	output += ufmt.Sprintf("- **No votes:** %d\n", noVotes)
	output += ufmt.Sprintf("- **Total votes:** %d\n", totalVotes)

	totalMembers := GetTotalRegistryMembers()
	quorumRequired := int(float64(totalMembers) * REGISTRY_QUORUM)
	output += ufmt.Sprintf("- **Quorum required:** %d/%d votes\n\n", totalVotes, quorumRequired)

	statusLabel := "PASSED"
	if proposal.Status() == "failed" {
		statusLabel = "FAILED"
	}
	output += ufmt.Sprintf("**Final Status:** %s\n\n", statusLabel)

	if proposal.StatusReason() != "" {
		output += ufmt.Sprintf("**Status Reason:** %s\n\n", proposal.StatusReason())
	}

	output += ufmt.Sprintf("**Voting Ended:** %s\n\n", proposal.VotingDeadline().Format("2006-01-02 15:04:05"))

	output += "---\n\n"
	output += "[Back to archive](/r/pierre115/registrydao:archive) | [Home](/r/pierre115/registrydao)\n"

	return output
}
