package home

import (
	"strings"
	"std"
	"gno.land/p/nt/ownable"
)

var OwnableAddress = ownable.NewWithAddress("g13szarf3rw3jf7m6v43yzwfz5jx0njkezq6hjx3")
var pp = "![test](https://i2.seadn.io/ethereum/0x368ad4a7a7f49b8fa8f34476be0fc4d04ce622f5/22e9f239c16892e578adeea381a4dc6a.png?w=350)"
var projects = []string{
	"[Gnovisu](/r/pierre115/gnovisu) - Lib Svg for Data Visualisation.",
}
var links = []string{
	"[Github](https://github.com/gnolang/hackerspace/issues?q=sort:updated-desc+author:divisio74) - As part of the Epitech student program, I’ll be sharing my progress and insights over the next four months.",
}
var introText = `# Pierre115's Home
##
## About Me
`
var espace = `
##
`

var modtext = `

I'm Pierre Baud, a second-year student at Epitech Lyon. Before diving into tech, I spent five years in business school, specializing in AI management and Finance where I developed a strong foundation in strategy and innovation.

Today, I’m passionate about software development and eager to bridge the gap between business and technology. I enjoy working with languages like Go, C/C++, and Python, and I’m currently exploring the blockchain ecosystem through hands-on projects.

I'm also very interested in dynamic NFTs and their potential to help artists through new forms of creative expression and ownership !

`

func IsAuthorized(addr std.Address) bool {
	return addr == OwnableAddress.Owner()
}

func Render(_ string) string {
	content := introText + modtext + espace + RenderPp() + RenderProjects() + RenderLinks()
	return strings.ReplaceAll(content, "^", "`")
}

func RenderProjects() string {
	var content string
	content += "\n\n## Projects\n\n"
	for _, p := range projects {
		content += "- " + p + "\n"
	}
	return content
}

func RenderPp() string {
	return pp
}

func RenderLinks() string {
	var content string
	content += "\n\n## Links\n\n"
	for _, p := range links {
		content += "- " + p + "\n"
	}
	return content
}

func UpdateProjects(_ realm, name, url, desc string) {
	if !IsAuthorized(std.PreviousRealm().Address()) {
		panic("unauthorized")
	}
	entry := "[" + name + "](" + url + ") - " + desc
	projects = append(projects, entry)
}

func UpdateLinks(_ realm, name, url, desc string) {
	if !IsAuthorized(std.PreviousRealm().Address()) {
		panic("unauthorized")
	}

	entry := "[" + name + "](" + url + ") - " + desc
	links = append(links, entry)
}

func UpdatePp(_ realm, name, url string) {
	if !IsAuthorized(std.PreviousRealm().Address()) {
		panic("unauthorized")
	}

	entry := "![" + name + "](" + url + ")"
	pp = entry
}

func UpdateIntro(_ realm, newText string) {
	if !IsAuthorized(std.PreviousRealm().Address()) {
		panic("unauthorized")
	}
	modtext = newText
}
