package gnobounty

import (
	"time"

	"gno.land/p/nt/commondao"
)

// Bounty represents a bounty post for an issue
type Bounty struct {
	ID          uint64
	Title       string // Short title for the bounty
	IssueURL    string
	Description string
	Amount      int64 // Amount in ugnot
	Creator     address
	CreatedAt   time.Time
	IsClaimed   bool
	Claimer     address
	ClaimedAt   time.Time
}

// Application represents a claim application for a bounty with a private DAO
type Application struct {
	ID         uint64
	BountyID   uint64
	Applicant  address
	PRLink     string
	AppliedAt  time.Time
	Status     ApplicationStatus
	DAO        *commondao.CommonDAO // Private DAO for this application
	ProposalID uint64               // Proposal ID in the DAO
	Votes      []VoteRecord         // Local record of votes
}

// VoteRecord represents a vote cast by a validator
type VoteRecord struct {
	Voter  address
	Choice commondao.VoteChoice
}

// ApplicationStatus represents the status of an application
type ApplicationStatus int

const (
	StatusPending ApplicationStatus = iota
	StatusApproved
	StatusRejected
)

// Validator represents a validator who can vote on applications
type Validator struct {
	Address address
	AddedAt time.Time
	Active  bool
}
