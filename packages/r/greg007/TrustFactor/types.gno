package trustfactor

// TrustScore represents a user's trust rating and associated metadata.
type TrustScore struct {
	Score          float64 // Base trust score (0-10)
	LastUpdate     int64   // Unix timestamp of last update
	Evaluator      address // Address of last evaluator
	TotalVotes     int     // Total number of votes received
	PositiveVotes  int     // Number of upvotes received
	NegativeVotes  int     // Number of downvotes received
	VoterWeightSum float64 // Sum of all voter weights
	Confidence     float64 // Confidence level based on vote count and quality
}

// VoteHistory tracks individual voting events for transparency and audit purposes.
type VoteHistory struct {
	Voter     address // Address of the voter
	VoteType  string  // "upvote" or "downvote"
	Weight    float64 // Weight of the voter's trust score
	Timestamp int64   // Unix timestamp of the vote
}

// UserDisplay is used for rendering user information in paginated lists.
type UserDisplay struct {
	addr           address    // User's address
	trust          TrustScore // User's trust score data
	compositeScore float64    // Calculated composite score
}

// Comment represents a user comment on a profile.
type Comment struct {
	Author    address // Address of the comment author
	Text      string  // Comment text content
	Timestamp int64   // Unix timestamp of the comment
}
