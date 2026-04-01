// Package trustfactor provides score index management using AVL-based sorted access.
package trustfactor

import (
	"strings"

	"gno.land/p/nt/avl"
	"gno.land/p/nt/ufmt"
)

// makeScoreKey creates a lexicographically sortable key for the scoreIndex.
// Format: "inverted_score_address" where inverted_score ensures descending order.
//
// To achieve descending order with lexicographic sorting, we invert the score:
// - Max score (10.0) becomes "0000000000" (sorts first)
// - Min score (0.0) becomes "9999999999" (sorts last)
//
// The formula: inverted = 9999999999 - (score * 100000000)
// This gives us precision to 2 decimal places and proper ordering.
func makeScoreKey(score float64, addr address) string {
	// Convert score (0.00-10.00) to integer with 8 decimal precision
	// Then invert for descending order
	scoreInt := int64(score * 100000000)
	inverted := 9999999999 - scoreInt

	// Pad to 10 digits and append address
	return ufmt.Sprintf("%010d_%s", inverted, string(addr))
}

// addToScoreIndex adds a user to the score-based index
func addToScoreIndex(addr address, trust TrustScore) {
	score := calculateCompositeScore(trust)
	key := makeScoreKey(score, addr)
	scoreIndex.Set(key, addr)
}

// removeFromScoreIndex removes a user's old score entry from the index
func removeFromScoreIndex(addr address, trust TrustScore) {
	score := calculateCompositeScore(trust)
	key := makeScoreKey(score, addr)
	scoreIndex.Remove(key)
}

// updateScoreIndex updates a user's position in the score index
// This is called whenever a user's score changes
func updateScoreIndex(addr address, oldTrust, newTrust TrustScore) {
	// Remove old entry
	removeFromScoreIndex(addr, oldTrust)

	// Add new entry
	addToScoreIndex(addr, newTrust)
}

// IterateSortedUsers iterates over all users in descending score order.
// Callback receives (address, index) and returns true to stop iteration.
func IterateSortedUsers(callback func(addr address, index int) bool) {
	index := 0
	scoreIndex.Iterate("", "", func(key string, value interface{}) bool {
		shouldStop := callback(value.(address), index)
		index++
		return shouldStop
	})
}

// GetTopUsers returns the top N users without materializing full sorted list.
// Uses direct AVL iteration for efficiency.
func GetTopUsers(limit int, filter func(address) bool) []address {
	result := make([]address, 0, limit)

	scoreIndex.Iterate("", "", func(key string, value interface{}) bool {
		addr := value.(address)

		// Apply filter if provided
		if filter != nil && !filter(addr) {
			return false // Continue to next
		}

		result = append(result, addr)
		return len(result) >= limit // Stop when limit reached
	})

	return result
}

// FilterUsers iterates over filtered and paginated users using pure AVL iteration.
// Returns total count and invokes callback for each result in the page.
// Callback receives (address, index) and returns true to stop iteration.
// No slices are materialized - works directly with AVL tree.
func FilterUsers(searchTerm string, limit int, offset int, callback func(addr address, index int) bool) int {
	if searchTerm == "" {
		// No filter - iterate paginated results directly from AVL tree
		index := 0
		total := scoreIndex.Size()
		pageIndex := 0

		scoreIndex.Iterate("", "", func(key string, value interface{}) bool {
			if index >= offset && index < offset+limit {
				shouldStop := callback(value.(address), pageIndex)
				pageIndex++
				if shouldStop {
					return true
				}
			}
			index++
			return index >= offset+limit // Stop after processing page
		})

		return total
	}

	// With filter - need two passes: count matches, then paginate
	// First pass: build filtered index (unavoidable for search)
	filteredTree := avl.NewTree()
	matchCount := 0

	scoreIndex.Iterate("", "", func(key string, value interface{}) bool {
		addr := value.(address)
		addrStr := string(addr)
		if containsSubstring(addrStr, searchTerm) {
			// Preserve sort order by using sequential keys
			filteredTree.Set(ufmt.Sprintf("%010d", matchCount), addr)
			matchCount++
		}
		return false // Continue iteration
	})

	// Second pass: iterate paginated results from filtered tree
	index := 0
	pageIndex := 0
	filteredTree.Iterate("", "", func(key string, value interface{}) bool {
		if index >= offset && index < offset+limit {
			shouldStop := callback(value.(address), pageIndex)
			pageIndex++
			if shouldStop {
				return true
			}
		}
		index++
		return index >= offset+limit
	})

	return matchCount
}

// containsSubstring checks if a string contains a substring (case-sensitive)
func containsSubstring(str, substr string) bool {
	return strings.Index(str, substr) >= 0
}

// GetPerformanceStats returns system statistics
func GetPerformanceStats() (int, int) {
	return totalUsers, scoreIndex.Size()
}
