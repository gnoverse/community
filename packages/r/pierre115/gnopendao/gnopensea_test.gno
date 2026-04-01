package gnopendao

import (
	"testing"
)

// Test marketplace initialization values
func TestMarketplaceInit(t *testing.T) {
	// Check marketplace fee is set to default (2.5%)
	fee := GetMarketplaceFee()
	if fee != 250 {
		t.Errorf("Expected marketplace fee to be 250, got %d", fee)
	}
}

// Test marketplace fee getter
func TestGetMarketplaceFee(t *testing.T) {
	fee := GetMarketplaceFee()
	if fee < 0 || fee > 1000 {
		t.Errorf("Marketplace fee out of valid range (0-1000): %d", fee)
	}
}

// Test active listings count (should not panic)
func TestGetActiveListingsCount(t *testing.T) {
	count := GetActiveListingsCount()
	if count < 0 {
		t.Errorf("Active listings count should not be negative: %d", count)
	}
}

// Test total sales (should not panic)
func TestGetTotalSales(t *testing.T) {
	sales := GetTotalSales()
	if sales < 0 {
		t.Errorf("Total sales should not be negative: %d", sales)
	}
}

// Test total volume (should not panic)
func TestGetTotalVolume(t *testing.T) {
	volume := GetTotalVolume()
	if volume < 0 {
		t.Errorf("Total volume should not be negative: %d", volume)
	}
}

// Test total royalties paid (should not panic)
func TestGetTotalRoyaltiesPaid(t *testing.T) {
	royalties := GetTotalRoyaltiesPaid()
	if royalties < 0 {
		t.Errorf("Total royalties should not be negative: %d", royalties)
	}
}

// Test marketplace address getter (should not panic)
func TestGetMarketplaceAddress(t *testing.T) {
	addr := GetMarketplaceAddress()
	if addr == "" {
		t.Error("Marketplace address should not be empty")
	}
}

// Test balance getter (should not panic)
func TestGetBalance(t *testing.T) {
	balance := GetBalance()
	if balance < 0 {
		t.Errorf("Balance should not be negative: %d", balance)
	}
}

// Test render home page (should not panic)
func TestRenderHome(t *testing.T) {
	output := Render("")
	if len(output) == 0 {
		t.Error("Home render should not be empty")
	}

	// Check for expected content
	if !contains(output, "Marketplace") {
		t.Error("Home render should contain 'Marketplace'")
	}
}

// Test render stats page (should not panic)
func TestRenderStats(t *testing.T) {
	output := Render("stats")
	if len(output) == 0 {
		t.Error("Stats render should not be empty")
	}

	// Check for expected content
	if !contains(output, "Statistics") {
		t.Error("Stats render should contain 'Statistics'")
	}
}

// Test render invalid path
func TestRenderInvalidPath(t *testing.T) {
	output := Render("invalid/path/test")
	if output != "Page not found" {
		t.Errorf("Expected 'Page not found', got '%s'", output)
	}
}

// Test format price function
func TestFormatPrice(t *testing.T) {
	tests := []struct {
		input    int64
		expected string
	}{
		{1000000, "1.00 GNOT"},
		{5000000, "5.00 GNOT"},
		{100, "0.00 GNOT"},
		{0, "0.00 GNOT"},
	}

	for _, tt := range tests {
		result := formatPrice(tt.input)
		if result != tt.expected {
			t.Errorf("formatPrice(%d) = %s, expected %s", tt.input, result, tt.expected)
		}
	}
}

// Test format fee function
func TestFormatFee(t *testing.T) {
	tests := []struct {
		input    int64
		expected string
	}{
		{250, "2.50%"},
		{500, "5.00%"},
		{1000, "10.00%"},
		{0, "0.00%"},
	}

	for _, tt := range tests {
		result := formatFee(tt.input)
		if result != tt.expected {
			t.Errorf("formatFee(%d) = %s, expected %s", tt.input, result, tt.expected)
		}
	}
}

// Test format percentage function
func TestFormatPercentage(t *testing.T) {
	tests := []struct {
		value    int64
		total    int64
		expected string
	}{
		{25, 100, "25.0%"},
		{50, 100, "50.0%"},
		{0, 100, "0.0%"},
		{100, 100, "100.0%"},
		{0, 0, "0%"}, // Division by zero case
	}

	for _, tt := range tests {
		result := formatPercentage(tt.value, tt.total)
		if result != tt.expected {
			t.Errorf("formatPercentage(%d, %d) = %s, expected %s",
				tt.value, tt.total, result, tt.expected)
		}
	}
}

// Test GetListing with invalid ID (should return zeros)
func TestGetListingInvalid(t *testing.T) {
	id, tokenId, price, seller, active, listedAt := GetListing(999999)

	if id != 0 || tokenId != "" || price != 0 || seller != "" || active != false || listedAt != 0 {
		t.Error("GetListing with invalid ID should return zero values")
	}
}

// Test GetSale with invalid ID (should return zeros)
func TestGetSaleInvalid(t *testing.T) {
	listingId, tokenId, buyer, seller, price, marketFee, royaltyFee, royaltyReceiver, soldAt := GetSale(999999)

	if listingId != 0 || tokenId != "" || buyer != "" || seller != "" ||
		price != 0 || marketFee != 0 || royaltyFee != 0 || royaltyReceiver != "" || soldAt != 0 {
		t.Error("GetSale with invalid ID should return zero values")
	}
}

// Test GetRoyaltyBreakdown with invalid ID (should return zeros)
func TestGetRoyaltyBreakdownInvalid(t *testing.T) {
	sellerAmount, marketFee, royalty, royaltyReceiver := GetRoyaltyBreakdown(999999)

	if sellerAmount != 0 || marketFee != 0 || royalty != 0 || royaltyReceiver != "" {
		t.Error("GetRoyaltyBreakdown with invalid ID should return zero values")
	}
}

// Helper function to check if string contains substring
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr ||
		len(s) > len(substr) && indexOf(s, substr) >= 0)
}

// Helper function to find substring index
func indexOf(s, substr string) int {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return i
		}
	}
	return -1
}
