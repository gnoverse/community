package registrydao

import (
	"chain/runtime"

	"gno.land/p/nt/commondao"
	"gno.land/p/nt/ufmt"
)

// ProposeVerifyCollection - Create proposal to verify a collection and verify it upon approval
func ProposeVerifyCollection(_ realm, collectionAddr address, collectionName string, reason string) uint64 {
	caller := runtime.PreviousRealm().Address()

	if !IsRegistryDAOMember(caller) {
		panic("only Registry DAO members can create proposals")
	}

	info := GetCollection(collectionAddr)
	if info == nil {
		panic("collection not registered")
	}

	if info.Verified {
		panic("collection already verified")
	}

	propDef := NewVerifyCollectionProposal(collectionAddr, collectionName, reason)

	proposal, err := registryDAO.Propose(caller, propDef)
	if err != nil {
		panic("failed to create proposal: " + err.Error())
	}

	return proposal.ID()
}

// ProposeUnverifyCollection - Create proposal to unverify a collection
func ProposeUnverifyCollection(_ realm, collectionAddr address, collectionName string, reason string) uint64 {
	caller := runtime.PreviousRealm().Address()

	if !IsRegistryDAOMember(caller) {
		panic("only Registry DAO members can create proposals")
	}

	info := GetCollection(collectionAddr)
	if info == nil {
		panic("collection not registered")
	}

	if !info.Verified {
		panic("collection not verified")
	}

	propDef := NewUnverifyCollectionProposal(collectionAddr, collectionName, reason)

	proposal, err := registryDAO.Propose(caller, propDef)
	if err != nil {
		panic("failed to create proposal: " + err.Error())
	}

	return proposal.ID()
}

// VoteRegistry - Vote on a registry proposal yes/no
func VoteRegistry(_ realm, proposalID uint64, choice string) string {
	caller := runtime.PreviousRealm().Address()

	var voteChoice commondao.VoteChoice
	if choice == "yes" {
		voteChoice = commondao.ChoiceYes
	} else if choice == "no" {
		voteChoice = commondao.ChoiceNo
	} else {
		panic("choice must be 'yes' or 'no'")
	}

	// Use DAO's Vote method - handles all validations automatically
	err := registryDAO.Vote(caller, proposalID, voteChoice, "")
	if err != nil {
		panic("vote failed: " + err.Error())
	}

	return "Vote recorded: " + choice
}

// TallyRegistryProposal - Execute a registry proposal
func TallyRegistryProposal(_ realm, proposalID uint64) string {
	err := registryDAO.Execute(proposalID)
	if err != nil {
		panic("execution failed: " + err.Error())
	}

	return ufmt.Sprintf("Proposal %d executed successfully", proposalID)
}
