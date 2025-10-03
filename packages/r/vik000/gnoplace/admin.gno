package gnoplace

import (
	"chain/runtime"
	"time"

	"gno.land/p/nt/avl"
	"gno.land/p/nt/ownable"
)

var (
	OwnableMain   = ownable.NewWithAddress("g13kytw9mpyutwmyg5eq7arqxqcszfl6uq4p89zg")
	OwnableBackup = ownable.NewWithAddress("g1f699cfulem8jvq69pxlm5eq945dzusptzkdrgz")
)

// Resets gnoplace
func Reset(_ realm) {
	CheckPermission()

	users = avl.NewTree()
	pixels = [300]int{}
}

func SetInterval(_ realm, interval int) {
	CheckPermission()

	interval_s = time.Duration(interval) * time.Second
}

func CheckPermission() {
	addr := runtime.PreviousRealm().Address()
	if addr == OwnableMain.Owner() || addr == OwnableBackup.Owner() {
		return
	} else {
		panic("access restricted")
	}
}
