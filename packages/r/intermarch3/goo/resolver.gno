// Package goo contains the resolver logic for the GOO.
// It supports both Yes/No and Numeric resolutions.
// It is used to determine the winning value of a dispute and reward the voters.
package goo

import (
	"chain"
	"chain/runtime"
)

func resolve(id string) int64 {
	dispute := getDispute(id)
	request := getRequest(id)

	if dispute.NbResolvedVotes == 0 {
		// If no one voted or reveal their vote, the proposed value wins by default
		return request.ProposedValue
	}

	if request.YesNoQuestion {
		return resolveYesNo(dispute)
	}
	return resolveNumeric(dispute)
}

// resolveYesNo determines the winning value for yes/no disputes based on the highest total token weight.
// If 0 votes or equal votes, the proposed value wins by default.
func resolveYesNo(dispute *Dispute) int64 {
	var (
		winningValue int64
		weight       int64
		yesVotes     int64
		noVotes      int64
	)

	for _, vote := range dispute.Votes {
		if vote.Revealed {
			if vote.Value == 1 {
				yesVotes += vote.TokenAmount
			} else if vote.Value == 0 {
				noVotes += vote.TokenAmount
			}
		}
	}

	if yesVotes > noVotes {
		winningValue = 1
		weight = yesVotes
	} else {
		winningValue = 0
		weight = noVotes
	}

	rewardAndSlashVoters(dispute, winningValue, weight)
	return winningValue
}

// resolveNumeric determines the winning value for numeric disputes based on the highest total token weight.
// Not the best algorithm, but gas effective and fast.
func resolveNumeric(dispute *Dispute) int64 {
	// Find the value with the most token weight
	var (
		winningValue int64
		maxWeight    int64
	)

	// Collect unique values and aggregate weights
	valueWeights := make(map[int64]int64)
	for _, vote := range dispute.Votes {
		if vote.Revealed {
			valueWeights[vote.Value] += vote.TokenAmount
		}
	}

	for value, weight := range valueWeights {
		if weight > maxWeight {
			maxWeight = weight
			winningValue = value
		}
	}

	rewardAndSlashVoters(dispute, winningValue, maxWeight)
	return winningValue
}

func rewardAndSlashVoters(dispute *Dispute, winningValue, totalWeight int64) {
	for _, vote := range dispute.Votes {
		if !vote.Revealed {
			continue
		}

		if vote.Value == winningValue {
			// Reward winning voters
			VoteToken.mint(vote.Voter, 2)
			reward := bond * (vote.TokenAmount / totalWeight)

			if reward != 0 {
				bank.SendCoins(runtime.CurrentRealm().Address(), vote.Voter, chain.Coins{chain.Coin{Denom: "ugnot", Amount: reward}})
			}
			chain.Emit("VoterRewarded", "voter", vote.Voter.String())
		} else {
			// Slash losing voters
			slash := vote.TokenAmount / 4 // 25% slash
			VoteToken.burn(vote.Voter, slash)
			chain.Emit("VoterSlashed", "voter", vote.Voter.String())
		}
	}
}
