package gnopensea

import (
	"chain/banker"
	"chain/runtime"
)

// ============= ADMIN =============

func SetMarketplaceFee(newFee int64) {
	caller := runtime.PreviousRealm().Address()
	if caller != owner {
		panic("Only owner can modify fees")
	}

	if newFee < 0 || newFee > 1000 { // Max 10%
		panic("Fees must be between 0% and 10%")
	}

	marketplaceFee = newFee
}

func WithdrawFees() {
	caller := runtime.PreviousRealm().Address()
	if caller != owner {
		panic("Only owner can withdraw fees")
	}

	// Use NewBanker instead of GetBanker
	bnkr := banker.NewBanker(banker.BankerTypeRealmSend)
	realmAddr := runtime.CurrentRealm().Address()

	// Get balance of the realm
	balance := bnkr.GetCoins(realmAddr)

	if balance.AmountOf("ugnot") > 0 {
		bnkr.SendCoins(realmAddr, owner, balance)
	}
}

// AddAdmin - Add a new admin address
func AddAdmin(newAdmin address) {
	caller := runtime.PreviousRealm().Address()
	if caller != owner {
		panic("Only owner can add admins")
	}
	admins.Set(newAdmin.String(), true)
}

// RemoveAdmin - Remove an admin address
func RemoveAdmin(admin address) {
	caller := runtime.PreviousRealm().Address()
	if caller != owner {
		panic("Only owner can remove admins")
	}
	if admin == owner {
		panic("Cannot remove owner as admin")
	}
	admins.Remove(admin.String())
}
