package svg

type SvgGroup struct {
	SvgElement
	id string
}

func NewSvgGroup(id string, children ...SvgElementer) *SvgGroup {
	return &SvgGroup{
		SvgElement: SvgElement{
			children: children,
		},
		id: id,
	}
}

func (g *SvgGroup) render() string {
	children := g.renderChildren()
	if g.id != "" {
		return `<g id="` + g.id + `">` + children + `
</g>`
	}
	return `<g>` + children + `
</g>`
}
