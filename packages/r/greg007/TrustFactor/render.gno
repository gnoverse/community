package trustfactor

import (
	"strconv"

	"gno.land/p/leon/svgbtn"
	"gno.land/p/moul/md"
	"gno.land/p/moul/txlink"
	"gno.land/p/nt/ufmt"
)

// =============================================================================
// MAIN RENDERING FUNCTIONS
// =============================================================================

// renderMainPageWithFilter displays the main TrustFactor registry page with
// optional search filtering, popular users section, and paginated user listings.
func renderMainPageWithFilter(filter string) string {
	result := md.H1("TrustFactor Registry")

	registerURL := txlink.Call("Register")
	result += svgbtn.SuccessButton(200, 40, "✓ Register (Score: 4.0)", registerURL) + "\n\n"

	result += md.H2("🔍 Search Users")

	if filter != "" {
		result += md.Bold("🎯 Active filter for: ") + md.InlineCode(filter) + "\n\n"
		result += svgbtn.SmallButton(120, 30, "🗑️ Clear filter", "/r/greg007/trustfactor") + "\n\n"
	}

	result += `<gno-form>
<gno-input name="search" type="text" placeholder="Type part of the address to search..." />
</gno-form>

`

	result += md.Bold("💡 How to use search:") + "\n"
	result += md.OrderedList([]string{
		"Type part of the address in the field above",
		"Press Enter or click Submit",
		"URL will change to " + md.InlineCode("/r/greg007/trustfactor?search=YOUR_TERM"),
		"Page will reload with filtered results",
	}) + "\n"

	// Get top 5 popular users (with 3+ votes) using AVL iteration
	topUsers := GetTopUsers(5, func(addr address) bool {
		trust := GetTrustDetails(addr)
		return trust.TotalVotes >= 3
	})

	if len(topUsers) > 0 {
		result += md.Bold("⭐ Popular Users:") + "\n\n"
		for i, addr := range topUsers {
			trust := GetTrustDetails(addr)
			displayName := getDisplayName(addr)
			userURL := "/r/greg007/trustfactor:" + string(addr)
			compositeScore := calculateCompositeScore(trust)

			result += svgbtn.TextButton(140, 30, ufmt.Sprintf("🔍 %s (%.1f)", displayName, compositeScore), userURL)
			if i < len(topUsers)-1 {
				result += " "
			}
		}
		result += "\n\n"
	}

	result += md.H2("Trust Scores for Addresses:")

	const USERS_PER_PAGE = 20

	// Collect users using AVL iterator (no slice materialization)
	var users []UserDisplay
	totalMatches := FilterUsers(filter, USERS_PER_PAGE, 0, func(addr address, index int) bool {
		trust := GetTrustDetails(addr)
		users = append(users, UserDisplay{
			addr:           addr,
			trust:          trust,
			compositeScore: calculateCompositeScore(trust),
		})
		return false // Continue
	})

	if totalMatches == 0 && filter != "" {
		result += "❌ " + md.Bold("No users found with filter: ") + md.InlineCode(filter) + "\n\n"
		result += "Try with a different part of the address or remove the filter.\n\n"
		return result
	}

	if totalMatches == 0 {
		result += "No trust scores registered yet.\n\n"
		result += md.Italic("Click the button above to register!") + "\n"
		return result
	}

	for _, user := range users {
		displayName := getDisplayName(user.addr)
		detailURL := "/r/greg007/trustfactor:" + string(user.addr)

		result += md.H3(svgbtn.TextButton(200, 30, "🔍 "+displayName, detailURL))
		result += md.Italic("("+md.InlineCode(string(user.addr))+")") + "\n\n"

		result += md.Bold("Trust Score: ") + ufmt.Sprintf("%.2f", user.compositeScore) + "/10.0 " + getConfidenceIcon(user.trust.Confidence)
		result += " " + md.Bold("Votes: ") + strconv.Itoa(user.trust.TotalVotes)

		if user.trust.TotalVotes > 0 {
			ratio := float64(user.trust.PositiveVotes) / float64(user.trust.TotalVotes) * 100
			result += " (" + ufmt.Sprintf("%.0f%% positive", ratio) + ")"
		}
		result += "\n\n"

		upvoteURL := txlink.Call("Upvote", "target", string(user.addr))
		downvoteURL := txlink.Call("Downvote", "target", string(user.addr))

		result += svgbtn.SuccessButton(80, 30, "👍", upvoteURL) + " "
		result += svgbtn.DangerButton(80, 30, "👎", downvoteURL) + " "
		result += svgbtn.SmallButton(80, 30, "Details", detailURL)
		result += "\n\n" + md.HorizontalRule()
	}

	return result
}

