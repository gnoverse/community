package types

import "time"

// RequestState represents the state of a request
type RequestState int

const (
	StateRequested RequestState = iota
	StateProposed
	StateDisputed
	StateResolved
)

func (s RequestState) String() string {
	switch s {
	case StateRequested:
		return "Requested"
	case StateProposed:
		return "Proposed"
	case StateDisputed:
		return "Disputed"
	case StateResolved:
		return "Resolved"
	default:
		return "Unknown"
	}
}

// Request represents a data request
type Request struct {
	ID              string
	Requester       string
	AncillaryData   string
	YesNoQuestion   bool
	ProposedValue   int64
	Deadline        time.Time
	ResolutionTime  time.Time
	State           RequestState
	Proposer        string
	RequesterReward int64
}

// Dispute represents a dispute on a request
type Dispute struct {
	RequestID           string
	Disputer            string
	DisputeInitiatedAt  time.Time
	VoteEndTime         time.Time
	RevealEndTime       time.Time
	TotalVotes          int64
	VotesFor            int64
	VotesAgainst        int64
	Resolved            bool
}

// VoteData represents a vote commitment stored locally
type VoteData struct {
	RequestID string `json:"request_id"`
	Value     int64  `json:"value"`
	Salt      string `json:"salt"`
	Hash      string `json:"hash"`
	Timestamp int64  `json:"timestamp"`
}

// OracleParams represents oracle parameters
type OracleParams struct {
	Bond               int64
	ResolutionTime     int64
	RequesterReward    int64
	DisputeDuration    int64
	RevealDuration     int64
	VoteTokenPrice     int64
}
