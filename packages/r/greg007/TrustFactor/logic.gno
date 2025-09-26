package trustfactor

import (
    "std"
    "strings"
    "time"
)

var trustScores map[std.Address]TrustScore
var userVotes map[string]bool // "voter_target" format to track votes
var voteHistory map[std.Address][]VoteHistory
var owner std.Address

// Performance cache
var sortedUsers []std.Address
var lastSortTime int64
var totalUsers int

const MAX_HISTORY_SIZE = 50
const SORT_CACHE_TTL = 300 // Cache TTL in seconds

func init() {
    trustScores = make(map[std.Address]TrustScore)
    userVotes = make(map[string]bool)
    voteHistory = make(map[std.Address][]VoteHistory)
    owner = std.Address("g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5")

    sortedUsers = make([]std.Address, 0)
    lastSortTime = 0
    totalUsers = 0
}

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

func GetTrustScore(addr std.Address) (float64, bool) {
    trust, exists := trustScores[addr]
    if !exists {
        return 0.0, false
    }
    return trust.Score, true
}

func GetCompositeScore(addr std.Address) (float64, bool) {
    trust, exists := trustScores[addr]
    if !exists {
        return 0.0, false
    }
    return calculateCompositeScore(trust), true
}

func GetTrustDetails(addr std.Address) TrustScore {
    trust, exists := trustScores[addr]
    if !exists {
        return TrustScore{Score: 0, LastUpdate: 0, Evaluator: ""}
    }
    return trust
}

// Calculate temporal decay factor
func getTimeDecayFactor(timestamp int64) float64 {
    now := time.Now().Unix()
    daysSince := float64(now-timestamp) / 86400.0

    if daysSince <= 7.0 {
        return 1.0
    } else if daysSince <= 30.0 {
        return 0.95
    } else if daysSince <= 90.0 {
        return 0.85
    } else {
        return 0.7
    }
}

// Calculate confidence based on vote count and voter quality
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

// Calculate advanced composite score
func calculateCompositeScore(trust TrustScore) float64 {
    baseScore := trust.Score
    timeFactor := getTimeDecayFactor(trust.LastUpdate)
    confidence := calculateConfidence(trust.TotalVotes, trust.VoterWeightSum, trust.PositiveVotes)
    timeAdjustedScore := baseScore * timeFactor
    confidenceMultiplier := 1.0 + (confidence-0.5)*0.4
    finalScore := timeAdjustedScore * confidenceMultiplier

    if finalScore > 10.0 {
        return 10.0
    } else if finalScore < 0.0 {
        return 0.0
    }

    return finalScore
}

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
    impact := (voterWeight / 10.0) * 0.3 // Impact maximal de 0.3 points
    if impact < 0.05 {
        impact = 0.05
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
    impact := (voterWeight / 10.0) * 0.3 // Impact maximal de 0.3 points
    if impact < 0.05 {
        impact = 0.05
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

func GetAllUsers() map[std.Address]TrustScore {
    return trustScores
}

func GetVoteHistory(addr std.Address) []VoteHistory {
    return voteHistory[addr]
}

// Invalide le cache de tri
func invalidateCache() {
    lastSortTime = 0
    sortedUsers = make([]std.Address, 0)
}

// Retourne les utilisateurs triés avec cache
func GetSortedUsers() []std.Address {
    now := time.Now().Unix()

    // Vérifier si le cache est valide
    if now-lastSortTime < SORT_CACHE_TTL && len(sortedUsers) == totalUsers {
        return sortedUsers
    }

    // Reconstruire le cache
    return rebuildSortCache()
}

// Reconstruit le cache de tri - Quick Sort optimisé
func rebuildSortCache() []std.Address {
    // Convertir la map en slice pour le tri
    users := make([]std.Address, 0, len(trustScores))
    for addr := range trustScores {
        users = append(users, addr)
    }

    // Quick sort par score composite (décroissant)
    quickSortByScore(users, 0, len(users)-1)

    // Mettre à jour le cache
    sortedUsers = users
    lastSortTime = time.Now().Unix()
    totalUsers = len(users)

    return sortedUsers
}

func quickSortByScore(users []std.Address, low, high int) {
    if low < high {
        pi := partitionByScore(users, low, high)
        quickSortByScore(users, low, pi-1)
        quickSortByScore(users, pi+1, high)
    }
}

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

// Optimized search with filtering
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

func GetPerformanceStats() (int, int, int64) {
    return totalUsers, len(sortedUsers), lastSortTime
}

// PUBLIC API FOR OTHER REALMS

// Main function to get user trust score
func QueryTrustScore(addr std.Address) (float64, bool) {
    trust, exists := trustScores[addr]
    if !exists {
        return 0.0, false
    }
    return calculateCompositeScore(trust), true
}

// Get complete user details
func QueryUserDetails(addr std.Address) (float64, int, float64, bool) {
    trust, exists := trustScores[addr]
    if !exists {
        return 0.0, 0, 0.0, false
    }

    compositeScore := calculateCompositeScore(trust)
    return compositeScore, trust.TotalVotes, trust.Confidence, true
}

// Check if user meets minimum trust threshold
func IsTrustedUser(addr std.Address, minScore float64) bool {
    score, exists := QueryTrustScore(addr)
    return exists && score >= minScore
}

// Get user rank in leaderboard
func GetUserRank(addr std.Address) (int, int, bool) {
    sortedUsers := GetSortedUsers()

    for i, userAddr := range sortedUsers {
        if userAddr == addr {
            return i + 1, len(sortedUsers), true
        }
    }

    return 0, len(sortedUsers), false
}

// Get top N most trusted users
func GetTopTrustedUsers(limit int) []std.Address {
    sortedUsers := GetSortedUsers()

    if limit > len(sortedUsers) {
        limit = len(sortedUsers)
    }

    result := make([]std.Address, limit)
    copy(result, sortedUsers[:limit])
    return result
}

// Check score freshness (days since last update)
func GetScoreFreshness(addr std.Address) (int64, bool) {
    trust, exists := trustScores[addr]
    if !exists {
        return 0, false
    }

    now := time.Now().Unix()
    daysSince := (now - trust.LastUpdate) / 86400
    return daysSince, true
}

// MINIMAL ADMIN FUNCTIONS (OWNER ONLY)

func onlyOwner() {
    caller := std.PreviousRealm().Address()
    if caller != owner {
        panic("only owner can call this function")
    }
}

// Emergency function to remove malicious user
func RemoveUser(target std.Address) {
    onlyOwner()

    delete(trustScores, target)
    delete(voteHistory, target)

    // Clean up user votes
    for key := range userVotes {
        if strings.Contains(key, string(target)) {
            delete(userVotes, key)
        }
    }

    totalUsers--
    invalidateCache()
}

// Transfer ownership
func TransferOwnership(newOwner std.Address) {
    onlyOwner()
    owner = newOwner
}

