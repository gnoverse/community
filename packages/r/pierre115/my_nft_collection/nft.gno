package mynftcollection

import (
	"chain/runtime"
	"strconv"

	"gno.land/p/demo/tokens/grc721"
	"gno.land/p/nt/ufmt"
	"gno.land/r/pierre115/registrydao"
)

// Interface locale qui combine toutes les méthodes nécessaires
type NFTWithMetadata interface {
	grc721.IGRC721
	grc721.IGRC721MetadataOnchain
	Mint(to address, tid grc721.TokenID) error
	SetTokenMetadata(tid grc721.TokenID, metadata grc721.Metadata) error
	Getter() grc721.NFTGetter
}

var (
	nft                NFTWithMetadata
	nextTokenId        = 1
	myRealmAddr        = runtime.CurrentRealm().Address()
	collectionImageURL = "https://i.imgflip.com/91vskx.jpg"
)

func init() {
	nft = grc721.NewNFTWithMetadata("My NFT Collection", "MNFT")
}

// Register registers this collection on the NFT registry
func Register(_ realm) {
	registrydao.RegisterCollection(
		myRealmAddr,
		"My NFT Collection",
		"MNFT",
		"art",
		"NFT Collection with full metadata support",
		"https://example.com",
		true, // supportsMetadata
		Getter(),
	)
}

// MintNFT - Mint a new NFT with metadata (image fixe définie dans collectionImageURL)
func MintNFT(_ realm, name string, description string) int {
	caller := runtime.PreviousRealm().Address()
	tokenId := grc721.TokenID(strconv.Itoa(nextTokenId))

	// Mint the NFT
	err := nft.Mint(caller, tokenId)
	if err != nil {
		panic(err.Error())
	}

	// Set metadata avec l'image fixe de la collection
	metadata := grc721.Metadata{
		Name:        name,
		Description: description,
		Image:       collectionImageURL, // Image fixe pour tous les NFTs
		Attributes:  []grc721.Trait{},
	}

	err = nft.SetTokenMetadata(tokenId, metadata)
	if err != nil {
		panic(err.Error())
	}

	nextTokenId++
	return nextTokenId - 1
}

// MintNFTWithAttributes - Mint NFT with custom attributes (image fixe définie dans collectionImageURL)
func MintNFTWithAttributes(
	_ realm,
	name string,
	description string,
	traitTypes []string,
	traitValues []string,
) int {
	caller := runtime.PreviousRealm().Address()
	tokenId := grc721.TokenID(strconv.Itoa(nextTokenId))

	// Mint the NFT
	err := nft.Mint(caller, tokenId)
	if err != nil {
		panic(err.Error())
	}

	// Build attributes
	var attributes []grc721.Trait
	if len(traitTypes) != len(traitValues) {
		panic("traitTypes and traitValues must have the same length")
	}

	for i := 0; i < len(traitTypes); i++ {
		attributes = append(attributes, grc721.Trait{
			TraitType: traitTypes[i],
			Value:     traitValues[i],
		})
	}

	// Set metadata with attributes et image fixe
	metadata := grc721.Metadata{
		Name:        name,
		Description: description,
		Image:       collectionImageURL, // Image fixe pour tous les NFTs
		Attributes:  attributes,
	}

	err = nft.SetTokenMetadata(tokenId, metadata)
	if err != nil {
		panic(err.Error())
	}

	nextTokenId++
	return nextTokenId - 1
}

// GetTokenMetadata - Get metadata for a token
func GetTokenMetadata(tokenId string) string {
	tid := grc721.TokenID(tokenId)

	metadata, err := nft.TokenMetadata(tid)
	if err != nil {
		return "Error: " + err.Error()
	}

	output := ufmt.Sprintf("# %s\n\n", metadata.Name)
	output += ufmt.Sprintf("**Description:** %s\n\n", metadata.Description)
	output += ufmt.Sprintf("**Image:** %s\n\n", metadata.Image)

	if len(metadata.Attributes) > 0 {
		output += "## Attributes\n\n"
		for _, trait := range metadata.Attributes {
			output += ufmt.Sprintf("- **%s:** %s\n", trait.TraitType, trait.Value)
		}
	}

	return output
}

// SetApprovalForAll - Approve or revoke operator to manage all caller's NFTs
func SetApprovalForAll(_ realm, operator address, approved bool) {
	err := nft.SetApprovalForAll(operator, approved)
	if err != nil {
		panic(err.Error())
	}
}

// Getter - Returns the NFT getter function
func Getter() grc721.NFTGetter {
	return func() grc721.IGRC721 {
		return nft
	}
}

// GetCollectionInfo - Returns collection info
func GetCollectionInfo() string {
	output := "# My NFT Collection\n\n"
	output += "**Symbol:** MNFT\n"
	output += "**Total Supply:** " + strconv.Itoa(nextTokenId-1) + "\n"
	output += "**Realm Address:** " + myRealmAddr.String() + "\n"
	output += "**Supports Metadata:** Yes\n\n"
	output += "This collection supports full onchain metadata including images, descriptions, and custom attributes.\n"
	return output
}

// Render - Render the collection page
func Render(path string) string {
	if path == "" {
		return GetCollectionInfo()
	}

	// If path is a token ID, show token metadata
	return GetTokenMetadata(path)
}
