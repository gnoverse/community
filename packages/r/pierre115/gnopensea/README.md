# Gnoland NFT Marketplace

A fully-featured NFT marketplace for Gnoland blockchain with automatic royalty distribution (GRC-2981 compliant).

## Features

- GRC-721 compatible - works with any NFT collection implementing the standard
- Automatic royalties - supports GRC-2981 with automatic distribution
- Fixed price listings for immediate purchase
- Secure atomic transfers
- Configurable marketplace fees (default 2.5%)
- Complete on-chain sales history
- Volume and royalty statistics

## Architecture

```
Marketplace Realm
├── Listings (Active)
├── Sales (History)
└── Payment Distribution
    ├── Seller
    ├── Royalty (if GRC-2981)
    └── Marketplace Fee

NFT Collection (GRC-721)
├── OwnerOf()
├── TransferFrom()
├── Approve() / SetApprovalForAll()
└── RoyaltyInfo() (optional)
```

## Usage

### For Sellers

#### Step 1: Approve the Marketplace

```bash
# Approve for all NFTs (recommended)
gnokey maketx call \
  -pkgpath "gno.land/r/[username]/MYNFT" \
  -func "SetApprovalForAll" \
  -args "g1marketplace_address" \
  -args "true" \
  -broadcast \
  yourkey

# Or approve for a specific NFT
gnokey maketx call \
  -pkgpath "gno.land/r/[username]/MYNFT" \
  -func "Approve" \
  -args "g1marketplace_address" \
  -args "1" \
  -broadcast \
  yourkey
```

#### Step 2: Create a Listing


```bash
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopensea" \
  -func "CreateListing" \
  -args "mynft.Getter()" \
  -args "1" \
  -args "5000000" \
  -broadcast \
  yourkey
```

Parameters:
- `nftGetter`: Function returning the NFT collection instance
- `tokenId`: Token ID to sell
- `price`: Price in ugnot (5000000 = 5 GNOT)

#### Step 3: Manage Listing

```bash
# Update price
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopensea" \
  -func "UpdatePrice" \
  -args "1" \
  -args "10000000" \
  -broadcast \
  yourkey

# Cancel listing
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopensea" \
  -func "CancelListing" \
  -args "1" \
  -broadcast \
  yourkey
```

### For Buyers

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopensea" \
  -func "BuyNFT" \
  -args "1" \
  -send "5000000ugnot" \
  -broadcast \
  yourkey
```

Purchase process:
1. Payment verified
2. Royalties calculated (if GRC-2981 supported)
3. Payments distributed
4. NFT transferred
5. Excess refunded

### For Admins

```bash
# Set marketplace fee (in basis points: 100 = 1%, max 1000 = 10%)
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopensea" \
  -func "SetMarketplaceFee" \
  -args "500" \
  -broadcast \
  adminkey

# Withdraw accumulated fees
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopensea" \
  -func "WithdrawFees" \
  -broadcast \
  adminkey
```

## Functions Reference

### Public Functions

- `CreateListing(nftGetter, tokenId, price)` - List an NFT for sale
- `BuyNFT(listingId)` - Purchase a listed NFT
- `CancelListing(listingId)` - Cancel your listing
- `UpdatePrice(listingId, newPrice)` - Update listing price

### Read Functions

- `GetListing(listingId)` - Get listing details
- `GetSale(saleId)` - Get sale details
- `GetActiveListingsCount()` - Number of active listings
- `GetTotalSales()` - Total sales count
- `GetTotalVolume()` - Total volume traded
- `GetTotalRoyaltiesPaid()` - Total royalties distributed
- `GetRoyaltyBreakdown(listingId)` - Calculate payment distribution
- `GetBalance()` - Marketplace balance
- `GetMarketplaceFee()` - Current fee (basis points)
- `GetMarketplaceAddress()` - Marketplace realm address

### Admin Functions

- `SetMarketplaceFee(newFee)` - Update marketplace fee
- `WithdrawFees()` - Withdraw accumulated fees

## Payment Distribution

Example with 10% royalty:

```
Sale Price: 100 GNOT
├── Marketplace Fee (2.5%): 2.5 GNOT
├── Creator Royalty (10%): 10 GNOT
└── Seller Receives: 87.5 GNOT
```

Example without royalty:

```
Sale Price: 100 GNOT
├── Marketplace Fee (2.5%): 2.5 GNOT
└── Seller Receives: 97.5 GNOT
```

## Complete Workflow Example

```bash
# 1. Deploy NFT collection
gnokey maketx addpkg \
  --pkgpath "gno.land/r/alice/mycollection" \
  --pkgdir "./mycollection" \
  --broadcast \
  alice

# 2. Mint an NFT
gnokey maketx call \
  -pkgpath "gno.land/r/alice/mycollection" \
  -func "Mint" \
  -send "1000000ugnot" \
  -broadcast \
  alice

# 3. Approve marketplace
gnokey maketx call \
  -pkgpath "gno.land/r/alice/mycollection" \
  -func "SetApprovalForAll" \
  -args "g1marketplace_address" \
  -args "true" \
  -broadcast \
  alice

# 4. List for 5 GNOT
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopensea" \
  -func "CreateListing" \
  -args "mycollection.Getter()" \
  -args "1" \
  -args "5000000" \
  -broadcast \
  alice

# 5. Purchase NFT
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopensea" \
  -func "BuyNFT" \
  -args "1" \
  -send "5000000ugnot" \
  -broadcast \
  bob
```

## Querying Data

```bash
# View marketplace home
curl https://test4.gno.land/r/demo/marketplace:

# View statistics
curl https://test4.gno.land/r/demo/marketplace:stats

# View specific listing
curl https://test4.gno.land/r/demo/marketplace:listing/1

# View sale details
curl https://test4.gno.land/r/demo/marketplace:sale/1
```

## Security Features

### Built-in Protections

- Ownership verification before listing and sale
- Approval checks at listing and sale time
- Payment validation with automatic refunds
- Atomic transactions (all-or-nothing)
- Admin fee limits (0-10%)

### Best Practices

Do:
- Verify listing details before purchasing
- Use `SetApprovalForAll()` for easier management
- Check marketplace fee before listing
- Verify royalty percentages

Don't:
- Send more than listing price (wastes gas)
- List NFTs you don't own
- Forget to approve marketplace

## NFT Collection Integration

### Minimal Requirements

```go
import "gno.land/p/demo/grc/grc721"

var nft *grc721.basicNFT

func init() {
    nft = grc721.NewBasicNFT("MyCollection", "MC")
}

func Getter() grc721.NFTGetter {
    return nft.Getter()
}
```

### With Royalties (Optional)

```go
var nft *grc721.royaltyNFT

func init() {
    nft = grc721.NewNFTWithRoyalty("MyCollection", "MC")
}

func Mint() {
    // ... mint logic
    royaltyInfo := grc721.RoyaltyInfo{
        PaymentAddress: creator,
        Percentage:     10, // 10%
    }
    nft.SetTokenRoyalty(tokenId, royaltyInfo)
}

func Getter() grc721.NFTGetter {
    return nft.Getter()
}
```
