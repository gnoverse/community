package goo

import (
	"time"

	"gno.land/p/demo/tokens/grc20"
	"gno.land/p/nt/avl"
)

// court.gno
type Vote struct {
	RequestId   string
	Voter       address
	TokenAmount int64
	Hash        string
	Value       int64
	Revealed    bool
}

type Voter struct {
	HasVoted  bool
	VoteIndex int64
}

type Dispute struct {
	RequestId       string
	Votes           []Vote
	NbResolvedVotes int64
	Voters          *avl.Tree
	IsResolved      bool
	WinningValue    int64
	EndTime         time.Time
	EndRevealTime   time.Time
}

// oracle.gno
type DataRequest struct {
	Id             string
	Creator        address
	Timestamp      time.Time
	AncillaryData  string
	YesNoQuestion  bool
	ProposedValue  int64
	Proposer       address
	ProposerBond   int64
	Disputer       address
	DisputerBond   int64
	ResolutionTime time.Time
	WinningValue   int64
	State          string // "Requested", "Proposed", "Disputed", "Resolved"
	Deadline       time.Time
}

// token.gno
type OOT struct {
	*grc20.Token
	*grc20.PrivateLedger
}
