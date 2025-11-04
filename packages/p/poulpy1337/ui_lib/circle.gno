package svg

import (
	"strconv"
)

type SvgCircle struct {
	SvgElement
	radius int
}

func NewSvgCircle(x, y, radius int, color string, class string, children ...SvgElementer) *SvgCircle {
	return &SvgCircle{
		SvgElement: SvgElement{
			color:    color,
			class:    class,
			x:        x,
			y:        y,
			children: children,
		},
		radius: radius,
	}
}

func (c *SvgCircle) render() string {
	children := c.renderChildren()
	if children == "" {
		return `<circle cx="` + strconv.Itoa(c.x) +
			`" cy="` + strconv.Itoa(c.y) +
			`" r="` + strconv.Itoa(c.radius) +
			`" class="` + c.class +
			`" fill="` + c.color + `"/>`
	}
	return `<g>
  <circle cx="` + strconv.Itoa(c.x) +
		`" cy="` + strconv.Itoa(c.y) +
		`" r="` + strconv.Itoa(c.radius) +
		`" class="` + c.class +
		`" fill="` + c.color + `"/>` + children + `
</g>`
}
