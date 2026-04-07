package goo

import (
	"gno.land/p/demo/tokens/grc20"
)

func newOOToken(name, symbol string, decimals int) *OOT {
	token := &OOT{}
	t, adm := grc20.NewToken(name, symbol, decimals)
	token.Token = t
	token.PrivateLedger = adm
	return token
}

// Mint create new tokens to an address.
func (t *OOT) mint(to address, amount int64) {
	t.PrivateLedger.Mint(to, amount)
}

// Burn destroy tokens from an address.
func (t *OOT) burn(from address, amount int64) {
	t.PrivateLedger.Burn(from, amount)
}

func (t *OOT) BalanceOf(addr address) int64 {
	return t.Token.BalanceOf(addr)
}
