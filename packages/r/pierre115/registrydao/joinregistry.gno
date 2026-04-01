package registrydao

import (
	//"chain/banker"
	"chain/runtime"

	"gno.land/p/nt/commondao"
)

var (
	registryDAO *commondao.CommonDAO
)

const (
	MIN_STAKE_UGNOT = 0 // 0 GNOT minimum to join registry DAO
)

func initRegistryDAO() {
	storage := commondao.NewMemberStorage()

	registryDAO = commondao.New(
		commondao.WithID(2), // Different ID from marketplace DAO
		commondao.WithName("NFT Registry DAO"),
		commondao.WithDescription("Decentralized governance for NFT Registry"),
		commondao.WithMemberStorage(storage),
	)
}

// JoinRegistryDAO - Join the NFT Registry DAO by staking GNOT
func JoinRegistryDAO(_ realm) string {
	caller := runtime.PreviousRealm().Address()
	//sent := banker.OriginSend()

	//amount := sent.AmountOf("ugnot")
	//if amount < MIN_STAKE_UGNOT {
	//	panic("minimum 10 GNOT required to join Registry DAO")
	//}

	if registryDAO.Members().Has(caller) {
		panic("already a DAO member")
	}

	registryDAO.Members().Add(caller)

	return "Successfully joined NFT Registry DAO"
}

// IsRegistryDAOMember - Check if an address is a registry DAO member
func IsRegistryDAOMember(addr address) bool {
	return registryDAO.Members().Has(addr)
}

// GetTotalRegistryMembers - Returns total number of registry DAO members
func GetTotalRegistryMembers() int {
	return registryDAO.Members().Size()
}
