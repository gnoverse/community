package gnoplace

import (
	"chain/runtime"
	"net/url"
	"strconv"
	"time"

	"gno.land/p/moul/md"
	"gno.land/p/nt/avl"
	"gno.land/r/leon/hor"
)

// todo: versionning

var (
	users      = avl.NewTree()
	pixels     = [300]int{0}
	interval_s = 30 * time.Second
	colors     = []string{"⬜", "⬛", "🟦", "🟪", "🟧", "🟫", "🟥", "🟨", "🟩"}
)

func init() {
	hor.Register(cross, "GnoPlace", "a mini version of r/place  \n🟥🟩🟦🟨")
}

// Sets a pixel to a color
func SetPixel(_ realm, pixel int, color int) {
	// check for errors
	if pixel < 0 || pixel >= len(pixels) {
		panic("invalid pixel")
	}
	if color < 0 || color >= len(colors) {
		panic("invalid color")
	}

	// check if user allowed to set pixel
	lastEvent, ok := users.Get(runtime.PreviousRealm().Address().String())

	if ok && time.Since(lastEvent.(time.Time)) < interval_s {
		panic("you placed a pixel less than " + interval_s.String() + " ago")
	}

	pixels[pixel] = color

	// record the SetPixel event time for this user
	users.Set(runtime.PreviousRealm().Address().String(), time.Now())
}

// Render renders ui and pixel grid
func Render(path string) string {
	u, _ := url.Parse(path)
	query := u.Query()
	color := atoiDefault(query.Get("color"), -1)

	// show home
	out := md.H1("GnoPlace")
	out += md.HorizontalRule()
	out += md.H2("1 - Select your pixel color")

	for i, _ := range colors {
		out += md.Link(colors[i], "?color="+strconv.Itoa(i)) + " "
	}

	out += "  \n"

	out += "## 2 - Click a pixel to paint it"
	if color >= 0 {
		out += " with color " + colors[color]
	}
	out += "  \n"

	// render pixels
	for i, _ := range pixels {
		out += renderPixel(i, color)
		if (i+1)%20 == 0 {
			out += "  \n"
		}
	}

	out += md.H2("3 - Wait " + interval_s.String() + " before placing again :)")
	out += md.HorizontalRule()
	out += "If you enjoy gnoplace, please upvote in "
	out += md.Link("the Hall of Realms", "/r/leon/hor:hall?sort=creation") + "!\n"

	return out
}

// helper to render a pixel
func renderPixel(pixel int, color int) string {
	return md.Link(colors[pixels[pixel]], "gnoplace$help&func=SetPixel&.send=&pixel="+strconv.Itoa(pixel)+"&color="+strconv.Itoa(color))
}

// atoiDefault converts string to integer with a default fallback
func atoiDefault(s string, def int) int {
	if s == "" {
		return def
	}
	i, _ := strconv.Atoi(s)
	return i
}
