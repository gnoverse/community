package gnov

import (
	"strings"
	"testing"
)

// Test for basic scatter plot rendering
func TestScatterPlot(t *testing.T) {
	sp := ScatterPlot{
		Points: []Point{
			{X: 0, Y: 0, Label: "A", Color: "red"},
			{X: 1, Y: 2, Label: "B", Color: "blue"},
		},
		Title: "Test Scatter",
		XAxis: "X Axis",
		YAxis: "Y Axis",
	}

	got := sp.String()

	if got == "" {
		t.Fatal("Render output is empty")
	}
	if !strings.Contains(got, "Test Scatter") {
		t.Error("title not found in render output")
	}
	if !strings.Contains(got, "X Axis") {
		t.Error("X axis label not found")
	}
	if !strings.Contains(got, "Y Axis") {
		t.Error("Y axis label not found")
	}
	if !strings.Contains(got, "<circle") {
		t.Error("expected at least one circle (point) in render output")
	}
}

// Test for scatter plot rendering with regression flag
func TestScatterPlotReFlag(t *testing.T) {
	sp := ScatterPlot{
		Points: []Point{
			{X: 0, Y: 0},
			{X: 1, Y: 2},
			{X: 2, Y: 4},
		},
		Title: "With Regression",
		XAxis: "X",
		YAxis: "Y",
		Flag:  "re",
	}

	got := sp.String()

	if !strings.Contains(got, "Equation") {
		t.Error("regression equation not found in render output")
	}
	if !strings.Contains(got, "<rect") {
		t.Error("expected regression line rectangle in render output")
	}
}
