package trustfactor

// Main entry point - only contains the Render function
func Render(path string) string {
    // Gérer les paramètres de recherche pour le filtrage
    searchParam := extractSearchParam(path)
    if searchParam != "" {
        return renderMainPageWithFilter(searchParam)
    }

    if path == "" {
        return renderMainPageWithFilter("")
    }

    return renderUserProfile(path)
}