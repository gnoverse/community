package utils

import (
	"fmt"
	"strings"
)

// ContractError represents a user-friendly error message
type ContractError struct {
	Original string
	Friendly string
}

// ParseContractError converts contract error messages to user-friendly messages
func ParseContractError(err error) error {
	if err == nil {
		return nil
	}

	errMsg := err.Error()

	// Common contract error patterns with user-friendly messages
	errorMappings := map[string]string{
		// Request errors
		"Ancillary data cannot be empty":                         "❌ Question/ancillary data is required",
		"Deadline must be at least 24 hours in the future":      "❌ Deadline must be at least 24 hours from now",
		"Incorrect reward amount sent":                          "❌ Incorrect reward amount (check with 'goo query params')",
		"Request with this ID does not exist":                   "❌ Request not found - invalid request ID",
		"Request is not in 'Requested' state":                   "❌ Request is not available for proposals (may be already proposed, disputed, or resolved)",
		"Deadline for proposal has passed":                      "❌ Proposal deadline has passed",
		"Request has not been proposed yet":                     "❌ No proposal submitted for this request yet",
		"Request is already resolved":                           "❌ Request is already resolved",
		"cannot retreive fund as requests fulfilled":            "❌ Cannot retrieve funds - request has been fulfilled",
		"Only the creator of the request can retrieve the fund": "❌ Only the request creator can retrieve the fund",
		"Cannot retrieve fund before the deadline":              "❌ Cannot retrieve fund - deadline not reached yet",

		// Proposal errors
		"Proposed value must be 0 or 1 for yes/no questions":  "❌ For yes/no questions, value must be 0 (no) or 1 (yes)",
		"Incorrect bond amount sent":                          "❌ Incorrect bond amount (check with 'goo query params')",
		"Resolution period has not ended yet":                 "❌ Cannot resolve yet - resolution period still active",
		"Request is in 'Disputed' state":                      "❌ Cannot resolve - request is disputed",
		"Proposer cannot dispute their own proposal":          "❌ You cannot dispute your own proposal",
		"Request is not in 'Proposed' state":                  "❌ Request is not in proposed state (may be already disputed or resolved)",
		"Dispute period has ended":                            "❌ Dispute period has ended",
		"Dispute for this request already exists":             "❌ This request is already disputed",
		"Dispute is already resolved":                         "❌ Dispute is already resolved",
		"Dispute period has not ended yet":                    "❌ Dispute period has not ended yet",
		"Request is not resolved":                             "❌ Request is not resolved yet - cannot get result",

		// Vote errors
		"You already have a vote token":                            "❌ You already own a vote token",
		"Must send exactly":                                        "❌ Incorrect vote token price (check with 'goo query params')",
		"Proposer and Disputer cannot vote in this dispute":       "❌ Proposers and disputers cannot vote on their own disputes",
		"Voter has already voted in this dispute":                 "❌ You have already voted in this dispute",
		"You need at least 1 vote token to vote":                  "❌ You need to buy a vote token first ('goo vote buy-token')",
		"Vote period has ended":                                   "❌ Voting period has ended",
		"Vote period has not ended yet":                           "❌ Cannot reveal yet - voting period still active",
		"Reveal period has ended":                                 "❌ Reveal period has ended",
		"Voter did not participate in this dispute":               "❌ You did not vote in this dispute",
		"Vote already revealed":                                   "❌ Vote already revealed",
		"Hash does not match the revealed value and salt":         "❌ Hash mismatch - value or salt incorrect (check ~/.goo/votes/)",
		"Dispute with this ID does not exist":                     "❌ Dispute not found - invalid dispute ID",
		"Dispute is resolved":                                     "❌ Dispute is already resolved",

		// Admin errors
		"Only the admin can": "❌ Admin privileges required",
		"Only admin can":     "❌ Admin privileges required",

		// General errors
		"missing realm argument": "❌ Internal error - realm context required",
		"query failed":           "❌ Query failed",
		"failed to query":        "❌ Failed to query contract",
	}

	// Check for each error pattern
	for pattern, friendlyMsg := range errorMappings {
		if strings.Contains(errMsg, pattern) {
			return fmt.Errorf("%s", friendlyMsg)
		}
	}

	// If no pattern matches, check if it's a contract error and clean it up
	if strings.Contains(errMsg, "Error =--") {
		// Extract the actual error message from contract output
		if idx := strings.Index(errMsg, "error:"); idx != -1 {
			// Find the end of the error message
			rest := errMsg[idx+7:] // Skip "error: "
			if endIdx := strings.Index(rest, "\n"); endIdx != -1 {
				cleanMsg := strings.TrimSpace(rest[:endIdx])
				return fmt.Errorf("❌ Contract error: %s", cleanMsg)
			}
		}
		if idx := strings.Index(errMsg, "Data:"); idx != -1 {
			rest := errMsg[idx+5:]
			if endIdx := strings.Index(rest, "\n"); endIdx != -1 {
				cleanMsg := strings.TrimSpace(rest[:endIdx])
				return fmt.Errorf("❌ %s", cleanMsg)
			}
		}
	}

	// Return original error if no pattern matches
	return err
}

// HandleError prints a user-friendly error message
func HandleError(err error) {
	if err == nil {
		return
	}

	friendlyErr := ParseContractError(err)
	PrintError(friendlyErr.Error())
}
