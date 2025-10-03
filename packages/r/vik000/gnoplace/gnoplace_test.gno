package gnoplace

import (
	"strings"
	"testing"

	"gno.land/p/nt/testutils"
	"gno.land/p/nt/urequire"
)

var (
	user1 = testutils.TestAddress("user1")
	user2 = testutils.TestAddress("user2")
	user3 = testutils.TestAddress("user3")
)

func TestGnoPlace(t *testing.T) {
	// Test initial render
	output := Render("")
	urequire.True(t, strings.Contains(output, "GnoPlace"), "should contain title")

	// Test render with color parameter
	output = Render("?color=1")
	urequire.True(t, strings.Contains(output, "with color"), "should show selected color")

	// User 1 sets a pixel
	testing.SetRealm(testing.NewUserRealm(user1))
	urequire.NotPanics(t, func() {
		SetPixel(cross, 0, 1)
	}, "user1 should be able to set pixel")

	// User 1 tries to set another pixel too soon (should panic)
	urequire.AbortsWithMessage(t, "you placed a pixel less than 30s ago", func() {
		SetPixel(cross, 2, 3)
	}, "user1 should not be able to set pixel too soon")

	// User 2 sets a different pixel (should work immediately)
	testing.SetRealm(testing.NewUserRealm(user2))
	urequire.NotPanics(t, func() {
		SetPixel(cross, 1, 2)
	}, "user2 should be able to set pixel")
}

func TestSetPixel_InvalidInputs(t *testing.T) {
	testing.SetRealm(testing.NewUserRealm(user1))

	// Test invalid pixel (negative)
	urequire.AbortsWithMessage(t, "invalid pixel", func() {
		SetPixel(cross, -1, 1)
	})

	// Test invalid pixel (out of bounds)
	urequire.AbortsWithMessage(t, "invalid pixel", func() {
		SetPixel(cross, 300, 1)
	})

	// Test invalid color (negative)
	urequire.AbortsWithMessage(t, "invalid color", func() {
		SetPixel(cross, 0, -1)
	})

	// Test invalid color (out of bounds)
	urequire.AbortsWithMessage(t, "invalid color", func() {
		SetPixel(cross, 0, 10)
	})
}

func TestAtoiDefault(t *testing.T) {
	urequire.Equal(t, 10, atoiDefault("", 10), "empty string should return default")
	urequire.Equal(t, 5, atoiDefault("5", 10), "valid number should be parsed")
	urequire.Equal(t, 0, atoiDefault("0", 10), "zero should be parsed")
	urequire.Equal(t, 0, atoiDefault("invalid", 10), "invalid string should return 0")
}

func TestRenderPixel(t *testing.T) {
	// Set a pixel to test rendering
	testing.SetRealm(testing.NewUserRealm(user3))
	SetPixel(cross, 0, 1)

	// Test render pixel function
	output := renderPixel(0, 1)
	urequire.True(t, strings.Contains(output, "SetPixel"), "should contain SetPixel call")
}
