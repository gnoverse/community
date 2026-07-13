package goo

import (
	"chain/runtime"
	"strconv"
	"time"

	"gno.land/p/moul/md"
	"gno.land/p/moul/realmpath"
	"gno.land/p/moul/txlink"
	"gno.land/p/nt/ufmt"
)

const DateFormat = "January 2 2006, 03:04:04 PM"

func Render(path string) string {
	req := realmpath.Parse(path)
	if req.Path == "" {
		return renderHome()
	}
	return renderRequestPage(req.Path)
}

func renderHome() string {
	msg := md.H1("GOO Home")
	msg += md.Paragraph("Welcome to the first Optimistic Oracle on GnoLand! This project is developed by " + md.Link("@intermarch3", "/r/intermarch3/home"))
	msg += md.Paragraph("For more information, visit the " + md.Link("Readme", runtime.CurrentRealm().PkgPath()[8:]+"$source") + ".")
	msg += md.Link("Request Data", ufmt.Sprintf("%s", txlink.NewLink("RequestData").AddArgs("ancillaryData", "YOUR_QUESTION", "yesNoQuestion", "true or false", "deadline", "DEADLINE_TIMESTAMP").SetSend(strconv.Itoa(int(requesterReward))+"ugnot").URL())) + "\n\n(Note: Requesting data need to pay a reward of " + strconv.Itoa(int(requesterReward/1_000_000)) + " GNOT to the proposer).\n\n"
	msg += md.H2("Current requests :")

	// List current requests and build table
	var table []string
	table = append(table, md.Bold("Question"), md.Bold("Proposed Value"), md.Bold("State"), md.Bold("See more"))

	requests.Iterate("", "", func(key string, value any) bool {
		if value.(*DataRequest).State == "Resolved" {
			return false
		}
		table = append(table, renderRequest(value.(*DataRequest))...)
		return false
	})
	msg += md.ColumnsN(table, 4, false)

	// If no current requests, show a message
	if len(table) == 4 {
		msg += md.Paragraph("No current requests.")
	}

	msg += md.HorizontalRule()

	// List last 5 resolved requests and build table
	msg += md.H2("Last 5 Resolved requests:")
	var resolved []string
	resolved = append(resolved, md.Bold("Question"), md.Bold("Winning Value"), md.Bold("Proposer"), md.Bold("See more"))

	requests.Iterate("", "", func(key string, value any) bool {
		if value.(*DataRequest).State != "Resolved" {
			return false
		}
		resolved = append(resolved, md.Paragraph(value.(*DataRequest).AncillaryData))
		resolved = append(resolved, md.Paragraph(rendervalue(value.(*DataRequest), value.(*DataRequest).WinningValue)))
		resolved = append(resolved, md.Paragraph(value.(*DataRequest).Proposer.String()))
		resolved = append(resolved, md.Link("Click here", runtime.CurrentRealm().PkgPath()[8:]+":"+value.(*DataRequest).Id))
		return false
	})
	msg += md.ColumnsN(resolved, 4, false)

	// If no resolved requests, show a message
	if len(resolved) == 4 {
		msg += md.Paragraph("No resolved requests yet.")
	}
	return msg
}

// renderRequestPage renders the page for a specific request
func renderRequestPage(id string) string {
	req := getRequest(id)

	msg := md.H1("Question: " + req.AncillaryData)
	msg += md.H2("Details:\n\n")
	msg += md.H3("Request ID: "+req.Id) + "\n\n"

	// check if the request is past the deadline
	msg += md.H3("Requested at: "+req.Timestamp.Format(DateFormat)) + "\n\n"
	if req.State == "Requested" && req.Deadline.Unix() < time.Now().Unix() {
		msg += md.H3("Deadline Missed: requests not fulfilled") + "\n\n"
		return msg
	}

	// show the state of the request
	msg += md.H3("State: "+req.State) + "\n\n"
	if req.State == "Requested" {
		msg += md.Paragraph("This request has not been proposed yet.") + "\n\n"
		msg += md.H3("The reward for the proposer is "+strconv.Itoa(int(requesterReward/1_000_000))+" GNOT.") + "\n\n"
		msg += renderAction(req)
		return msg
	}

	// if the request is resolved, show the winning value and the number of votes
	if req.State == "Resolved" {
		msg += md.H3("Winning Value: "+rendervalue(req, req.WinningValue)) + "\n\n"
		res, exists := disputes.Get(req.Id)
		if !exists {
			msg += md.Paragraph("Value Proposed by: "+req.Proposer.String()) + "\n\n"
			return msg
		}

		dispute := res.(*Dispute)
		msg += md.Paragraph("Number of Votes: " + strconv.Itoa(len(dispute.Votes)) + "\n\n")
		msg += md.Paragraph("Reveal Votes: \n\n")
		if dispute.NbResolvedVotes > 0 {
			msg += renderRevealedVotes(*dispute) + "\n\n"
		} else {
			msg += md.Paragraph("No votes revealed. Proposed value win by default\n\n")
		}
		return msg
	}

	// if the request is proposed, show the proposed value and the end resolution time
	if req.State == "Proposed" {
		msg += md.Paragraph("Proposed by: "+req.Proposer.String()) + "\n\n"
		msg += md.H3("Proposed Value: "+rendervalue(req, req.ProposedValue)) + "\n\n"
		msg += md.H3("End Resolution Time: "+req.ResolutionTime.Format(DateFormat)) + "\n\n"
	}

	// if the request is disputed, show the dispute details
	if req.State == "Disputed" {
		res, exist := disputes.Get(req.Id)
		if exist {
			dispute := res.(*Dispute)
			msg += md.H2("Dispute Details:\n\n")
			msg += md.Paragraph("End of Voting Time: " + dispute.EndTime.Format(DateFormat) + "\n\n")
			msg += md.Paragraph("End of Reveal Time: " + dispute.EndRevealTime.Format(DateFormat))
			msg += md.Paragraph("Number of Votes: " + strconv.Itoa(len(dispute.Votes)) + "\n\n")
			msg += md.Paragraph("Revealed Votes: \n\n")

			if dispute.NbResolvedVotes > 0 {
				msg += renderRevealedVotes(*dispute) + "\n\n"
			} else {
				msg += md.Paragraph("No votes revealed yet.\n\n")
			}
		} else {
			msg += md.Paragraph("No dispute details available.\n\n")
		}
	}

	msg += renderAction(req)
	return msg
}

