package trustfactor

import (
    "std"
    "strconv"
    "strings"
    "time"

    "gno.land/p/nt/ufmt"
    "gno.land/p/leon/svgbtn"
)

// =============================================================================
// URL PARAMETER EXTRACTION
// =============================================================================

// extractSearchParam extracts the search parameter from URL query string
func extractSearchParam(path string) string {
    searchVal := ""

    if strings.Contains(path, "?") {
        parts := strings.Split(path, "?")
        if len(parts) > 1 {
            params := strings.Split(parts[1], "&")
            for _, param := range params {
                keyVal := strings.Split(param, "=")
                if len(keyVal) == 2 {
                    if keyVal[0] == "search" {
                        searchVal = keyVal[1]
                    }
                }
            }
        }
    }

    return searchVal
}

// =============================================================================
// SEARCH RESULTS RENDERING
// =============================================================================

// renderSearchResults displays search results for user queries
func renderSearchResults(query string) string {
    if query == "" {
        return "Please enter an address to search."
    }

    addr := std.Address(query)
    if _, exists := GetAllUsers()[addr]; exists {
        return renderUserProfile(string(addr))
    }

    result := "# 🔍 Search results for: `" + query + "`\n\n"

    var matches []std.Address
    for addr := range GetAllUsers() {
        addrStr := string(addr)
        if len(query) >= 4 && len(addrStr) >= len(query) {
            for i := 0; i <= len(addrStr)-len(query); i++ {
                if addrStr[i:i+len(query)] == query {
                    matches = append(matches, addr)
                    break
                }
            }
        }
    }

    if len(matches) == 0 {
        result += "❌ **No users found**\n\n"
        result += "**Suggestions:**\n"
        result += "- Check the address spelling\n"
        result += "- Try with at least 4 characters\n"
        result += "- User must be registered in the system\n\n"
    } else if len(matches) == 1 {
        return renderUserProfile(string(matches[0]))
    } else {
        result += "✅ **" + strconv.Itoa(len(matches)) + " user(s) found:**\n\n"

        for _, addr := range matches {
            trust := GetTrustDetails(addr)
            compositeScore := calculateCompositeScore(trust)

            result += "### " + string(addr) + "\n"
            result += "**Trust Score:** " + ufmt.Sprintf("%.2f", compositeScore) + "/10.0 "

            if trust.Confidence >= 0.8 {
                result += "🟢"
            } else if trust.Confidence >= 0.5 {
                result += "🟡"
            } else {
                result += "🔴"
            }

            result += "\n"
            result += "**Votes:** " + strconv.Itoa(trust.TotalVotes) + " total\n\n"

            detailURL := "/r/greg007/trustfactor:" + string(addr)
            upvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Upvote&target=" + string(addr)
            downvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Downvote&target=" + string(addr)

            result += svgbtn.PrimaryButton(100, 30, "View Profile", detailURL) + " "
            result += svgbtn.SuccessButton(80, 30, "👍", upvoteURL) + " "
            result += svgbtn.DangerButton(80, 30, "👎", downvoteURL)
            result += "\n\n---\n\n"
        }
    }

    result += svgbtn.SmallButton(100, 30, "← Back", "/r/greg007/trustfactor")

    return result
}

// Render user profile
func renderUserProfile(path string) string {
    addr := std.Address(path)
    trust := GetTrustDetails(addr)

    if trust.Score == 0 && trust.LastUpdate == 0 {
        result := "# ❌ User Not Found\n\n"
        result += "No trust score found for address: `" + path + "`\n\n"
        result += "**Suggestions:**\n"
        result += "- Check that the address is correct (g1... format)\n"
        result += "- User must register first\n\n"

        backURL := "/r/greg007/trustfactor"
        result += svgbtn.PrimaryButton(150, 35, "← Back", backURL)
        return result
    }

    compositeScore := calculateCompositeScore(trust)
    result := "# 👤 Detailed Profile\n\n"
    result += "**Address:** `" + path + "`\n\n"

    result += "## 📊 Score\n"
    result += "- **Trust Score:** " + ufmt.Sprintf("%.2f", compositeScore) + "/10.0\n"
    result += "- **Confidence Level:** " + ufmt.Sprintf("%.1f%%", trust.Confidence*100) + "\n\n"

    result += "## 🗳️ Vote Statistics\n"
    result += "- **Total Votes:** " + strconv.Itoa(trust.TotalVotes) + "\n"
    result += "- **Positive Votes:** 👍 " + strconv.Itoa(trust.PositiveVotes) + "\n"
    result += "- **Negative Votes:** 👎 " + strconv.Itoa(trust.NegativeVotes) + "\n"

    if trust.TotalVotes > 0 {
        positiveRatio := float64(trust.PositiveVotes) / float64(trust.TotalVotes) * 100
        result += "- **Positive Ratio:** " + ufmt.Sprintf("%.1f%%", positiveRatio) + "\n"
    }

    result += "\n## ⏰ Time Information\n"

    // Calculate time since last update
    now := time.Now().Unix()
    daysSince := (now - trust.LastUpdate) / 86400

    timeStr := ""
    if daysSince == 0 {
        timeStr = "Today"
    } else if daysSince == 1 {
        timeStr = "1 day ago"
    } else if daysSince < 7 {
        timeStr = strconv.FormatInt(daysSince, 10) + " days ago"
    } else if daysSince < 30 {
        weeks := daysSince / 7
        timeStr = strconv.FormatInt(weeks, 10) + " week(s) ago"
    } else if daysSince < 365 {
        months := daysSince / 30
        timeStr = strconv.FormatInt(months, 10) + " month(s) ago"
    } else {
        years := daysSince / 365
        timeStr = strconv.FormatInt(years, 10) + " year(s) ago"
    }

    result += "- **Last Activity:** " + timeStr + "\n"
    result += "- **Time Impact:** " + ufmt.Sprintf("%.1f%%", getTimeDecayFactor(trust.LastUpdate)*100) + " (score freshness)\n\n"

    // Recent vote history (last 5)
    history := GetVoteHistory(addr)
    if len(history) > 0 {
        result += "## 📋 Recent Vote History\n"
        startIdx := len(history) - 5
        if startIdx < 0 {
            startIdx = 0
        }

        for i := len(history) - 1; i >= startIdx; i-- {
            vote := history[i]
            voteIcon := "👍"
            if vote.VoteType == "downvote" {
                voteIcon = "👎"
            }
            result += "- " + voteIcon + " by `" + string(vote.Voter)[:12] + "...` "
            result += "(weight: " + ufmt.Sprintf("%.1f", vote.Weight) + ")\n"
        }
        result += "\n"
    }

    result += "## 🎯 Actions\n"
    upvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Upvote&target=" + string(addr)
    downvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Downvote&target=" + string(addr)
    backURL := "/r/greg007/trustfactor"

    result += svgbtn.SuccessButton(100, 35, "👍 Upvote", upvoteURL) + " "
    result += svgbtn.DangerButton(100, 35, "👎 Downvote", downvoteURL) + " "
    result += svgbtn.PrimaryButton(100, 35, "← Back", backURL)

    return result
}

