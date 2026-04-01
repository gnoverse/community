package trustfactor

import "gno.land/p/nt/mux"

// =============================================================================
// ROUTER SETUP
// =============================================================================

var router *mux.Router

func init() {
	router = mux.NewRouter()

	// Register routes
	router.HandleFunc("", handleHome)
	router.HandleFunc("{address}", handleUserProfile)
}

// =============================================================================
// MAIN ENTRY POINT
// =============================================================================

// Render handles all page routing and displays content based on the URL path
// This is the main entry point for the TrustFactor realm
func Render(path string) string {
	return router.Render(path)
}

// =============================================================================
// ROUTE HANDLERS
// =============================================================================

// handleHome renders the main page with optional search filtering
func handleHome(res *mux.ResponseWriter, req *mux.Request) {
	searchQuery := req.Query.Get("search")
	res.Write(renderMainPageWithFilter(searchQuery))
}

// handleUserProfile renders a specific user's profile page
func handleUserProfile(res *mux.ResponseWriter, req *mux.Request) {
	addr := req.GetVar("address")
	res.Write(renderUserProfile(addr))
}
