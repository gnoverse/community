package gnopensea

import (
	"strconv"
	"strings"

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

	return "Page not found"
}

func renderHome() string {
	output := "# 🏪 GNOPENSEA9\n\n"
	output += "Marketplace compatible **GRC-721** + **GRC-2981** (Automatic Royalties)\n\n"
	output += "---\n\n"
	output += ufmt.Sprintf("**Marketplace Address:** %s\n\n", marketplaceAddr.String())
	output += "---\n\n"

	output += "## Statistics\n\n"
	output += ufmt.Sprintf("- **Active listings:** %d\n", GetActiveListingsCount())
	output += ufmt.Sprintf("- **Total sales:** %d\n", GetTotalSales())
	output += ufmt.Sprintf("- **Total volume:** %s\n", formatPrice(GetTotalVolume()))
	output += ufmt.Sprintf("- **Royalties paid:** %s\n", formatPrice(GetTotalRoyaltiesPaid()))
	output += ufmt.Sprintf("- **Marketplace fee:** %s\n", formatFee(marketplaceFee))
	output += ufmt.Sprintf("- **Balance:** %s\n\n", formatPrice(GetBalance()))

	output += "[View detailed statistics](/r/pierre115/gnopensea9:stats)\n\n"
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

	output := ufmt.Sprintf("### 🏷️ Listing #%d\n\n", listing.ListingId)
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
	output += ufmt.Sprintf("[View details](/r/pierre115/gnopensea9:listing/%d)\n\n", listing.ListingId)
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
		output += "  -pkgpath \"gno.land/r/pierre115/gnopensea9\" \\\n"
		output += "  -func \"BuyNFT\" \\\n"
		output += ufmt.Sprintf("  -args \"%d\" \\\n", listingId)
		output += ufmt.Sprintf("  -send \"%dugnot\" \\\n", listing.Price)
		output += "  -broadcast yourkey\n"
		output += "```\n"
	}

	output += "\n[← Back](/r/pierre115/gnopensea9)\n"

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

	output += "## 💸 Distribution\n\n"
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
	output := "# 📊 Marketplace Statistics\n\n"

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

	output += "\n[← Back](/r/pierre115/gnopensea9)\n"

	return output
}
