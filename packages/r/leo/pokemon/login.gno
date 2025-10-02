package pokemon

import (
	"chain/runtime"

	"gno.land/p/moul/md"
	"gno.land/p/moul/txlink"
	"gno.land/p/nt/avl"
	"gno.land/p/nt/mux"
	"gno.land/r/sys/users"
)

type UserData struct {
	team       [teamSize]Pokemon
	inventory  []ItemType
	pokedollar uint
}

var (
	pokemonDAO = avl.NewTree()
)

// defaultUserData creates a new user with an empty team and 500 Pokedollars
func defaultUserData() *UserData {
	return &UserData{team: [teamSize]Pokemon{}, inventory: []ItemType{}, pokedollar: 500}
}

// Login registers a new user in the Pokémon game
func Login(_ realm) {
	usr := string(runtime.PreviousRealm().Address())
	if pokemonDAO.Has(usr) {
		panic("user already a member")
	}
	pokemonDAO.Set(usr, defaultUserData())
}

// DeleteMyAccount removes the user's account and data
func DeleteMyAccount(_ realm) {
	usr := string(runtime.PreviousRealm().Address())
	if !pokemonDAO.Has(usr) {
		panic("user is not a member")
	}
	pokemonDAO.Remove(usr)
}

// renderPokemonLogin renders the login page with options to create or delete an account
func renderPokemonLogin(rend *mux.ResponseWriter, _ *mux.Request) {
	rend.Write(md.H2("Are you a already Pokémon Trainer ?"))
	rend.Write(md.Link("Get me a brand new Pokémon Licence !", txlink.Call("Login")) + nl)
	rend.Write(md.Link("Delete my existing Pokémon Licence", txlink.Call("DeleteMyAccount")) + nl)
	rend.Write(md.H2("Select your account"))
	pokemonDAO.Iterate("", "", func(addr string, user any) bool {
		name := addr
		data := users.ResolveAddress(address(addr))
		if data != nil {
			name = data.Name()
		}
		link := atmPath + ":" + string(pokemonLobby) + "?user=" + addr
		rend.Write(" - " + md.Link(name, link))
		rend.Write(" : " + renderPokedollar(int(user.(*UserData).pokedollar)) + nl)
		return false
	})
	return
}
