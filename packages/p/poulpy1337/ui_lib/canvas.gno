package svg

import (
	"strconv"
)

type SvgCanvas struct {
	SvgElement
	viewBox string
	style   string
}

func NewSvgCanvas(width, height int, viewBox string, style string, children ...SvgElementer) *SvgCanvas {
	return &SvgCanvas{
		SvgElement: SvgElement{
			width:    width,
			height:   height,
			children: children,
			class:    "",
		},
		viewBox: viewBox,
		style:   style,
	}
}

func (s *SvgCanvas) Render() string {
	children := s.renderChildren()
	return `<svg width="` + strconv.Itoa(s.width) +
		`" height="` + strconv.Itoa(s.height) +
		`" viewBox="` + s.viewBox +
		`" class="` + s.class +
		`" xmlns="http://www.w3.org/2000/svg"> ` + `<style>` + s.style + "</style>" + children + `</svg>`
}
