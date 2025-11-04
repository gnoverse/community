package svg

import (
	"strconv"
)

type SvgText struct {
	SvgElement
	text string
}

func NewSvgText(x, y int, text string, color string, class string, children ...SvgElementer) *SvgText {
	return &SvgText{
		SvgElement: SvgElement{
			color:    color,
			class:    class,
			x:        x,
			y:        y,
			width:    0,
			height:   0,
			children: children,
		},
		text: text,
	}
}

func (r *SvgText) render() string {
	children := r.renderChildren()
	if children == "" {
		return `<text x="` + strconv.Itoa(r.x) +
			`" y="` + strconv.Itoa(r.y) +
			`" class="` + r.class +
			`" fill="` + r.color + `">` + r.text + "</text>"
	}
	return `<g>
  <text x="` + strconv.Itoa(r.x) +
		`" y="` + strconv.Itoa(r.y) +
		`" class="` + r.class +
		`" fill="` + r.color + `">` + r.text + "</text>" + children + `
</g>`
}