// =============================================================================
// MAIN PAGE RENDERING
// =============================================================================

// renderMainPageWithFilter displays the main page with optional search filtering
func renderMainPageWithFilter(filter string) string {
    result := "# TrustFactor Registry\n\n"

    // Registration button
    registerURL := "https://gno.land/r/greg007/trustfactor$help&func=Register"
    result += svgbtn.SuccessButton(200, 40, "✓ Register (Score: 5.0)", registerURL)
    result += "\n\n"

    result += "## 🔍 Search Users\n\n"

    if filter != "" {
        result += "**🎯 Active filter for:** `" + filter + "`\n\n"
        result += svgbtn.SmallButton(120, 30, "🗑️ Clear filter", "/r/greg007/trustfactor") + "\n\n"
    }

    result += `<gno-form>
<gno-input name="search" type="text" placeholder="Type part of the address to search..." />
</gno-form>

`

    result += "**💡 How to use search:**\n"
    result += "1. Type part of the address in the field above\n"
    result += "2. Press Enter or click Submit\n"
    result += "3. URL will change to `/r/greg007/trustfactor?search=YOUR_TERM`\n"
    result += "4. Page will reload with filtered results\n\n"

    // Popular users
    var topUsers []std.Address
    allUsers := GetAllUsers()
    for addr, trust := range allUsers {
        if trust.TotalVotes >= 3 {
            topUsers = append(topUsers, addr)
            if len(topUsers) >= 5 {
                break
            }
        }
    }

    if len(topUsers) > 0 {
        result += "**⭐ Popular Users:**\n\n"
        for i, addr := range topUsers {
            trust := GetTrustDetails(addr)
            shortAddr := string(addr)[:12] + "..."
            userURL := "/r/greg007/trustfactor:" + string(addr)
            compositeScore := calculateCompositeScore(trust)

            result += svgbtn.TextButton(140, 30, ufmt.Sprintf("🔍 %s (%.1f)", shortAddr, compositeScore), userURL)
            if i < len(topUsers)-1 {
                result += " "
            }
        }
        result += "\n\n"
    }

    result += "## Trust Scores for Addresses:\n\n"

    const USERS_PER_PAGE = 20
    offset := 0

    filteredAddrs, _ := FilterUsers(filter, USERS_PER_PAGE, offset)

    var users []UserDisplay
    for _, addr := range filteredAddrs {
        trust := GetTrustDetails(addr)
        users = append(users, UserDisplay{
            addr:           addr,
            trust:          trust,
            compositeScore: calculateCompositeScore(trust),
        })
    }

    if len(users) == 0 && filter != "" {
        result += "❌ **No users found with filter:** `" + filter + "`\n\n"
        result += "Try with a different part of the address or remove the filter.\n\n"
        return result
    }

    if len(users) == 0 {
        result += "No trust scores registered yet.\n\n"
        result += "_Click the button above to register!_\n"
        return result
    }

    for _, user := range users {
        addr := user.addr
        trust := user.trust
        compositeScore := user.compositeScore

        shortAddr := string(addr)[:12] + "..."
        detailURL := "/r/greg007/trustfactor:" + string(addr)

        result += "### " + svgbtn.TextButton(200, 30, "🔍 " + shortAddr, detailURL) + "\n"
        result += "**Trust Score:** " + ufmt.Sprintf("%.2f", compositeScore) + "/10.0"

        if trust.Confidence >= 0.8 {
            result += " 🟢"
        } else if trust.Confidence >= 0.5 {
            result += " 🟡"
        } else {
            result += " 🔴"
        }

        result += " **Votes:** " + strconv.Itoa(trust.TotalVotes)
        if trust.TotalVotes > 0 {
            ratio := float64(trust.PositiveVotes) / float64(trust.TotalVotes) * 100
            result += " (" + ufmt.Sprintf("%.0f%% positive", ratio) + ")"
        }
        result += "\n\n"

        upvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Upvote&target=" + string(addr)
        downvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Downvote&target=" + string(addr)

        result += svgbtn.SuccessButton(80, 30, "👍", upvoteURL) + " "
        result += svgbtn.DangerButton(80, 30, "👎", downvoteURL) + " "
        result += svgbtn.SmallButton(80, 30, "Details", detailURL)
        result += "\n\n---\n\n"
    }

    return result
}