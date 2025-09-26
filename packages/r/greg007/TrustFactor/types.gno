package trustfactor

import (
    "std"
)

type TrustScore struct {
    Score        float64
    LastUpdate   int64
    Evaluator    std.Address
    TotalVotes   int
    PositiveVotes int
    NegativeVotes int
    VoterWeightSum float64  // Somme des poids des votants
    Confidence   float64    // Niveau de confiance basé sur le nombre de votes
}

type VoteHistory struct {
    Voter     std.Address
    VoteType  string // "upvote" ou "downvote"
    Weight    float64
    Timestamp int64
}

type UserDisplay struct {
    addr           std.Address
    trust          TrustScore
    compositeScore float64
}