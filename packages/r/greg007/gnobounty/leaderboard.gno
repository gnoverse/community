package gnobounty

import (
	"gno.land/p/moul/md"
	"gno.land/p/nt/avl"
	"gno.land/p/nt/ufmt"
)

// LeaderboardEntry holds the stats for a user
type LeaderboardEntry struct {
	Address              address
	BountiesCreated      int
	BountiesApplied      int
	ValidationsPerformed int
	Score                int
}

// GetLeaderboard aggregates stats for all users
func GetLeaderboard() []LeaderboardEntry {
	var stats avl.Tree // address -> *LeaderboardEntry

	// Count bounties created (10 points)
	bounties.Iterate("", "", func(key string, value interface{}) bool {
		if value == nil {
			return false
		}
		bounty, ok := value.(*Bounty)
		if !ok || bounty == nil {
			return false
		}
		entry := getEntry(&stats, bounty.Creator)
		entry.BountiesCreated++
		entry.Score += 10
		return false
	})

	// Count applications and validations
	applications.Iterate("", "", func(key string, value interface{}) bool {
		if value == nil {
			return false
		}
		app, ok := value.(*Application)
		if !ok || app == nil {
			return false
		}

		// Only count approved applications (20 points)
		if app.Status == StatusApproved {
			entry := getEntry(&stats, app.Applicant)
			entry.BountiesApplied++
			entry.Score += 20
		}

		// Count validations from local record (5 points)
		for _, vote := range app.Votes {
			entry := getEntry(&stats, vote.Voter)
			entry.ValidationsPerformed++
			entry.Score += 5
		}

		return false
	})

	// Convert tree to slice
	var result []LeaderboardEntry
	stats.Iterate("", "", func(key string, value interface{}) bool {
		entry := value.(*LeaderboardEntry)
		result = append(result, *entry)
		return false
	})

	// Sort by Score descending
	// Manual bubble sort since sort.Slice is not available
	for i := 0; i < len(result)-1; i++ {
		for j := 0; j < len(result)-i-1; j++ {
			if result[j].Score < result[j+1].Score {
				// Swap
				result[j], result[j+1] = result[j+1], result[j]
			}
		}
	}

	return result
}

// RenderLeaderboard renders the leaderboard page
func RenderLeaderboard() string {
	entries := GetLeaderboard()

	output := md.H1("🏆 Community Leaderboard")
	output += "Top contributors to the GnoBounty ecosystem.\n\n"
	output += md.Bold("Scoring:") + " Bounty Creation (10pts) | Approved Application (20pts) | Validation (5pts)\n\n"

	if len(entries) == 0 {
		output += "No activity recorded yet."
		return output
	}

	// Table header
	output += "| Rank | User | Score | 💰 Bounties | 📝 Applications | ⚖️ Validations |\n"
	output += "|---|---|---|---|---|---|\n"

	// Table rows
	for i, entry := range entries {
		rank := getRankDisplay(i)
		output += tableRow(
			rank,
			string(entry.Address),
			md.Bold(ufmt.Sprintf("%d", entry.Score)),
			ufmt.Sprintf("%d", entry.BountiesCreated),
			ufmt.Sprintf("%d", entry.BountiesApplied),
			ufmt.Sprintf("%d", entry.ValidationsPerformed),
		)
	}

	return output
}

// getRankDisplay returns the rank display (medal for top 3, number otherwise)
func getRankDisplay(position int) string {
	switch position {
	case 0:
		return "🥇"
	case 1:
		return "🥈"
	case 2:
		return "🥉"
	default:
		return ufmt.Sprintf("%d", position+1)
	}
}

// tableRow creates a markdown table row
func tableRow(cells ...string) string {
	output := "|"
	for _, cell := range cells {
		output += " " + cell + " |"
	}
	return output + "\n"
}

func getEntry(stats *avl.Tree, addr address) *LeaderboardEntry {
	key := string(addr)
	val, ok := stats.Get(key)
	if !ok {
		entry := &LeaderboardEntry{Address: addr}
		stats.Set(key, entry)
		return entry
	}
	return val.(*LeaderboardEntry)
}
