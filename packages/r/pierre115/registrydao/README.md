# DAO Registry - NFT Collection Registry

Global registry for NFT collections on Gno.land with DAO-based verification.

## Overview

The DAO Registry is a centralized registry that tracks all NFT collections. It provides:
- Collection registration (permissionless)
- DAO-based verification system
- Metadata storage (name, symbol, category, description, website)
- NFT getter functions for marketplace integration

## For NFT Creators: Setup for Marketplace

To list your NFTs on the marketplace, you need to implement these functions in your NFT package:

### 1. Required: `Register()` function

This function registers your collection in the global registry:

```go
func Register(_ realm) {
    registrydao.RegisterCollection(
        myRealmAddr,
        "Collection Name",
        "SYMBOL",
        "category",           // e.g., "art", "gaming", "photography"
        "Description",
        "https://website.com",
        false,                // hasOffchainMetadata
        nft.Getter(),
    )
}
```

### 2. Required: `Getter()` function

This function must return the NFT getter for the marketplace:

```go
func Getter() grc721.NFTGetter {
    return nft.Getter()
}
```

### 3. Optional: Metadata functions

For rich marketplace display, implement these optional interfaces:

```go
// For on-chain metadata
func (nft *MyNFT) TokenMetadata(tid grc721.TokenID) (grc721.Metadata, error) {
    return grc721.Metadata{
        Name:        "NFT Name",
        Description: "NFT Description",
        Image:       "https://image-url.com",
        Attributes: []grc721.Trait{
            {TraitType: "Background", Value: "Blue"},
            {TraitType: "Rarity", Value: "Rare"},
        },
    }, nil
}

// For royalties (GRC2981)
func (nft *MyNFT) RoyaltyInfo(tid grc721.TokenID, salePrice int64) (address, int64, error) {
    royaltyAmount := (salePrice * 1000) / 10000  // 10% royalty
    return creatorAddress, royaltyAmount, nil
}
```

## Key Functions

**Registration:**
- `RegisterCollection()` - Register your NFT collection (call from your NFT realm)
- `IsRegistered()` - Check if a collection is registered
- `GetNFTGetter()` - Get the NFT getter function for a collection

**Metadata:**
- `GetTokenMetadata()` - Retrieve on-chain metadata for a specific token
- `GetCollectionInfo()` - Get collection information

**Verification (DAO only):**
- `ProposeVerifyCollection()` - Create a verification proposal
- `VoteRegistry()` - Vote on a verification proposal
- `TallyRegistryProposal()` - Execute a passed proposal

## Registration Status

Collections have two levels:
1. **Registered** (automatic) - Technical registration, allows basic marketplace functionality
2. **Verified** (DAO approval required) - Blue checkmark badge, signals trust

## Integration with Marketplace

Once registered, the marketplace can:
- Verify collections are legitimate
- Fetch NFT instances via getters
- Display metadata (if implemented)
- Calculate and distribute royalties (if GRC2981 is implemented)

## Minimal Example

```go
package mynft

import (
    "gno.land/p/demo/tokens/grc721"
    "gno.land/r/pierre115/registrydao"
)

var (
    nft = grc721.NewBasicNFT("My NFTs", "MNFT")
    myRealmAddr = runtime.CurrentRealm().Address()
)

func Register(_ realm) {
    registrydao.RegisterCollection(
        myRealmAddr,
        "My NFTs",
        "MNFT",
        "art",
        "My awesome NFT collection",
        "https://my-nfts.com",
        false,
        nft.Getter(),
    )
}

func Getter() grc721.NFTGetter {
    return nft.Getter()
}
```

Call `Register()` once, then your collection is ready for the marketplace!
