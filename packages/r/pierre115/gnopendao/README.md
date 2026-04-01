# GnopenSea - NFT Marketplace

Decentralized NFT marketplace on Gno.land with DAO governance.

## 🚀 How to list your NFT in 3 steps

### Step 1: Register your collection

**From your NFT package**, call the `Register()` function:

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/[your-username]/[your-nft]" \
  -func "Register" \
  -gas-fee 1000000ugnot \
  -gas-wanted 5000000 \
  -broadcast \
  -chainid "staging" \
  your-wallet
```

This registers your collection in the **Registry DAO** (status: unverified).

### Step 2: Approve the marketplace

Give permission to the marketplace to transfer your NFTs:

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/[your-username]/[your-nft]" \
  -func "SetApprovalForAll" \
  -args "g1[marketplace-address]" \
  -args "true" \
  -gas-fee 1000000ugnot \
  -gas-wanted 5000000 \
  -broadcast \
  your-wallet
```

### Step 3: Create your listing

List your NFT for sale:

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopendao" \
  -func "CreateListing" \
  -args "gno.land/r/[your-username]/[your-nft]" \
  -args "1" \
  -args "5000000" \
  -gas-fee 1000000ugnot \
  -gas-wanted 5000000 \
  -broadcast \
  your-wallet
```

**Parameters:**
- 1st arg: Your NFT package address
- 2nd arg: Token ID to sell
- 3rd arg: Price in ugnot (5000000 = 5 GNOT)

---

## 🛒 Buy an NFT

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopendao" \
  -func "BuyNFT" \
  -args "1" \
  -send "5000000ugnot" \
  -gas-fee 1000000ugnot \
  -gas-wanted 5000000 \
  -broadcast \
  your-wallet
```

---

## 📋 Manage your listings

### Update price

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopendao" \
  -func "UpdatePrice" \
  -args "1" \
  -args "10000000" \
  -broadcast \
  your-wallet
```

### Cancel a listing

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopendao" \
  -func "CancelListing" \
  -args "1" \
  -broadcast \
  your-wallet
```

---

## Get your collection verified (verified badge)

### 1. Create a proposal to the Registry DAO

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/daoregistry4" \
  -func "ProposeVerifyCollection" \
  -args "g1[your-nft-address]" \
  -args "Collection name" \
  -args "Verification reason" \
  -gas-fee 1000000ugnot \
  -gas-wanted 5000000 \
  -broadcast \
  your-wallet
```

### 2. DAO members vote

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/daoregistry4" \
  -func "VoteRegistry" \
  -args "1" \
  -args "yes" \
  -broadcast \
  dao-member-wallet
```

### 3. Execute the proposal (after quorum)

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/daoregistry4" \
  -func "TallyRegistryProposal" \
  -args "1" \
  -broadcast \
  your-wallet
```

---

## 💰 Payment Distribution

Example with 2.5% marketplace fee and 10% royalties:

```
Sale price: 100 GNOT
├── Marketplace fee (2.5%): 2.5 GNOT
├── Creator royalties (10%): 10 GNOT
└── Seller receives: 87.5 GNOT
```

---

## 🏛️ DAO Governance

The marketplace is governed by a DAO. Members can create proposals to:

- ✅ Approve/remove collections
- ✅ Modify marketplace fees
- ✅ Withdraw funds from treasury
- ✅ Cancel problematic listings

### Create a proposal (example: update fees)

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopendao" \
  -func "ProposeUpdateFees" \
  -args "300" \
  -args "Reduce fees to 3%" \
  -broadcast \
  dao-member-wallet
```

### Vote on a proposal

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/pierre115/gnopendao" \
  -func "Vote" \
  -args "1" \
  -args "yes" \
  -broadcast \
  dao-member-wallet
```

---

## 🔧 Minimal NFT Configuration

Your NFT package must have a `Register()` function:

```go
package mynft

import (
    "gno.land/p/demo/tokens/grc721"
    "gno.land/r/pierre115/daoregistry4"
)

var (
    nft         *grc721.basicNFT
    myRealmAddr = runtime.CurrentRealm().Address()
)

func init() {
    nft = grc721.NewBasicNFT("My Collection", "MC")
}

// Register in the registry
func Register(_ realm) {
    daoregistry4.RegisterCollection(
        myRealmAddr,
        "My Collection",
        "MC",
        "art",
        "My collection description",
        "https://my-site.com",
        false,
        nft.Getter(),
    )
}

// Required function for the marketplace
func Getter() grc721.NFTGetter {
    return nft.Getter()
}
```

---

## 📊 Read Functions

```bash
# View all active listings
curl https://rpc.gno.land/r/pierre115/gnopendao:

# Marketplace statistics
curl https://rpc.gno.land/r/pierre115/gnopendao:stats

# Listing details
curl https://rpc.gno.land/r/pierre115/gnopendao:listing/1

# Registered collections
curl https://rpc.gno.land/r/pierre115/daoregistry4:
```

---

## 🔐 Security

- ✅ Ownership verification before listing
- ✅ Approval verification before sale
- ✅ Atomic transfers
- ✅ Automatic refund of excess payment
- ✅ Fee limits (max 10%)
- ✅ Decentralized governance

---

## 🆘 Common Issues

**"Collection not registered"**
→ You must first call `Register()` on your NFT

**"Insufficient payment"**
→ The amount sent must match the listing price

**"Not approved"**
→ Call `SetApprovalForAll()` before creating a listing

**"Not owner"**
→ Only the NFT owner can list it
