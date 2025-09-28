package trustfactor

import (
    "std"
)

// =============================================================================
// DATA STRUCTURES
// =============================================================================

// TrustScore represents a user's trust rating and associated metadata
type TrustScore struct {
    Score          float64     // Base trust score (0-10)
    LastUpdate     int64       // Unix timestamp of last update
    Evaluator      std.Address // Address of last evaluator
    TotalVotes     int         // Total number of votes received
    PositiveVotes  int         // Number of upvotes received
    NegativeVotes  int         // Number of downvotes received
    VoterWeightSum float64     // Sum of all voter weights
    Confidence     float64     // Confidence level based on vote count and quality
}

// VoteHistory tracks individual voting events for transparency
type VoteHistory struct {
    Voter     std.Address // Address of the voter
    VoteType  string      // "upvote" or "downvote"
    Weight    float64     // Weight of the voter's trust score
    Timestamp int64       // Unix timestamp of the vote
}

// UserDisplay is used for rendering user information in lists
type UserDisplay struct {
    addr           std.Address // User's address
    trust          TrustScore  // User's trust score data
    compositeScore float64     // Calculated composite score
}