package registrydao

import (
	"gno.land/p/demo/tokens/grc721"
)

// VerifyCollectionProposal - Proposal to verify a collection
type VerifyCollectionProposal struct {
	collectionAddr address
	collectionName string
	reason         string
	approved       bool
	executed       bool
}

// CollectionInfo - Extended metadata stored in the registry
type CollectionInfo struct {
	Address          address
	Name             string
	Symbol           string
	Creator          address
	RegisteredAt     int64
	Verified         bool
	Category         string
	Description      string
	ExternalURL      string
	NFTGetter        grc721.NFTGetter
	SupportsMetadata bool
}
