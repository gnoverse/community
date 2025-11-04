package svg

import (
	"strconv"
)

type SvgRect struct {
	SvgElement
	roundness int
}

func NewSvgRect(x, y, width, height int, roundness int, color string, class string, children ...SvgElementer) *SvgRect {
	return &SvgRect{
		SvgElement: SvgElement{
			color:    color,
			class:    class,
			x:        x,
			y:        y,
			width:    width,
			height:   height,
			children: children,
		},
		roundness: roundness,
	}
}

func (r *SvgRect) render() string {
	children := r.renderChildren()
	if children == "" {
		return `<rect x="` + strconv.Itoa(r.x) +
			`" y="` + strconv.Itoa(r.y) +
			`" width="` + strconv.Itoa(r.width) +
			`" height="` + strconv.Itoa(r.height) +
			`" rx="` + strconv.Itoa(r.roundness) +
			`" class="` + r.class +
			`" fill="` + r.color + `"/>`
	}
	return `<g>
  <rect x="` + strconv.Itoa(r.x) +
		`" y="` + strconv.Itoa(r.y) +
		`" width="` + strconv.Itoa(r.width) +
		`" height="` + strconv.Itoa(r.height) +
		`" rx="` + strconv.Itoa(r.roundness) +
		`" class="` + r.class +
		`" fill="` + r.color + `"/>` + children + `
</g>`
}
