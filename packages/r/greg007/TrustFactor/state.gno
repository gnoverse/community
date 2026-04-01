// Package trustfactor manages global state variables and initialization.
package trustfactor

import (
	"gno.land/p/nt/avl"
	"gno.land/p/nt/ownable"
)

var (
	// Main storage using AVL trees
	trustScores  *avl.Tree        // Main storage for user trust scores (key: address, value: *TrustScore)
	userVotes    *avl.Tree        // Tracks votes in "voter_target" format (key: string, value: bool)
	voteHistory  *avl.Tree        // Historical vote records per user (key: address, value: []VoteHistory)
	userComments *avl.Tree        // User comments storage using AVL tree (key: address, value: *avl.Tree)
	owner        *ownable.Ownable // Contract ownership management

	// Score-based index for sorted access (descending order)
	// Key format: "score_address" where score is padded for reverse lexicographic sorting
	// Value: address
	scoreIndex *avl.Tree

	// Total registered users count
	totalUsers int
)

const (
	MAX_HISTORY_SIZE = 50 // Maximum vote history entries per user
)

func init() {
	trustScores = avl.NewTree()
	userVotes = avl.NewTree()
	voteHistory = avl.NewTree()
	userComments = avl.NewTree()
	scoreIndex = avl.NewTree()
	owner = ownable.NewWithAddress(address("g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"))
}
