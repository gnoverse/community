package gnopensea

import (
	"strconv"

	"chain"
	"chain/banker"
	"chain/runtime"
	"strings"

	"gno.land/p/demo/tokens/grc721"
	"gno.land/p/nt/avl"
	"gno.land/p/nt/ufmt"
)

var (
	listings      avl.Tree
	sales         avl.Tree
	nextListingId = 1
	nextSaleId    = 1

	marketplaceFee  = int64(250) // 250 basis points = 2.5%
	marketplaceAddr = runtime.CurrentRealm().Address()
	owner           address
	admins          avl.Tree
)

func init() {
	owner = runtime.PreviousRealm().Address()
	admins.Set(owner.String(), true)
}

// CreateListing - List an NFT for sale using the global NFT Registry
func CreateListing(_ realm, nftRealmAddress address, tokenId grc721.TokenID, price int64) int {
	caller := runtime.OriginCaller()

	if price <= 0 || price > 99999999999 {
		panic("Price not valid")
	}

	// Check if collection is registered in the GLOBAL NFT Registry
	if !nftregistry.IsRegistered(nftRealmAddress) {
		panic("NFT collection not registered in the global NFT Registry. The collection must call nftregistry.RegisterCollection() first.")
	}

	// Get NFT getter from the global registry
	getter, exists := nftregistry.GetNFTGetter(nftRealmAddress)
	if !exists {
		panic("Failed to get NFT getter from registry")
	}

	nftInstance := getter()

	// Verify caller is the owner
	owner, err := nftInstance.OwnerOf(tokenId)
	if err != nil {
		panic("Token not found: " + err.Error())
	}

	if owner != caller {
		panic("You are not the owner of this NFT")
	}

	// Verify approvals
	marketplaceAddr := runtime.CurrentRealm().Address()
	approvedAddr, err := nftInstance.GetApproved(tokenId)
	isApprovedForToken := (err == nil && approvedAddr == marketplaceAddr)
	isApprovedForAll := nftInstance.IsApprovedForAll(owner, marketplaceAddr)

	if !isApprovedForToken && !isApprovedForAll {
		panic("You must first approve the marketplace.\nUse Approve() or SetApprovalForAll()")
	}

	// Create listing
	listing := &Listing{
		ListingId:       nextListingId,
		NFTGetter:       getter,
		TokenId:         tokenId,
		Seller:          caller,
		Price:           price,
		Active:          true,
		ListedAt:        runtime.ChainHeight(),
		NFTRealmAddress: nftRealmAddress,
	}

	listings.Set(strconv.Itoa(nextListingId), listing)
	nextListingId++

	return listing.ListingId
}

