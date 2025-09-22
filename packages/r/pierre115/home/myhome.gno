package home2

import (
	"strings"
	"std"

	"gno.land/p/nt/ownable"
	"gno.land/p/moul/md"
)

var (
	OwnableAddress = ownable.NewWithAddress("g1e7r5eglptfejknps3xv2kxv6pc8wvd3wwtw6tg")
	pp = "![png](https://i.imgflip.com/a6o5jb.jpg)"
	projects = []string{
		"[Gnovisu](/r/pierre115/gnovisu) - Lib Svg for Data Visualisation.",
	}
	links = []string{
		"[Github](https://github.com/gnolang/hackerspace/issues?q=sort:updated-desc+author:divisio74) - As part of the Epitech student program, I’ll be sharing my progress and insights over the next four months.",
		"[Linkedin](https://www.linkedin.com/in/pierre-baud-/)  - Feel free to connect with me on LinkedIn!",
	}
	HomeTitle = md.H1("Pierre115's Home")
	ScndTitle = md.H2("About Me")
)


func IsAuthorized(addr std.Address) bool {
	return addr == OwnableAddress.Owner()
}

func Render(_ string) string {
	content := HomeTitle + ScndTitle + modtext + RenderPp() + RenderProjects() + RenderLinks()
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

func AddProjects(_ realm, name, url, desc string) {
	if !IsAuthorized(std.PreviousRealm().Address()) {
		panic("unauthorized")
	}
	entry := "[" + name + "](" + url + ") - " + desc
	projects = append(projects, entry)
}

func AddLinks(_ realm, name, url, desc string) {
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

var modtext = md.H3(`

I'm Pierre Baud, a second-year student at Epitech Lyon. Before diving into tech, I spent five years in business school, specializing in AI management and Finance where I developed a strong foundation in strategy and innovation.

Today, I’m passionate about software development and eager to bridge the gap between business and technology. I enjoy working with languages like Go, C/C++, and Python, and I’m currently exploring the blockchain ecosystem through hands-on projects.

I'm also very interested in dynamic NFTs and their potential to help artists through new forms of creative expression and ownership !

`)
