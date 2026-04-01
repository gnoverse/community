package gnopendao

import (
	"chain"
	"chain/banker"
	"chain/runtime"
	"strconv"
	"strings"

	"gno.land/p/demo/tokens/grc721"
	"gno.land/p/nt/avl"
	"gno.land/p/nt/ufmt"
	"gno.land/r/pierre115/registrydao"
)

var (
	listings      avl.Tree
	sales         avl.Tree
	nextListingId = 1
	nextSaleId    = 1

	marketplaceFee      = int64(250) // 250 basis points = 2.5%
	marketplaceAddr     = runtime.CurrentRealm().Address()
	approvedCollections avl.Tree // Whitelist of approved collections
)

func init() {
	initDAO()
}

// CreateListing - List an NFT for sale using the global NFT Registry
func CreateListing(_ realm, nftRealmAddress address, tokenId grc721.TokenID, price int64) int {
	caller := runtime.OriginCaller()

	if price <= 0 || price > 99999999999 {
		panic("Price not valid")
	}

	// Check if collection is registered in the GLOBAL NFT Registry (technical check)
	if !registrydao.IsRegistered(nftRealmAddress) {
		panic("NFT collection not registered in the global NFT Registry. The collection must call nftregistry.RegisterCollection() first.")
	}
	// Check if collection is approved by DAO (governance check)
	if !approvedCollections.Has(nftRealmAddress.String()) {
		panic("Collection not approved by DAO. A DAO proposal must be created and passed first.")
	}

	// Get NFT getter from the global registry
	getter, exists := registrydao.GetNFTGetter(nftRealmAddress)
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

	// 3. TODO : Marketplace fees remain in contract

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

// CancelListing - Cancel own listing (seller only)
func CancelListing(_ realm, listingId int) {
	caller := runtime.PreviousRealm().Address()

	listing := getListing(listingId)
	if listing == nil {
		panic("Listing not found")
	}

	// Only seller can cancel their own listing
	// DAO use ProposeForceCancelListing instead
	if listing.Seller != caller {
		panic("Only the seller can cancel this listing. DAO members can create a ProposeForceCancelListing proposal.")
	}

	if !listing.Active {
		panic("This listing is already inactive")
	}

	listing.Active = false
	listings.Set(strconv.Itoa(listingId), listing)
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

// GetAllListings - Return all active listings with metadata
func GetAllListings() string {
	var listingsData []string

	listings.Iterate("", "", func(key string, value interface{}) bool {
		listing := value.(*Listing)
		if listing.Active {
			// Try to get image and name from onchain metadata via the registry
			// The registry can make the type assertion in the collection's realm context
			var image, name string
			metadata, err := registrydao.GetTokenMetadata(listing.NFTRealmAddress, listing.TokenId)
			if err == nil {
				image = metadata.Image
				name = metadata.Name
			}

			// If no image, use the collection's default image
			if image == "" {
				image = "https://i.imgflip.com/a6o5jb.jpg"
			}

			// If no name, use default
			if name == "" {
				name = ufmt.Sprintf("NFT #%s", listing.TokenId.String())
			}

			// Format: listingId|nftAddress|tokenId|price|seller|image|name
			listingData := ufmt.Sprintf("%d|%s|%s|%d|%s|%s|%s",
				listing.ListingId,
				listing.NFTRealmAddress.String(),
				listing.TokenId.String(),
				listing.Price,
				listing.Seller.String(),
				image,
				name,
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

	// Get NFT metadata via the registry
	// The registry can make the type assertion in the collection's realm context
	var name, description, image, uri string
	var attributes []grc721.Trait

	// Try onchain metadata via registry
	metadata, err := registrydao.GetTokenMetadata(listing.NFTRealmAddress, listing.TokenId)
	if err == nil {
		name = metadata.Name
		description = metadata.Description
		image = metadata.Image
		attributes = metadata.Attributes
	}

	// Format attributes as JSON array
	attributesJSON := "[]"
	if len(attributes) > 0 {
		attrStr := "["
		for i, attr := range attributes {
			if i > 0 {
				attrStr += ","
			}
			attrStr += ufmt.Sprintf(`{"trait_type":"%s","value":"%s"}`, attr.TraitType, attr.Value)
		}
		attrStr += "]"
		attributesJSON = attrStr
	}

	// Format JSON-like response
	output := ufmt.Sprintf(`{
  "listingId": %d,
  "tokenId": "%s",
  "price": %d,
  "seller": "%s",
  "active": %t,
  "name": "%s",
  "description": "%s",
  "image": "%s",
  "uri": "%s",
  "attributes": %s,
  "listedAt": %d
}`,
		listing.ListingId,
		listing.TokenId.String(),
		listing.Price,
		listing.Seller.String(),
		listing.Active,
		name,
		description,
		image,
		uri,
		attributesJSON,
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
