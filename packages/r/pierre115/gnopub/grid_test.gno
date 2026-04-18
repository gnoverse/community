package gnopub

import (
	"strings"
	"testing"
)

// Test for basic grid rendering
func TestRenderGrid(t *testing.T) {
	got := renderGrid()

	if got == "" {
		t.Fatal("RenderGrid output is empty")
	}

	if !strings.Contains(got, "svg") {
		t.Error("expected at least one SVG element in render output")
	}

	if !strings.Contains(got, "BuyCell") {
		t.Error("expected 'BuyCells' tutorial step in render output")
	}

	if !strings.Contains(got, "available") {
		t.Error("expected 'available' label for unowned cells")
	}
}
