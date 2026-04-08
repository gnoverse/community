package nftregistry

import (
	"gno.land/p/nt/ufmt"
)

// Render functions

func Render(path string) string {
	if path == "" {
		return renderHome()
	}

	if path == "verified" {
		return renderVerified()
	}

	// Render specific category
	return renderCategory(path)
}

func renderHome() string {
	output := "# NFT Registry\n\n"
	output += "**The unified NFT collection directory for Gnoland in GRC721**\n\n"
	output += "---\n\n"
	output += ufmt.Sprintf("**Total Collections**: %d\n", GetTotalCollections())
	output += ufmt.Sprintf("**Verified Collections**: %d\n", GetVerifiedCount())
	output += ufmt.Sprintf("**Registration Fee**: %d ugnot\n\n", registrationFee)

	output += "## All Collections\n\n"

	if GetTotalCollections() == 0 {
		output += "_No collections registered yet_\n"
		return output
	}

	collections.Iterate("", "", func(key string, value interface{}) bool {
		info := value.(*CollectionInfo)
		output += renderCollectionCard(info)
		return false
	})

	return output
}

// Render verified collections
func renderVerified() string {
	output := "# Verified Collections\n\n"
	output += ufmt.Sprintf("Showing %d verified collections\n\n", GetVerifiedCount())

	if GetVerifiedCount() == 0 {
		output += "_No verified collections yet_\n"
		return output
	}

	collections.Iterate("", "", func(key string, value interface{}) bool {
		info := value.(*CollectionInfo)
		if info.Verified {
			output += renderCollectionCard(info)
		}
		return false
	})

	return output
}

// Render collections by category
func renderCategory(category string) string {
	output := ufmt.Sprintf("# Category: %s\n\n", category)

	count := 0
	collections.Iterate("", "", func(key string, value interface{}) bool {
		info := value.(*CollectionInfo)
		if info.Category == category {
			output += renderCollectionCard(info)
			count++
		}
		return false
	})

	if count == 0 {
		output += "_No collections in this category_\n"
	}

	return output
}

// Render a single collection card
func renderCollectionCard(info *CollectionInfo) string {
	verified := ""
	if info.Verified {
		verified = " ✓"
	}

	metadata := ""
	if info.SupportsMetadata {
		metadata = " 🎭"
	}

	output := ufmt.Sprintf("### %s (%s)%s%s\n", info.Name, info.Symbol, verified, metadata)
	output += ufmt.Sprintf("- **Address**: `%s`\n", info.Address)
	output += ufmt.Sprintf("- **Creator**: `%s`\n", info.Creator)

	if info.Category != "" {
		output += ufmt.Sprintf("- **Category**: %s\n", info.Category)
	}

	if info.Description != "" {
		output += ufmt.Sprintf("- **Description**: %s\n", info.Description)
	}

	if info.ExternalURL != "" {
		output += ufmt.Sprintf("- **Website**: %s\n", info.ExternalURL)
	}

	output += ufmt.Sprintf("- **Registered**: Block #%d\n", info.RegisteredAt)
	output += "\n"

	return output
}
