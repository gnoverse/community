package trustfactor

import (
    "std"
    "strings"
    "time"
)

// =============================================================================
// GLOBAL STATE VARIABLES
// =============================================================================

var trustScores map[std.Address]TrustScore        // Main storage for user trust scores
var userVotes map[string]bool                     // Tracks votes in "voter_target" format
var voteHistory map[std.Address][]VoteHistory     // Historical vote records per user
var owner std.Address                             // Contract owner address

// Performance optimization cache
var sortedUsers []std.Address // Cached sorted user list
var lastSortTime int64        // Last cache update timestamp
var totalUsers int            // Total registered users count

// =============================================================================
// CONSTANTS
// =============================================================================

const MAX_HISTORY_SIZE = 50   // Maximum vote history entries per user
const SORT_CACHE_TTL = 300    // Cache time-to-live in seconds

// =============================================================================
// INITIALIZATION
// =============================================================================

func init() {
    trustScores = make(map[std.Address]TrustScore)
    userVotes = make(map[string]bool)
    voteHistory = make(map[std.Address][]VoteHistory)
    owner = std.Address("g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5")

    sortedUsers = make([]std.Address, 0)
    lastSortTime = 0
    totalUsers = 0
}

// =============================================================================
// USER REGISTRATION
// =============================================================================

// Register allows a user to join the TrustFactor system with an initial score of 5.0
func Register(_ realm) {
    caller := std.PreviousRealm().Address()

    if _, exists := trustScores[caller]; exists {
        panic("user already registered")
    }

    trustScores[caller] = TrustScore{
        Score:          5.0,
        LastUpdate:     time.Now().Unix(),
        Evaluator:      caller,
        TotalVotes:     0,
        PositiveVotes:  0,
        NegativeVotes:  0,
        VoterWeightSum: 0.0,
        Confidence:     0.0,
    }

    totalUsers++
    invalidateCache()
}

// =============================================================================
// BASIC GETTER FUNCTIONS
// =============================================================================

// GetTrustScore returns the raw trust score for a user
func GetTrustScore(addr std.Address) (float64, bool) {
    trust, exists := trustScores[addr]
    if !exists {
        return 0.0, false
    }
    return trust.Score, true
}

// GetCompositeScore returns the calculated composite score (with time decay and confidence)
func GetCompositeScore(addr std.Address) (float64, bool) {
    trust, exists := trustScores[addr]
    if !exists {
        return 0.0, false
    }
    return calculateCompositeScore(trust), true
}

// GetTrustDetails returns the complete TrustScore struct for a user
func GetTrustDetails(addr std.Address) TrustScore {
    trust, exists := trustScores[addr]
    if !exists {
        return TrustScore{Score: 0, LastUpdate: 0, Evaluator: ""}
    }
    return trust
}

// =============================================================================
// SCORE CALCULATION ALGORITHMS
// =============================================================================

// getTimeDecayFactor calculates how much a score should decay based on time elapsed
// More recent updates maintain higher scores
func getTimeDecayFactor(timestamp int64) float64 {
    now := time.Now().Unix()
    daysSince := float64(now-timestamp) / 86400.0

    if daysSince <= 7.0 {
        return 1.0   // No decay for recent activity
    } else if daysSince <= 30.0 {
        return 0.95  // Slight decay after a week
    } else if daysSince <= 90.0 {
        return 0.85  // Moderate decay after a month
    } else {
        return 0.7   // Higher decay for old scores
    }
}

// calculateConfidence determines confidence level based on vote quantity and voter quality
func calculateConfidence(totalVotes int, voterWeightSum float64, positiveVotes int) float64 {
    if totalVotes == 0 {
        return 0.0
    }

    voteConfidence := float64(totalVotes) / (float64(totalVotes) + 5.0)
    avgVoterWeight := voterWeightSum / float64(totalVotes)
    weightConfidence := avgVoterWeight / 10.0
    positiveRatio := float64(positiveVotes) / float64(totalVotes)
    positivityFactor := 0.5 + (positiveRatio-0.5)*1.0
    baseConfidence := (voteConfidence * 0.4) + (weightConfidence * 0.3)
    return baseConfidence * positivityFactor
}

