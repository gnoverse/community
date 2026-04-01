package gnobounty

import (
	"chain"
	"testing"

	"gno.land/p/nt/testutils"
)

func TestCreateBounty(t *testing.T) {
	// Setup test environment
	testing.SetOriginCaller(testutils.TestAddress("alice"))
	testing.SetOriginSend(chain.Coins{chain.Coin{Denom: "ugnot", Amount: 5000000}})

	// Create a bounty
	bountyID := CreateBounty(
		cross,
		"Fix Rendering Bug",
		"https://github.com/gnolang/gno/issues/1234",
		"Fix the rendering issue in the GRC20 token display",
	)

	if bountyID != 1 {
		t.Errorf("Expected bounty ID 1, got %d", bountyID)
	}

	// Check bounty was created
	bounty := GetBounty(bountyID)
	if bounty == nil {
		t.Fatal("Bounty not found")
	}

	if bounty.Amount != 5000000 {
		t.Errorf("Expected amount 5000000, got %d", bounty.Amount)
	}

	if bounty.IsClaimed {
		t.Error("Bounty should not be claimed yet")
	}

	if bounty.Title != "Fix Rendering Bug" {
		t.Errorf("Expected title 'Fix Rendering Bug', got %s", bounty.Title)
	}
}

func TestGetBountyCount(t *testing.T) {
	count := GetBountyCount()
	if count < 1 {
		t.Error("Expected at least 1 bounty from previous test")
	}
}

func TestListBounties(t *testing.T) {
	list := ListBounties()
	if list == "" {
		t.Error("Expected non-empty bounties list")
	}
	if list == "No bounties available" {
		t.Error("Expected bounties to be listed")
	}
}

func TestGetBountyDetails(t *testing.T) {
	// Test getting details for existing bounty
	details := GetBountyDetails(1)
	if details == "" {
		t.Error("Expected non-empty bounty details")
	}
	if details == "Bounty not found" {
		t.Error("Bounty #1 should exist")
	}
}

func TestGetBountyDetailsNotFound(t *testing.T) {
	// Test getting details for non-existent bounty
	details := GetBountyDetails(99999)
	if details != "Bounty not found" {
		t.Error("Expected 'Bounty not found' for non-existent bounty")
	}
}
