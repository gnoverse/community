package trustfactor

// =============================================================================
// MAIN ENTRY POINT
// =============================================================================

// Render handles all page routing and displays content based on the URL path
// This is the main entry point for the TrustFactor realm
func Render(path string) string {
    searchParam := extractSearchParam(path)
    if searchParam != "" {
        return renderMainPageWithFilter(searchParam)
    }

    if path == "" {
        return renderMainPageWithFilter("")
    }

    return renderUserProfile(path)
}