// calculateCompositeScore computes the final score using base score, time decay, and confidence
func calculateCompositeScore(trust TrustScore) float64 {
    baseScore := trust.Score
    timeFactor := getTimeDecayFactor(trust.LastUpdate)
    confidence := calculateConfidence(trust.TotalVotes, trust.VoterWeightSum, trust.PositiveVotes)
    timeAdjustedScore := baseScore * timeFactor
    confidenceMultiplier := 1.0 + (confidence-0.5)*0.4
    finalScore := timeAdjustedScore * confidenceMultiplier

    // Clamp to valid range
    if finalScore > 10.0 {
        return 10.0
    } else if finalScore < 0.0 {
        return 0.0
    }

    return finalScore
}

// =============================================================================
// VOTING FUNCTIONS
// =============================================================================

// Upvote increases a user's trust score based on the voter's own reputation
func Upvote(_ realm, target std.Address) {
    caller := std.PreviousRealm().Address()

    voterTrust, voterExists := trustScores[caller]
    if !voterExists {
        panic("voter must be registered")
    }

    targetTrust, targetExists := trustScores[target]
    if !targetExists {
        panic("target user not registered")
    }

    if caller == target {
        panic("cannot vote for yourself")
    }

    voteKey := string(caller) + "_" + string(target)
    if userVotes[voteKey] {
        panic("already voted for this user")
    }

    // Calculate weighted impact based on voter reputation
    voterWeight := calculateCompositeScore(voterTrust)
    impact := (voterWeight / 10.0) * 0.3 // Maximum impact of 0.3 points
    if impact < 0.05 {
        impact = 0.05 // Minimum impact to prevent zero effect
    }

    newScore := targetTrust.Score + impact
    if newScore > 10.0 {
        newScore = 10.0
    }

    // Add to vote history with size limit
    voteEntry := VoteHistory{
        Voter:     caller,
        VoteType:  "upvote",
        Weight:    voterWeight,
        Timestamp: time.Now().Unix(),
    }

    history := voteHistory[target]
    if len(history) >= MAX_HISTORY_SIZE {
        history = history[len(history)-(MAX_HISTORY_SIZE-1):]
    }
    voteHistory[target] = append(history, voteEntry)

    updatedTrust := TrustScore{
        Score:          newScore,
        LastUpdate:     time.Now().Unix(),
        Evaluator:      caller,
        TotalVotes:     targetTrust.TotalVotes + 1,
        PositiveVotes:  targetTrust.PositiveVotes + 1,
        NegativeVotes:  targetTrust.NegativeVotes,
        VoterWeightSum: targetTrust.VoterWeightSum + voterWeight,
        Confidence:     calculateConfidence(targetTrust.TotalVotes+1, targetTrust.VoterWeightSum+voterWeight, targetTrust.PositiveVotes+1),
    }

    trustScores[target] = updatedTrust

    userVotes[voteKey] = true
    invalidateCache()
}

