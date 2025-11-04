package svg

import (
	"strings"
)

type SvgElementer interface {
	render() string
}

type SvgElement struct {
	color    string
	class    string
	x        int
	y        int
	width    int
	height   int
	children []SvgElementer
}

func (e *SvgElement) renderChildren() string {
	var childrenStr strings.Builder
	for _, child := range e.children {
		childrenStr.WriteString("\n  ")
		childrenStr.WriteString(child.render())
	}
	return childrenStr.String()
}