// BuyNFT - Purchase a listed NFT with automatic royalty calculation
func BuyNFT(_ realm, listingId int) {
	caller := runtime.OriginCaller()
	sent := banker.OriginSend()

	// Get listing
	listing := getListing(listingId)
	if listing == nil {
		panic("Listing not found")
	}

	if !listing.Active {
		panic("This listing is no longer active")
	}

	// Verify payment
	amount := sent.AmountOf("ugnot")
	if amount < listing.Price {
		panic(ufmt.Sprintf("Insufficient amount. Price: %d ugnot", listing.Price))
	}

	// Get NFT instance
	nftInstance := listing.NFTGetter()

	// Verify seller still owns the NFT
	currentOwner, err := nftInstance.OwnerOf(listing.TokenId)
	if err != nil {
		panic("NFT not found: " + err.Error())
	}
	if currentOwner != listing.Seller {
		panic("Seller no longer owns this NFT")
	}

	// Calculate royalties
	var royaltyAmount int64 = 0
	var royaltyReceiver address

	// Check if NFT supports royalties
	if royaltyNFT, ok := nftInstance.(grc721.IGRC2981); ok {
		addr, amount, err := royaltyNFT.RoyaltyInfo(listing.TokenId, listing.Price)
		if err == nil {
			royaltyAmount = amount
			royaltyReceiver = addr
		}
	}

	// Calculate marketplace fee
	marketplaceFeeAmount := (listing.Price * marketplaceFee) / 10000

	// Calculate what seller receives
	sellerAmount := listing.Price - marketplaceFeeAmount - royaltyAmount

	if sellerAmount < 0 {
		panic("Error: fees + royalties exceed sale price")
	}

	// Distribute payments
	bnkr := banker.NewBanker(banker.BankerTypeRealmSend)
	realmAddr := runtime.CurrentRealm().Address()

	// 1. Pay seller
	if sellerAmount > 0 {
		sellerCoins := chain.Coins{chain.Coin{"ugnot", sellerAmount}}
		bnkr.SendCoins(realmAddr, listing.Seller, sellerCoins)
	}

	// 2. Pay royalties to creator
	if royaltyAmount > 0 && royaltyReceiver != "" {
		royaltyCoins := chain.Coins{chain.Coin{"ugnot", royaltyAmount}}
		bnkr.SendCoins(realmAddr, royaltyReceiver, royaltyCoins)
	}

	// 3. TODO : Marketplace fees remain in contract (withdrawal by admin)

	// 4. Refund excess
	if amount > listing.Price {
		excess := amount - listing.Price
		excessCoins := chain.Coins{chain.Coin{"ugnot", excess}}
		bnkr.SendCoins(realmAddr, caller, excessCoins)
	}

	// Transfer NFT
	err = nftInstance.TransferFrom(listing.Seller, caller, listing.TokenId)
	if err != nil {
		panic("Transfer error: " + err.Error())
	}

	// Record sale
	sale := &Sale{
		ListingId:       listingId,
		TokenId:         listing.TokenId.String(),
		Buyer:           caller,
		Seller:          listing.Seller,
		Price:           listing.Price,
		MarketplaceFee:  marketplaceFeeAmount,
		RoyaltyFee:      royaltyAmount,
		RoyaltyReceiver: royaltyReceiver,
		SoldAt:          runtime.ChainHeight(),
	}

	sales.Set(strconv.Itoa(nextSaleId), sale)
	nextSaleId++

	// Deactivate listing
	listing.Active = false
	listings.Set(strconv.Itoa(listingId), listing)
}

// CancelListing - Cancel a listing
func CancelListing(_realm, listingId int) {
	caller := runtime.PreviousRealm().Address()

	listing := getListing(listingId)
	if listing == nil {
		panic("Listing not found")
	}

	if listing.Seller != caller && !admins.Has(caller.String()) {
		panic("Only the seller or admins can cancel this listing")
	}

	if !listing.Active {
		panic("This listing is already inactive")
	}

	listing.Active = false
	listings.Set(strconv.Itoa(listingId), listing)
}

// BuyNFTDebug - Version debug de BuyNFT
func BuyNFTDebug(_ realm, listingId int) string {
	output := "=== BuyNFT Debug ===\n\n"

	// Step 1
	caller := runtime.OriginCaller()
	output += ufmt.Sprintf("1. Caller: %s\n", caller.String())

	// Step 2
	sent := banker.OriginSend()
	amount := sent.AmountOf("ugnot")
	output += ufmt.Sprintf("2. Amount sent: %d ugnot\n", amount)

	// Step 3
	listing := getListing(listingId)
	if listing == nil {
		output += "3. ERROR: Listing not found\n"
		return output
	}
	output += ufmt.Sprintf("3. Listing found, price: %d\n", listing.Price)
	output += ufmt.Sprintf("   Seller: %s\n", listing.Seller.String())
	output += ufmt.Sprintf("   Active: %t\n", listing.Active)

	// Step 4
	if !listing.Active {
		output += "4. ERROR: Listing not active\n"
		return output
	}
	output += "4. Listing is active\n"

	// Step 5
	if amount < listing.Price {
		output += ufmt.Sprintf("5. ERROR: Insufficient amount (sent: %d, need: %d)\n", amount, listing.Price)
		return output
	}
	output += "5. Payment verified\n"

	// Step 6
	if caller == listing.Seller {
		output += "6. ERROR: Cannot buy your own NFT\n"
		return output
	}
	output += "6. Buyer is not seller\n"

	// Step 7
	nftInstance := listing.NFTGetter()
	output += "7. NFT instance retrieved\n"

	// Step 8
	currentOwner, err := nftInstance.OwnerOf(listing.TokenId)
	if err != nil {
		output += ufmt.Sprintf("8. ERROR: %s\n", err.Error())
		return output
	}
	output += ufmt.Sprintf("8. Current owner: %s\n", currentOwner.String())

	// Step 9
	if currentOwner != listing.Seller {
		output += "9. ERROR: Seller no longer owns NFT\n"
		return output
	}
	output += "9. Seller still owns NFT\n"

	output += "\n✅ All checks passed - ready to execute transfer\n"

	return output
}