// Downvote decreases a user's trust score based on the voter's own reputation
func Downvote(_ realm, target std.Address) {
    caller := std.PreviousRealm().Address()

    voterTrust, voterExists := trustScores[caller]
    if !voterExists {
        panic("voter must be registered")
    }

    targetTrust, targetExists := trustScores[target]
    if !targetExists {
        panic("target user not registered")
    }

    if caller == target {
        panic("cannot vote for yourself")
    }

    voteKey := string(caller) + "_" + string(target)
    if userVotes[voteKey] {
        panic("already voted for this user")
    }

    // Calculate weighted impact based on voter reputation
    voterWeight := calculateCompositeScore(voterTrust)
    impact := (voterWeight / 10.0) * 0.3 // Maximum impact of 0.3 points
    if impact < 0.05 {
        impact = 0.05 // Minimum impact to prevent zero effect
    }

    newScore := targetTrust.Score - impact
    if newScore < 0.0 {
        newScore = 0.0
    }

    // Add to vote history with size limit
    voteEntry := VoteHistory{
        Voter:     caller,
        VoteType:  "downvote",
        Weight:    voterWeight,
        Timestamp: time.Now().Unix(),
    }

    history := voteHistory[target]
    if len(history) >= MAX_HISTORY_SIZE {
        history = history[len(history)-(MAX_HISTORY_SIZE-1):]
    }
    voteHistory[target] = append(history, voteEntry)

    updatedTrust := TrustScore{
        Score:          newScore,
        LastUpdate:     time.Now().Unix(),
        Evaluator:      caller,
        TotalVotes:     targetTrust.TotalVotes + 1,
        PositiveVotes:  targetTrust.PositiveVotes,
        NegativeVotes:  targetTrust.NegativeVotes + 1,
        VoterWeightSum: targetTrust.VoterWeightSum + voterWeight,
        Confidence:     calculateConfidence(targetTrust.TotalVotes+1, targetTrust.VoterWeightSum+voterWeight, targetTrust.PositiveVotes),
    }

    trustScores[target] = updatedTrust

    userVotes[voteKey] = true
    invalidateCache()
}

// =============================================================================
// DATA ACCESS FUNCTIONS
// =============================================================================

// GetAllUsers returns the complete trust scores map (used internally)
func GetAllUsers() map[std.Address]TrustScore {
    return trustScores
}

// GetVoteHistory returns the voting history for a specific user
func GetVoteHistory(addr std.Address) []VoteHistory {
    return voteHistory[addr]
}

// =============================================================================
// PERFORMANCE OPTIMIZATION - CACHING & SORTING
// =============================================================================

// invalidateCache clears the sorted user cache when data changes
func invalidateCache() {
    lastSortTime = 0
    sortedUsers = make([]std.Address, 0)
}

// GetSortedUsers returns users sorted by composite score with caching
func GetSortedUsers() []std.Address {
    now := time.Now().Unix()

    // Check if cache is still valid
    if now-lastSortTime < SORT_CACHE_TTL && len(sortedUsers) == totalUsers {
        return sortedUsers
    }

    // Rebuild cache if expired or invalid
    return rebuildSortCache()
}

// rebuildSortCache rebuilds the sorted user cache using optimized quicksort
func rebuildSortCache() []std.Address {
    // Convert map to slice for sorting
    users := make([]std.Address, 0, len(trustScores))
    for addr := range trustScores {
        users = append(users, addr)
    }

    // Quicksort by composite score (descending)
    quickSortByScore(users, 0, len(users)-1)

    // Update cache
    sortedUsers = users
    lastSortTime = time.Now().Unix()
    totalUsers = len(users)

    return sortedUsers
}

// quickSortByScore implements quicksort algorithm for user addresses by composite score
func quickSortByScore(users []std.Address, low, high int) {
    if low < high {
        pi := partitionByScore(users, low, high)
        quickSortByScore(users, low, pi-1)
        quickSortByScore(users, pi+1, high)
    }
}

// partitionByScore partitions the array for quicksort (descending order)
func partitionByScore(users []std.Address, low, high int) int {
    pivotScore := calculateCompositeScore(trustScores[users[high]])
    i := low - 1

    for j := low; j < high; j++ {
        currentScore := calculateCompositeScore(trustScores[users[j]])
        if currentScore > pivotScore {
            i++
            users[i], users[j] = users[j], users[i]
        }
    }

    users[i+1], users[high] = users[high], users[i+1]
    return i + 1
}

// =============================================================================
// SEARCH AND FILTERING
// =============================================================================

