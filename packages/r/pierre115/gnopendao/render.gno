package gnopendao

import (
	"strconv"
	"strings"

	"gno.land/p/leon/svgbtn"
	"gno.land/p/moul/txlink"
	"gno.land/p/nt/commondao"
	"gno.land/p/nt/ufmt"
)

// ============= RENDER =============

func Render(path string) string {
	if path == "" {
		return renderHome()
	}

	if strings.HasPrefix(path, "listing/") {
		idStr := strings.TrimPrefix(path, "listing/")
		id, _ := strconv.Atoi(idStr)
		return renderListing(id)
	}

	if strings.HasPrefix(path, "sale/") {
		idStr := strings.TrimPrefix(path, "sale/")
		id, _ := strconv.Atoi(idStr)
		return renderSale(id)
	}

	if path == "stats" {
		return renderStats()
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

	return "Page not found"
}

func renderHome() string {
	output := "# GNOPENSEA DAO 10\n\n"
	output += "Decentralized NFT Marketplace with DAO Governance\n\n"
	output += "Compatible **GRC-721** + **GRC-2981** (Automatic Royalties)\n\n"
	output += "---\n\n"
	output += ufmt.Sprintf("**Marketplace Address:** %s\n\n", marketplaceAddr.String())
	output += "[View detailed statistics](/r/pierre115/gnopendao:stats)\n\n"
	output += "---\n\n"

	// DAO Section
	output += "## DAO Governance\n\n"
	output += ufmt.Sprintf("**Total DAO Members:** %d\n\n", GetTotalMembers())

	activeProposals := marketplaceDAO.ActiveProposals()
	if activeProposals.Size() > 0 {
		output += ufmt.Sprintf("**Active Proposals:** %d\n\n", activeProposals.Size())
		output += "[View all proposals](/r/pierre115/gnopendao:proposals)\n\n"
	} else {
		output += "**Active Proposals:** 0\n\n"
		output += "*No active proposals*\n\n"
	}

	finishedProposals := marketplaceDAO.FinishedProposals()
	output += ufmt.Sprintf("[View archive (%d)](/r/pierre115/gnopendao:archive)\n\n", finishedProposals.Size())

	// Vote Join button
	linkjoin := txlink.NewLink("JoinDAO").
		URL()
	output += svgbtn.SuccessButton(100, 30, "Join !", linkjoin) + "\n\n"

	output += "---\n\n"

	// Active listings
	if GetActiveListingsCount() > 0 {
		output += "## NFTs for sale\n\n"

		listings.Iterate("", "", func(key string, value interface{}) bool {
			listing := value.(*Listing)
			if listing.Active {
				output += renderListingPreview(listing)
			}
			return false
		})
	} else {
		output += "## No NFTs for sale\n\n"
		output += "*Be the first to list an NFT!*\n"
	}

	return output
}

func renderListingPreview(listing *Listing) string {
	// Calculate breakdown
	sellerGets, marketFee, royalty, royaltyAddr := GetRoyaltyBreakdown(listing.ListingId)

	output := ufmt.Sprintf("### Listing #%d\n\n", listing.ListingId)
	output += ufmt.Sprintf("**Token ID:** %s\n\n", listing.TokenId.String())
	output += ufmt.Sprintf("**Price:** %s\n\n", formatPrice(listing.Price))

	if royalty > 0 {
		output += ufmt.Sprintf("Royalty: %s (%s)\n\n",
			formatPrice(royalty),
			formatPercentage(royalty, listing.Price))
	}

	output += ufmt.Sprintf("**Seller receives:** %s\n\n", formatPrice(sellerGets))
	output += ufmt.Sprintf("**Market Fees:** %s\n\n", formatPrice(marketFee))
	output += ufmt.Sprintf("**Royalty Address:** %s\n\n", royaltyAddr.String())
	output += ufmt.Sprintf("**Marketplace Address:** %s\n\n", marketplaceAddr.String())
	output += ufmt.Sprintf("[View details](/r/pierre115/gnopendao:listing/%d)\n\n", listing.ListingId)
	output += "---\n\n"
	return output
}

func renderListing(listingId int) string {
	listing := getListing(listingId)
	if listing == nil {
		return "# Listing not found"
	}

	status := "Active"
	if !listing.Active {
		status = "Sold/Cancelled"
	}

	output := ufmt.Sprintf("# Listing #%d - %s\n\n", listingId, status)

	output += "## Details\n\n"
	output += ufmt.Sprintf("**Token ID:** %s\n\n", listing.TokenId.String())
	output += ufmt.Sprintf("**Price:** %s\n\n", formatPrice(listing.Price))
	output += ufmt.Sprintf("**Seller:** `%s`\n\n", listing.Seller.String())
	output += ufmt.Sprintf("**Listed at block:** %d\n\n", listing.ListedAt)

	if listing.Active {
		sellerGets, marketFee, royalty, royaltyAddr := GetRoyaltyBreakdown(listingId)

		output += "---\n\n"
		output += "## Price breakdown\n\n"
		output += ufmt.Sprintf("- **Total price:** %s (100%%)\n", formatPrice(listing.Price))
		output += ufmt.Sprintf("- **Marketplace fee (%s):** %s\n",
			formatFee(marketplaceFee), formatPrice(marketFee))

		if royalty > 0 {
			output += ufmt.Sprintf("- **Creator royalty (%s):** %s\n",
				formatPercentage(royalty, listing.Price), formatPrice(royalty))
			output += ufmt.Sprintf("  - Beneficiary: `%s`\n", royaltyAddr.String())
		} else {
			output += "- **Royalty:** None\n"
		}

		output += ufmt.Sprintf("- **Seller receives:** %s (%s)\n\n",
			formatPrice(sellerGets), formatPercentage(sellerGets, listing.Price))

		output += "## Purchase\n\n"
		output += "```bash\n"
		output += "gnokey maketx call \\\n"
		output += "  -pkgpath \"gno.land/r/pierre115/gnopendao\" \\\n"
		output += "  -func \"BuyNFT\" \\\n"
		output += ufmt.Sprintf("  -args \"%d\" \\\n", listingId)
		output += ufmt.Sprintf("  -send \"%dugnot\" \\\n", listing.Price)
		output += "  -broadcast yourkey\n"
		output += "```\n"
	}

	output += "\n[← Back](/r/pierre115/gnopendao)\n"

	return output
}

func renderSale(saleId int) string {
	value, exists := sales.Get(strconv.Itoa(saleId))
	if !exists {
		return "# Sale not found"
	}

	sale := value.(*Sale)

	output := ufmt.Sprintf("# Sale #%d\n\n", saleId)
	output += ufmt.Sprintf("**Token ID:** %s\n\n", sale.TokenId)
	output += ufmt.Sprintf("**Price:** %s\n\n", formatPrice(sale.Price))
	output += ufmt.Sprintf("**Buyer:** `%s`\n\n", sale.Buyer.String())
	output += ufmt.Sprintf("**Seller:** `%s`\n\n", sale.Seller.String())
	output += ufmt.Sprintf("**Block:** %d\n\n", sale.SoldAt)

	output += "## Distribution\n\n"
	output += ufmt.Sprintf("- **Marketplace fee:** %s\n", formatPrice(sale.MarketplaceFee))

	if sale.RoyaltyFee > 0 {
		output += ufmt.Sprintf("- **Royalty:** %s → `%s`\n",
			formatPrice(sale.RoyaltyFee), sale.RoyaltyReceiver.String())
	}

	sellerReceived := sale.Price - sale.MarketplaceFee - sale.RoyaltyFee
	output += ufmt.Sprintf("- **Seller received:** %s\n", formatPrice(sellerReceived))

	return output
}

func renderStats() string {
	output := "# Marketplace Statistics\n\n"

	totalVolume := GetTotalVolume()
	totalSales := GetTotalSales()
	totalRoyalties := GetTotalRoyaltiesPaid()

	output += ufmt.Sprintf("**Total volume:** %s\n\n", formatPrice(totalVolume))
	output += ufmt.Sprintf("**Number of sales:** %d\n\n", totalSales)
	output += ufmt.Sprintf("**Royalties paid:** %s (%s of volume)\n\n",
		formatPrice(totalRoyalties), formatPercentage(totalRoyalties, totalVolume))

	if totalSales > 0 {
		avgPrice := totalVolume / int64(totalSales)
		output += ufmt.Sprintf("**Average price:** %s\n\n", formatPrice(avgPrice))
	}

	output += "\n[← Back](/r/pierre115/gnopendao)\n"

	return output
}

// ============= DAO RENDER FUNCTIONS =============

func renderProposals() string {
	output := "# Active DAO Proposals\n\n"

	proposals := marketplaceDAO.ActiveProposals()

	if proposals.Size() == 0 {
		output += "*No active proposals at the moment*\n\n"
		output += "DAO members can create proposals to:\n"
		output += "- Approve new NFT collections\n"
		output += "- Remove existing collections\n"
		output += "- Update marketplace fees\n\n"
		output += "[← Back](/r/pierre115/gnopendao)\n"
		return output
	}

	proposals.Iterate(0, proposals.Size(), false, func(p *commondao.Proposal) bool {
		output += renderProposalPreview(p)
		return false
	})

	output += "\n[← Back](/r/pierre115/gnopendao)\n"

	return output
}

func renderProposalPreview(p *commondao.Proposal) string {
	output := ufmt.Sprintf("## Proposal #%d\n\n", p.ID())
	output += ufmt.Sprintf("**%s**\n\n", p.Definition().Title())

	// Count votes
	yesVotes := 0
	noVotes := 0
	p.VotingRecord().Iterate(0, p.VotingRecord().Size(), false, func(v commondao.Vote) bool {
		if string(v.Choice) == "yes" {
			yesVotes++
		} else if string(v.Choice) == "no" {
			noVotes++
		}
		return false
	})

	output += ufmt.Sprintf("**Yes:** %d | **No:** %d | **Total:** %d\n\n", yesVotes, noVotes, yesVotes+noVotes)

	if p.HasVotingDeadlinePassed() {
		output += "⏰ **Voting ended**\n\n"
	} else {
		output += "✅ **Voting open**\n\n"
	}

	output += ufmt.Sprintf("[View & Vote](/r/pierre115/gnopendao:proposal/%d)\n\n", p.ID())
	output += "---\n\n"

	return output
}

func renderProposal(proposalID uint64) string {
	proposal := marketplaceDAO.ActiveProposals().Get(proposalID)
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
		if string(v.Choice) == "yes" {
			yesVotes++
		} else if string(v.Choice) == "no" {
			noVotes++
		}
		totalVotes++
		return false
	})

	output += "## Current Results\n\n"
	output += ufmt.Sprintf("- **Yes votes:** %d\n", yesVotes)
	output += ufmt.Sprintf("- **No votes:** %d\n", noVotes)
	output += ufmt.Sprintf("- **Total votes:** %d\n", totalVotes)

	totalMembers := GetTotalMembers()
	quorumRequired := int(float64(totalMembers) * QUORUM)
	output += ufmt.Sprintf("- **Quorum required:** %d/%d votes\n\n", totalVotes, quorumRequired)

	if proposal.HasVotingDeadlinePassed() {
		output += "⏰ **Voting period has ended**\n\n"
	} else {
		output += "✅ **Voting is open**\n\n"

		output += "---\n\n"
		output += "## Cast Your Vote\n\n"

		// Vote YES button
		linkyes := txlink.NewLink("Vote").
			AddArgs("proposalID", ufmt.Sprintf("%d", proposalID)).
			AddArgs("choice", "yes").
			URL()
		output += svgbtn.SuccessButton(100, 30, "YES", linkyes) + "\n\n"

		// Vote NO button
		linkno := txlink.NewLink("Vote").
			AddArgs("proposalID", ufmt.Sprintf("%d", proposalID)).
			AddArgs("choice", "no").
			URL()
		output += svgbtn.DangerButton(100, 30, "NO", linkno) + "\n\n"
	}

	output += "---\n\n"
	output += "[← Back to proposals](/r/pierre115/gnopendao:proposals) | [← Home](/r/pierre115/gnopendao)\n"

	return output
}