// UpdatePrice - Update listing price
func UpdatePrice(_ realm, listingId int, newPrice int64) {
	caller := runtime.PreviousRealm().Address()

	if newPrice <= 0 {
		panic("Price must be positive")
	}

	listing := getListing(listingId)
	if listing == nil {
		panic("Listing not found")
	}

	if listing.Seller != caller {
		panic("Only the seller can modify this listing")
	}

	if !listing.Active {
		panic("This listing is no longer active")
	}

	listing.Price = newPrice
	listings.Set(strconv.Itoa(listingId), listing)
}

// ============= READ FUNCTIONS =============

func GetListing(listingId int) (int, string, int64, string, bool, int64) {
	listing := getListing(listingId)
	if listing == nil {
		return 0, "", 0, "", false, 0
	}

	return listing.ListingId,
		listing.TokenId.String(),
		listing.Price,
		listing.Seller.String(),
		listing.Active,
		listing.ListedAt
}

func GetSale(saleId int) (int, string, string, string, int64, int64, int64, string, int64) {
	value, exists := sales.Get(strconv.Itoa(saleId))
	if !exists {
		return 0, "", "", "", 0, 0, 0, "", 0
	}

	sale := value.(*Sale)
	return sale.ListingId,
		sale.TokenId,
		sale.Buyer.String(),
		sale.Seller.String(),
		sale.Price,
		sale.MarketplaceFee,
		sale.RoyaltyFee,
		sale.RoyaltyReceiver.String(),
		sale.SoldAt
}

func GetActiveListingsCount() int {
	count := 0
	listings.Iterate("", "", func(key string, value interface{}) bool {
		listing := value.(*Listing)
		if listing.Active {
			count++
		}
		return false
	})
	return count
}

func GetTotalSales() int {
	return sales.Size()
}

func GetTotalVolume() int64 {
	var total int64 = 0
	sales.Iterate("", "", func(key string, value interface{}) bool {
		sale := value.(*Sale)
		total += sale.Price
		return false
	})
	return total
}

func GetTotalRoyaltiesPaid() int64 {
	var total int64 = 0
	sales.Iterate("", "", func(key string, value interface{}) bool {
		sale := value.(*Sale)
		total += sale.RoyaltyFee
		return false
	})
	return total
}

func GetMarketplaceFee() int64 {
	return marketplaceFee
}

func GetMarketplaceAddress() address {
	return runtime.CurrentRealm().Address()
}

// GetRoyaltyBreakdown - Calculate distribution for a listing
func GetRoyaltyBreakdown(listingId int) (int64, int64, int64, address) {
	listing := getListing(listingId)
	if listing == nil {
		return 0, 0, 0, ""
	}

	// Calculate marketplace fee
	marketplaceFeeAmount := (listing.Price * marketplaceFee) / 10000

	// Calculate royalties if supported
	nftInstance := listing.NFTGetter()
	var royaltyAmount int64 = 0
	var royaltyReceiver address

	if royaltyNFT, ok := nftInstance.(grc721.IGRC2981); ok {
		addr, amount, err := royaltyNFT.RoyaltyInfo(listing.TokenId, listing.Price)
		if err == nil {
			royaltyAmount = amount
			royaltyReceiver = addr
		}
	}

	sellerAmount := listing.Price - marketplaceFeeAmount - royaltyAmount

	return sellerAmount, marketplaceFeeAmount, royaltyAmount, royaltyReceiver
}

