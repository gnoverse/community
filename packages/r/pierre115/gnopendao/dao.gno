package gnopendao

import (
	//"chain/banker"
	"chain/runtime"

	"gno.land/p/nt/commondao"
)

var (
	marketplaceDAO *commondao.CommonDAO
)

const (
	MIN_STAKE_UGNOT = 0 // 0 GNOT minimum to join DAO
)

func initDAO() {
	storage := commondao.NewMemberStorage()

	marketplaceDAO = commondao.New(
		commondao.WithID(1),
		commondao.WithName("GnopenSea DAO"),
		commondao.WithDescription("Decentralized governance for GnopenSea marketplace"),
		commondao.WithMemberStorage(storage),
	)
}

// JoinDAO - Join the marketplace DAO by staking GNOT
func JoinDAO(_ realm) string {
	caller := runtime.PreviousRealm().Address()
	//sent := banker.OriginSend()

	//amount := sent.AmountOf("ugnot")
	//if amount < MIN_STAKE_UGNOT {
	//	panic("minimum 1 GNOT required to join DAO")
	//}

	if marketplaceDAO.Members().Has(caller) {
		panic("already a DAO member")
	}

	marketplaceDAO.Members().Add(caller)

	return "Successfully joined GnopenSea DAO"
}

// IsDAOMember - Check if an address is a DAO member
func IsDAOMember(addr address) bool {
	return marketplaceDAO.Members().Has(addr)
}

// GetTotalMembers - Returns total number of DAO members
func GetTotalMembers() int {
	return marketplaceDAO.Members().Size()
}
