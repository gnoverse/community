package gnopensea

import (
	"gno.land/p/demo/tokens/grc721"
)

// Listing structure
type Listing struct {
	ListingId       int
	NFTGetter       grc721.NFTGetter
	TokenId         grc721.TokenID
	Seller          address
	Price           int64
	Active          bool
	ListedAt        int64
	NFTRealmAddress address
}

// Sale statistics
type Sale struct {
	ListingId       int
	TokenId         string
	Buyer           address
	Seller          address
	Price           int64
	MarketplaceFee  int64
	RoyaltyFee      int64
	RoyaltyReceiver address
	SoldAt          int64
}