// create table of the votes that have been revealed
func renderRevealedVotes(dispute Dispute) string {
	var table []string

	table = append(table, md.Bold("Voter"), md.Bold("Vote"), md.Bold("Token Amount"))
	request := getRequest(dispute.RequestId)

	for _, vote := range dispute.Votes {
		if vote.Revealed {
			table = append(table, md.Paragraph(vote.Voter.String()), md.Paragraph(rendervalue(request, vote.Value)), md.Paragraph(strconv.Itoa(int(vote.TokenAmount))))
		}
	}
	return md.ColumnsN(table, 3, false)
}

func rendervalue(req *DataRequest, val int64) string {
	if req.YesNoQuestion {
		if val == 1 {
			return "Yes"
		} else if val == 0 {
			return "No"
		} else {
			return "Invalid value for Yes/No question"
		}
	} else {
		return strconv.Itoa(int(val))
	}
}

func renderRequest(req *DataRequest) []string {
	var table []string

	table = append(table, md.Paragraph(req.AncillaryData))
	if req.State == "Requested" {
		table = append(table, md.Paragraph("N/A"))
	} else {
		table = append(table, md.Paragraph(rendervalue(req, req.ProposedValue)))
	}
	table = append(table, md.Paragraph(req.State))
	table = append(table, md.Link("Click here", runtime.CurrentRealm().PkgPath()[8:]+":"+req.Id))
	return table
}

// return appropriate action link based on the state of the request
func renderAction(req *DataRequest) string {
	action := md.H2("Actions:\n\n")
	dispute, _ := disputes.Get(req.Id)

	if req.State == "Requested" {
		// tx to propose a value
		action += md.Link("Propose a value", ufmt.Sprintf("%s", txlink.NewLink("ProposeValue").AddArgs("id", req.Id, "proposedValue", "YOUR_VALUE_HERE").SetSend(strconv.Itoa(int(bond))+"ugnot").URL())) + "\n\n(Note: Proposing need to bond " + strconv.Itoa(int(bond/1_000_000)) + " GNOT)"
	} else if req.State == "Proposed" {
		// tx to dispute a value
		action += md.Link("Dispute value", ufmt.Sprintf("%s", txlink.NewLink("DisputeData").AddArgs("id", req.Id).SetSend(strconv.Itoa(int(bond))+"ugnot").URL())) + "\n\n(Note: Disputing need to bond " + strconv.Itoa(int(bond/1_000_000)) + " GNOT)"
	} else if req.State == "Disputed" {
		if req.ResolutionTime.Before(time.Now()) {
			// tx to reveal a vote
			action += md.Link("Reveal vote", ufmt.Sprintf("%s", txlink.NewLink("RevealVote").AddArgs("id", req.Id, "value", "YOUR_VALUE_HERE", "salt", "YOUR_SALT_HERE").URL())) + "\n\n(Note: You must reveal your vote before the reveal period ends at " + dispute.(*Dispute).EndRevealTime.UTC().Format(time.UnixDate) + ")"
		} else {
			// tx to vote on a dispute
			action += md.Link("Vote", ufmt.Sprintf("%s", txlink.NewLink("VoteOnDispute").AddArgs("id", req.Id, "hash", "YOUR_HASH_HERE").URL())) + "\n\n(Note: Voting need to hold a Vote Token and requires you to hash your vote with a salt. Use a tool to generate the sha256 hash and keep your salt safe to reveal your vote)"
		}
	} else if req.State == "Disputed" && dispute.(*Dispute).EndTime.Before(time.Now()) {
		// tx to resolve a dispute
		action += md.Link("Resolve dispute", ufmt.Sprintf("%s", txlink.NewLink("ResolveDispute").AddArgs("id", req.Id).URL())) + "\n\n"
	} else if req.State == "Proposed" && req.ResolutionTime.Before(time.Now()) {
		// tx to resolve a request
		action += md.Link("Resolve request", ufmt.Sprintf("%s", txlink.NewLink("ResolveRequest").AddArgs("id", req.Id).URL())) + "\n\n"
	}
	return action
}
