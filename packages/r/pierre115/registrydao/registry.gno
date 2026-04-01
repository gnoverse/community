package registrydao

import (
	"chain/runtime"

	"gno.land/p/demo/tokens/grc721"
	"gno.land/p/nt/avl"
)

var (
	collections     avl.Tree
	categoriesIndex avl.Tree
	registrationFee int64 = 1000000
)

func init() {
	initRegistryDAO()
}

// RegisterCollection - Register a new NFT collection
func RegisterCollection(
	realmAddr address,
	name string,
	symbol string,
	category string,
	description string,
	externalURL string,
	supportsMetadata bool,
	getter grc721.NFTGetter,
) {
	creator := runtime.OriginCaller()

	// Check if collection already registered
	if collections.Has(realmAddr.String()) {
		panic("Collection already registered")
	}

	if getter == nil {
		panic("NFT getter function is required")
	}

	if name == "" || symbol == "" {
		panic("Name and symbol cannot be empty")
	}

	info := &CollectionInfo{
		Address:          realmAddr,
		Creator:          creator,
		Name:             name,
		Symbol:           symbol,
		RegisteredAt:     runtime.ChainHeight(),
		Verified:         false,
		Category:         category,
		Description:      description,
		ExternalURL:      externalURL,
		NFTGetter:        getter,
		SupportsMetadata: supportsMetadata,
	}

	collections.Set(realmAddr.String(), info)
}

// IsRegistered - Check if a collection is registered
func IsRegistered(collectionAddr address) bool {
	return collections.Has(collectionAddr.String())
}

// GetTotalCollections - Total number of registered collections
func GetTotalCollections() int {
	count := 0
	collections.Iterate("", "", func(key string, value interface{}) bool {
		count++
		return false
	})
	return count
}

// GetVerifiedCount - Count of verified collections
func GetVerifiedCount() int {
	count := 0
	collections.Iterate("", "", func(key string, value interface{}) bool {
		info := value.(*CollectionInfo)
		if info.Verified {
			count++
		}
		return false
	})
	return count
}

// GetCollection - Retrieve collection info by address
func GetCollection(collectionAddr address) *CollectionInfo {
	val, exists := collections.Get(collectionAddr.String())
	if !exists {
		return nil
	}
	return val.(*CollectionInfo)
}

// GetNFTGetter - Retrieve the NFTGetter function for a collection
func GetNFTGetter(collectionAddr address) (grc721.NFTGetter, bool) {
	info := GetCollection(collectionAddr)
	if info == nil {
		return nil, false
	}
	return info.NFTGetter, true
}

// GetTokenMetadata - Retrieve onchain metadata for a token
func GetTokenMetadata(collectionAddr address, tokenId grc721.TokenID) (grc721.Metadata, error) {
	info := GetCollection(collectionAddr)
	if info == nil {
		panic("Collection not registered")
	}

	if !info.SupportsMetadata {
		panic("Collection does not support onchain metadata")
	}

	nftInstance := info.NFTGetter()
	metadataCollection := nftInstance.(grc721.IGRC721MetadataOnchain)

	return metadataCollection.TokenMetadata(tokenId)
}

// UpdateCollectionInfo - Update collection metadata
func UpdateCollectionInfo(category, description, externalURL string) {
	caller := runtime.PreviousRealm().Address()

	info := GetCollection(caller)
	if info == nil {
		panic("Collection not registered")
	}

	info.Category = category
	info.Description = description
	info.ExternalURL = externalURL
	collections.Set(caller.String(), info)
}