// renderUserProfile generates a detailed user profile page including trust score,
// voting statistics, vote history, and comments section.
func renderUserProfile(path string) string {
	addr := address(path)
	trust := GetTrustDetails(addr)

	if trust.Score == 0 && trust.LastUpdate == 0 {
		result := md.H1("❌ User Not Found") + "\n"
		result += "No trust score found for address: `" + path + "`\n\n"
		result += md.Bold("Suggestions:") + "\n"
		result += md.BulletList([]string{
			"Check that the address is correct (g1... format)",
			"User must register first",
		}) + "\n"
		result += svgbtn.PrimaryButton(150, 35, "← Back", "/r/greg007/trustfactor")
		return result
	}

	displayName := getDisplayName(addr)
	result := md.H2("👤 Profile: " + displayName)
	result += md.Italic(md.InlineCode(path)) + "\n\n"

	result += md.H2("📊 Score")
	result += GenerateTrustWidget(addr) + "\n\n"
	result += md.BulletList([]string{
		"**Confidence Level:** " + ufmt.Sprintf("%.1f%%", trust.Confidence*100),
	}) + "\n"

	result += md.H2("🗳️ Vote Statistics")
	voteItems := []string{
		"**Total Votes:** " + strconv.Itoa(trust.TotalVotes),
		"**Positive Votes:** 👍 " + strconv.Itoa(trust.PositiveVotes),
		"**Negative Votes:** 👎 " + strconv.Itoa(trust.NegativeVotes),
	}
	if trust.TotalVotes > 0 {
		positiveRatio := float64(trust.PositiveVotes) / float64(trust.TotalVotes) * 100
		voteItems = append(voteItems, "**Positive Ratio:** "+ufmt.Sprintf("%.1f%%", positiveRatio))
	}
	result += md.BulletList(voteItems) + "\n"

	result += md.H2("⏰ Time Information")
	result += md.BulletList([]string{
		"**Last Activity:** " + formatTimeAgo(trust.LastUpdate),
		"**Time Impact:** " + ufmt.Sprintf("%.1f%%", getTimeDecayFactor(trust.LastUpdate)*100) + " (score freshness)",
	}) + "\n"

	history := GetVoteHistory(addr)
	if len(history) > 0 {
		result += md.H2("📋 Recent Vote History")
		startIdx := len(history) - 5
		if startIdx < 0 {
			startIdx = 0
		}

		historyItems := []string{}
		for i := len(history) - 1; i >= startIdx; i-- {
			vote := history[i]
			voteIcon := "👍"
			if vote.VoteType == "downvote" {
				voteIcon = "👎"
			}
			voterName := getDisplayName(vote.Voter)
			historyItems = append(historyItems, voteIcon+" by "+md.InlineCode(voterName)+" (weight: "+ufmt.Sprintf("%.1f", vote.Weight)+")")
		}
		result += md.BulletList(historyItems) + "\n"
	}

	result += md.H2("🎯 Actions")
	upvoteURL := txlink.Call("Upvote", "target", string(addr))
	downvoteURL := txlink.Call("Downvote", "target", string(addr))

	result += svgbtn.SuccessButton(100, 35, "👍 Upvote", upvoteURL) + " "
	result += svgbtn.DangerButton(100, 35, "👎 Downvote", downvoteURL) + " "
	result += svgbtn.PrimaryButton(100, 35, "← Back", "/r/greg007/trustfactor") + "\n\n"

	result += md.H2("💬 Comments (" + strconv.Itoa(GetCommentCount(addr)) + ")")
	commentURL := txlink.NewLink("AddComment").
		AddArgs("target", string(addr), "text", "").
		URL()
	result += svgbtn.PrimaryButton(150, 35, "💬 Leave a comment", commentURL) + "\n\n"

	comments := GetComments(addr)
	if len(comments) > 0 {
		result += md.Bold("Recent comments:") + "\n\n"
		displayCount := 10
		if len(comments) < displayCount {
			displayCount = len(comments)
		}

		for i := 0; i < displayCount; i++ {
			comment := comments[i]
			authorName := getDisplayName(comment.Author)

			result += md.HorizontalRule()
			result += md.Bold(authorName) + " - " + md.Italic(formatTimeAgo(comment.Timestamp)) + "\n\n"
			result += md.Blockquote(comment.Text)
		}
	} else {
		result += md.Italic("No comments yet. Be the first to comment!") + "\n\n"
	}

	return result
}

// renderSearchResults displays filtered user search results based on the query string.
// If the query exactly matches an address, the user's profile is shown directly.
// Otherwise, partial matches are displayed with their trust scores and action buttons.
func renderSearchResults(query string) string {
	if query == "" {
		return "Please enter an address to search."
	}

	addr := address(query)
	if _, exists := trustScores.Get(string(addr)); exists {
		return renderUserProfile(string(addr))
	}

	result := md.H1("🔍 Search results for: " + md.InlineCode(query))

	// Collect matches using AVL iterator
	var matches []address
	matchCount := FilterUsers(query, 100, 0, func(addr address, index int) bool {
		matches = append(matches, addr)
		return false // Continue
	})

	if matchCount == 0 {
		result += "❌ " + md.Bold("No users found") + "\n\n"
		result += md.Bold("Suggestions:") + "\n"
		result += md.BulletList([]string{
			"Check the address spelling",
			"Try with at least 4 characters",
			"User must be registered in the system",
		}) + "\n"
	} else if matchCount == 1 {
		return renderUserProfile(string(matches[0]))
	} else {
		result += "✅ " + md.Bold(strconv.Itoa(matchCount)+" user(s) found:") + "\n\n"

		for _, addr := range matches {
			trust := GetTrustDetails(addr)
			compositeScore := calculateCompositeScore(trust)
			displayName := getDisplayName(addr)

			result += md.H3(displayName)
			result += md.Italic("("+md.InlineCode(string(addr))+")") + "\n\n"
			result += md.Bold("Trust Score: ") + ufmt.Sprintf("%.2f", compositeScore) + "/10.0 " + getConfidenceIcon(trust.Confidence) + "\n"
			result += md.Bold("Votes: ") + strconv.Itoa(trust.TotalVotes) + " total\n\n"

			detailURL := "/r/greg007/trustfactor:" + string(addr)
			upvoteURL := txlink.Call("Upvote", "target", string(addr))
			downvoteURL := txlink.Call("Downvote", "target", string(addr))

			result += svgbtn.PrimaryButton(100, 30, "View Profile", detailURL) + " "
			result += svgbtn.SuccessButton(80, 30, "👍", upvoteURL) + " "
			result += svgbtn.DangerButton(80, 30, "👎", downvoteURL)
			result += "\n\n" + md.HorizontalRule()
		}
	}

	result += svgbtn.SmallButton(100, 30, "← Back", "/r/greg007/trustfactor")
	return result
}