// ============= ARCHIVE RENDER FUNCTIONS =============

func renderArchive() string {
	output := "# Proposal Archive\n\n"

	finishedProposals := marketplaceDAO.FinishedProposals()

	if finishedProposals.Size() == 0 {
		output += "*No finished proposals yet*\n\n"
		output += "[← Back](/r/pierre115/gnopendao)\n"
		return output
	}

	output += ufmt.Sprintf("**Total archived proposals:** %d\n\n", finishedProposals.Size())
	output += "---\n\n"

	finishedProposals.Iterate(0, finishedProposals.Size(), false, func(p *commondao.Proposal) bool {
		output += renderArchivedProposalPreview(p)
		return false
	})

	output += "\n[← Back](/r/pierre115/gnopendao)\n"

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

	statusEmoji := "✅"
	if p.Status() == "failed" {
		statusEmoji = "❌"
	}
	output += ufmt.Sprintf("%s **Status:** %s\n\n", statusEmoji, string(p.Status()))
	if p.StatusReason() != "" {
		output += ufmt.Sprintf("**Reason:** %s\n\n", p.StatusReason())
	}

	output += ufmt.Sprintf("[View details](/r/pierre115/gnopendao:archived/%d)\n\n", p.ID())
	output += "---\n\n"

	return output
}

func renderArchivedProposal(proposalID uint64) string {
	proposal := marketplaceDAO.FinishedProposals().Get(proposalID)
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

	totalMembers := GetTotalMembers()
	quorumRequired := int(float64(totalMembers) * QUORUM)
	output += ufmt.Sprintf("- **Quorum required:** %d/%d votes\n\n", totalVotes, quorumRequired)

	statusEmoji := "✅"
	if proposal.Status() == "failed" {
		statusEmoji = "❌"
	}
	output += ufmt.Sprintf("%s **Final Status:** %s\n\n", statusEmoji, string(proposal.Status()))

	if proposal.StatusReason() != "" {
		output += ufmt.Sprintf("**Status Reason:** %s\n\n", proposal.StatusReason())
	}

	output += ufmt.Sprintf("**Voting Ended:** %s\n\n", proposal.VotingDeadline().Format("2006-01-02 15:04:05"))

	output += "---\n\n"
	output += "[← Back to archive](/r/pierre115/gnopendao:archive) | [← Home](/r/pierre115/gnopendao)\n"

	return output
}