func GetBalance() int64 {
	bnkr := banker.NewBanker(banker.BankerTypeRealmSend)
	realmAddr := runtime.CurrentRealm().Address()
	balance := bnkr.GetCoins(realmAddr)
	return balance.AmountOf("ugnot")
}

// ============= READ FUNCTIONS FOR FRONTEND =============

// GetAllListings - Return all active listings
func GetAllListings() string {
	var listingsData []string

	listings.Iterate("", "", func(key string, value interface{}) bool {
		listing := value.(*Listing)
		if listing.Active {
			// Format: listingId|nftAddress|tokenId|price|seller
			listingData := ufmt.Sprintf("%d|%s|%s|%d|%s",
				listing.ListingId,
				listing.NFTRealmAddress.String(),
				listing.TokenId.String(),
				listing.Price,
				listing.Seller.String(),
			)
			listingsData = append(listingsData, listingData)
		}
		return false
	})

	if len(listingsData) == 0 {
		return "No active listings"
	}

	return strings.Join(listingsData, "\n")
}

// GetListingDetails - Get detailed info about a listing
func GetListingDetails(listingId int) string {
	listing := getListing(listingId)
	if listing == nil {
		return "Listing not found"
	}

	nftInstance := listing.NFTGetter()

	// Get NFT metadata if available
	var name, uri string
	if metaNFT, ok := nftInstance.(grc721.IGRC721Metadata); ok {
		name = metaNFT.Name()
		if tokenURI, err := metaNFT.TokenURI(listing.TokenId); err == nil {
			uri = tokenURI
		}
	}

	// Format JSON-like response
	output := ufmt.Sprintf(`{
  "listingId": %d,
  "tokenId": "%s",
  "price": %d,
  "seller": "%s",
  "active": %t,
  "name": "%s",
  "uri": "%s",
  "listedAt": %d
}`,
		listing.ListingId,
		listing.TokenId.String(),
		listing.Price,
		listing.Seller.String(),
		listing.Active,
		name,
		uri,
		listing.ListedAt,
	)

	return output
}

// GetUserListings - Get all listings by a specific seller
func GetUserListings(sellerAddr address) string {
	var userListings []string

	listings.Iterate("", "", func(key string, value interface{}) bool {
		listing := value.(*Listing)
		if listing.Seller == sellerAddr && listing.Active {
			listingData := ufmt.Sprintf("%d|%s|%d",
				listing.ListingId,
				listing.TokenId.String(),
				listing.Price,
			)
			userListings = append(userListings, listingData)
		}
		return false
	})

	if len(userListings) == 0 {
		return "No active listings"
	}

	return strings.Join(userListings, "\n")
}

// GetMarketplaceStats - Get overall marketplace statistics
func GetMarketplaceStats() string {
	activeCount := GetActiveListingsCount()
	totalSales := GetTotalSales()
	totalVolume := GetTotalVolume()

	output := ufmt.Sprintf(`{
  "activeListings": %d,
  "totalSales": %d,
  "totalVolume": %d,
  "marketplaceFee": %d
}`,
		activeCount,
		totalSales,
		totalVolume,
		marketplaceFee,
	)

	return output
}

// ============= HELPERS =============

func getListing(listingId int) *Listing {
	value, exists := listings.Get(strconv.Itoa(listingId))
	if !exists {
		return nil
	}
	return value.(*Listing)
}

func formatPrice(ugnot int64) string {
	gnot := float64(ugnot) / 1000000.0
	return ufmt.Sprintf("%.2f GNOT", gnot)
}

func formatFee(basisPoints int64) string {
	percent := float64(basisPoints) / 100.0
	return ufmt.Sprintf("%.2f%%", percent)
}

func formatPercentage(value, total int64) string {
	if total == 0 {
		return "0%"
	}
	percent := (float64(value) / float64(total)) * 100.0
	return ufmt.Sprintf("%.1f%%", percent)
}