// FilterUsers returns paginated and filtered user results
func FilterUsers(searchTerm string, limit int, offset int) ([]std.Address, int) {
    if searchTerm == "" {
        sorted := GetSortedUsers()
        total := len(sorted)

        end := offset + limit
        if end > total {
            end = total
        }
        if offset > total {
            return []std.Address{}, total
        }

        return sorted[offset:end], total
    }

    var filtered []std.Address
    for _, addr := range GetSortedUsers() {
        addrStr := string(addr)
        if containsSubstring(addrStr, searchTerm) {
            filtered = append(filtered, addr)
        }
    }

    total := len(filtered)
    end := offset + limit
    if end > total {
        end = total
    }
    if offset > total {
        return []std.Address{}, total
    }

    return filtered[offset:end], total
}

// containsSubstring checks if a string contains a substring (case-sensitive)
func containsSubstring(str, substr string) bool {
    if len(substr) == 0 {
        return true
    }
    if len(substr) > len(str) {
        return false
    }

    for i := 0; i <= len(str)-len(substr); i++ {
        match := true
        for j := 0; j < len(substr); j++ {
            if str[i+j] != substr[j] {
                match = false
                break
            }
        }
        if match {
            return true
        }
    }
    return false
}

// GetPerformanceStats returns cache and performance statistics
func GetPerformanceStats() (int, int, int64) {
    return totalUsers, len(sortedUsers), lastSortTime
}

// =============================================================================
// PUBLIC API FOR OTHER REALMS
// =============================================================================

// QueryTrustScore returns the calculated composite trust score for external use
func QueryTrustScore(addr std.Address) (float64, bool) {
    trust, exists := trustScores[addr]
    if !exists {
        return 0.0, false
    }
    return calculateCompositeScore(trust), true
}

// QueryUserDetails returns comprehensive user information for external realms
func QueryUserDetails(addr std.Address) (float64, int, float64, bool) {
    trust, exists := trustScores[addr]
    if !exists {
        return 0.0, 0, 0.0, false
    }

    compositeScore := calculateCompositeScore(trust)
    return compositeScore, trust.TotalVotes, trust.Confidence, true
}

// IsTrustedUser checks if a user meets a minimum trust threshold
func IsTrustedUser(addr std.Address, minScore float64) bool {
    score, exists := QueryTrustScore(addr)
    return exists && score >= minScore
}

// GetUserRank returns the user's position in the trust leaderboard
func GetUserRank(addr std.Address) (int, int, bool) {
    sortedUsers := GetSortedUsers()

    for i, userAddr := range sortedUsers {
        if userAddr == addr {
            return i + 1, len(sortedUsers), true
        }
    }

    return 0, len(sortedUsers), false
}

// GetTopTrustedUsers returns the N most trusted users
func GetTopTrustedUsers(limit int) []std.Address {
    sortedUsers := GetSortedUsers()

    if limit > len(sortedUsers) {
        limit = len(sortedUsers)
    }

    result := make([]std.Address, limit)
    copy(result, sortedUsers[:limit])
    return result
}

// GetScoreFreshness returns how many days since the user's last score update
func GetScoreFreshness(addr std.Address) (int64, bool) {
    trust, exists := trustScores[addr]
    if !exists {
        return 0, false
    }

    now := time.Now().Unix()
    daysSince := (now - trust.LastUpdate) / 86400
    return daysSince, true
}

// =============================================================================
// ADMIN FUNCTIONS (OWNER ONLY)
// =============================================================================

// onlyOwner ensures only the contract owner can call admin functions
func onlyOwner() {
    caller := std.PreviousRealm().Address()
    if caller != owner {
        panic("only owner can call this function")
    }
}

// RemoveUser removes a malicious user from the system (emergency function)
func RemoveUser(target std.Address) {
    onlyOwner()

    delete(trustScores, target)
    delete(voteHistory, target)

    // Clean up all votes involving the target user
    for key := range userVotes {
        if strings.Contains(key, string(target)) {
            delete(userVotes, key)
        }
    }

    totalUsers--
    invalidateCache()
}

// TransferOwnership transfers contract ownership to a new address
func TransferOwnership(newOwner std.Address) {
    onlyOwner()
    owner = newOwner
}

