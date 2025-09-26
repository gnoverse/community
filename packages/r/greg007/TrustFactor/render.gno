package trustfactor

import (
    "std"
    "strconv"
    "strings"
    "time"

    "gno.land/p/nt/ufmt"
    "gno.land/p/leon/svgbtn"
)

// Extract search parameters from URL
func extractSearchParam(path string) string {
    searchVal := ""

    if strings.Contains(path, "?") {
        parts := strings.Split(path, "?")
        if len(parts) > 1 {
            params := strings.Split(parts[1], "&")
            for _, param := range params {
                keyVal := strings.Split(param, "=")
                if len(keyVal) == 2 {
                    if keyVal[0] == "search" {
                        searchVal = keyVal[1]
                    }
                }
            }
        }
    }

    return searchVal
}

// Render search results
func renderSearchResults(query string) string {
    if query == "" {
        return "Veuillez entrer une adresse à rechercher."
    }

    addr := std.Address(query)
    if _, exists := GetAllUsers()[addr]; exists {
        return renderUserProfile(string(addr))
    }

    result := "# 🔍 Résultats de recherche pour: `" + query + "`\n\n"

    var matches []std.Address
    for addr := range GetAllUsers() {
        addrStr := string(addr)
        if len(query) >= 4 && len(addrStr) >= len(query) {
            for i := 0; i <= len(addrStr)-len(query); i++ {
                if addrStr[i:i+len(query)] == query {
                    matches = append(matches, addr)
                    break
                }
            }
        }
    }

    if len(matches) == 0 {
        result += "❌ **Aucun utilisateur trouvé**\n\n"
        result += "**Suggestions :**\n"
        result += "- Vérifiez l'orthographe de l'adresse\n"
        result += "- Essayez avec au moins 4 caractères\n"
        result += "- L'utilisateur doit être enregistré dans le système\n\n"
    } else if len(matches) == 1 {
        return renderUserProfile(string(matches[0]))
    } else {
        result += "✅ **" + strconv.Itoa(len(matches)) + " utilisateur(s) trouvé(s) :**\n\n"

        for _, addr := range matches {
            trust := GetTrustDetails(addr)
            compositeScore := calculateCompositeScore(trust)

            result += "### " + string(addr) + "\n"
            result += "**Score de confiance:** " + ufmt.Sprintf("%.2f", compositeScore) + "/10.0 "

            if trust.Confidence >= 0.8 {
                result += "🟢"
            } else if trust.Confidence >= 0.5 {
                result += "🟡"
            } else {
                result += "🔴"
            }

            result += "\n"
            result += "**Votes:** " + strconv.Itoa(trust.TotalVotes) + " total\n\n"

            detailURL := "/r/greg007/trustfactor:" + string(addr)
            upvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Upvote&target=" + string(addr)
            downvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Downvote&target=" + string(addr)

            result += svgbtn.PrimaryButton(100, 30, "Voir profil", detailURL) + " "
            result += svgbtn.SuccessButton(80, 30, "👍", upvoteURL) + " "
            result += svgbtn.DangerButton(80, 30, "👎", downvoteURL)
            result += "\n\n---\n\n"
        }
    }

    result += svgbtn.SmallButton(100, 30, "← Retour", "/r/greg007/trustfactor")

    return result
}

// Render user profile
func renderUserProfile(path string) string {
    addr := std.Address(path)
    trust := GetTrustDetails(addr)

    if trust.Score == 0 && trust.LastUpdate == 0 {
        result := "# ❌ Utilisateur non trouvé\n\n"
        result += "Aucun score de confiance trouvé pour l'adresse : `" + path + "`\n\n"
        result += "**Suggestions :**\n"
        result += "- Vérifiez que l'adresse est correcte (format g1...)\n"
        result += "- L'utilisateur doit d'abord s'enregistrer\n\n"

        backURL := "/r/greg007/trustfactor"
        result += svgbtn.PrimaryButton(150, 35, "← Retour", backURL)
        return result
    }

    compositeScore := calculateCompositeScore(trust)
    result := "# 👤 Profil détaillé\n\n"
    result += "**Adresse :** `" + path + "`\n\n"

    result += "## 📊 Score\n"
    result += "- **Score de confiance :** " + ufmt.Sprintf("%.2f", compositeScore) + "/10.0\n"
    result += "- **Niveau de confiance :** " + ufmt.Sprintf("%.1f%%", trust.Confidence*100) + "\n\n"

    result += "## 🗳️ Statistiques de votes\n"
    result += "- **Total des votes :** " + strconv.Itoa(trust.TotalVotes) + "\n"
    result += "- **Votes positifs :** 👍 " + strconv.Itoa(trust.PositiveVotes) + "\n"
    result += "- **Votes négatifs :** 👎 " + strconv.Itoa(trust.NegativeVotes) + "\n"

    if trust.TotalVotes > 0 {
        positiveRatio := float64(trust.PositiveVotes) / float64(trust.TotalVotes) * 100
        result += "- **Ratio positif :** " + ufmt.Sprintf("%.1f%%", positiveRatio) + "\n"
    }

    result += "\n## ⏰ Informations temporelles\n"

    // Calculate time since last update
    now := time.Now().Unix()
    daysSince := (now - trust.LastUpdate) / 86400

    timeStr := ""
    if daysSince == 0 {
        timeStr = "Aujourd'hui"
    } else if daysSince == 1 {
        timeStr = "Il y a 1 jour"
    } else if daysSince < 7 {
        timeStr = "Il y a " + strconv.FormatInt(daysSince, 10) + " jours"
    } else if daysSince < 30 {
        weeks := daysSince / 7
        timeStr = "Il y a " + strconv.FormatInt(weeks, 10) + " semaine(s)"
    } else if daysSince < 365 {
        months := daysSince / 30
        timeStr = "Il y a " + strconv.FormatInt(months, 10) + " mois"
    } else {
        years := daysSince / 365
        timeStr = "Il y a " + strconv.FormatInt(years, 10) + " an(s)"
    }

    result += "- **Dernière activité :** " + timeStr + "\n"
    result += "- **Impact temporel :** " + ufmt.Sprintf("%.1f%%", getTimeDecayFactor(trust.LastUpdate)*100) + " (fraîcheur du score)\n\n"

    // Recent vote history (last 5)
    history := GetVoteHistory(addr)
    if len(history) > 0 {
        result += "## 📋 Historique récent des votes\n"
        startIdx := len(history) - 5
        if startIdx < 0 {
            startIdx = 0
        }

        for i := len(history) - 1; i >= startIdx; i-- {
            vote := history[i]
            voteIcon := "👍"
            if vote.VoteType == "downvote" {
                voteIcon = "👎"
            }
            result += "- " + voteIcon + " par `" + string(vote.Voter)[:12] + "...` "
            result += "(poids: " + ufmt.Sprintf("%.1f", vote.Weight) + ")\n"
        }
        result += "\n"
    }

    result += "## 🎯 Actions\n"
    upvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Upvote&target=" + string(addr)
    downvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Downvote&target=" + string(addr)
    backURL := "/r/greg007/trustfactor"

    result += svgbtn.SuccessButton(100, 35, "👍 Upvote", upvoteURL) + " "
    result += svgbtn.DangerButton(100, 35, "👎 Downvote", downvoteURL) + " "
    result += svgbtn.PrimaryButton(100, 35, "← Retour", backURL)

    return result
}

// Fonction pour afficher la page principale avec filtre
func renderMainPageWithFilter(filter string) string {
    result := "# TrustFactor Registry\n\n"

    // Bouton SVG pour s'enregistrer
    registerURL := "https://gno.land/r/greg007/trustfactor$help&func=Register"
    result += svgbtn.SuccessButton(200, 40, "✓ S'enregistrer (Score: 5.0)", registerURL)
    result += "\n\n"

    result += "## 🔍 Rechercher des utilisateurs\n\n"

    if filter != "" {
        result += "**🎯 Filtrage actif pour :** `" + filter + "`\n\n"
        result += svgbtn.SmallButton(120, 30, "🗑️ Effacer filtre", "/r/greg007/trustfactor") + "\n\n"
    }

    result += `<gno-form>
<gno-input name="search" type="text" placeholder="Tapez une partie de l'adresse à rechercher..." />
</gno-form>

`

    result += "**💡 Comment utiliser la recherche :**\n"
    result += "1. Tapez une partie de l'adresse dans le champ ci-dessus\n"
    result += "2. Appuyez sur Entrée ou cliquez Submit\n"
    result += "3. L'URL changera vers `/r/greg007/trustfactor?search=VOTRE_TERME`\n"
    result += "4. La page se rechargera avec les résultats filtrés\n\n"

    // Popular users
    var topUsers []std.Address
    allUsers := GetAllUsers()
    for addr, trust := range allUsers {
        if trust.TotalVotes >= 3 {
            topUsers = append(topUsers, addr)
            if len(topUsers) >= 5 {
                break
            }
        }
    }

    if len(topUsers) > 0 {
        result += "**⭐ Utilisateurs populaires :**\n\n"
        for i, addr := range topUsers {
            trust := GetTrustDetails(addr)
            shortAddr := string(addr)[:12] + "..."
            userURL := "/r/greg007/trustfactor:" + string(addr)
            compositeScore := calculateCompositeScore(trust)

            result += svgbtn.TextButton(140, 30, ufmt.Sprintf("🔍 %s (%.1f)", shortAddr, compositeScore), userURL)
            if i < len(topUsers)-1 {
                result += " "
            }
        }
        result += "\n\n"
    }

    result += "## Trust scores pour les adresses:\n\n"

    const USERS_PER_PAGE = 20
    offset := 0

    filteredAddrs, _ := FilterUsers(filter, USERS_PER_PAGE, offset)

    var users []UserDisplay
    for _, addr := range filteredAddrs {
        trust := GetTrustDetails(addr)
        users = append(users, UserDisplay{
            addr:           addr,
            trust:          trust,
            compositeScore: calculateCompositeScore(trust),
        })
    }

    if len(users) == 0 && filter != "" {
        result += "❌ **Aucun utilisateur trouvé avec le filtre :** `" + filter + "`\n\n"
        result += "Essayez avec une partie différente de l'adresse ou supprimez le filtre.\n\n"
        return result
    }

    if len(users) == 0 {
        result += "Aucun score de confiance enregistré pour le moment.\n\n"
        result += "_Cliquez sur le bouton ci-dessus pour vous enregistrer !_\n"
        return result
    }

    for _, user := range users {
        addr := user.addr
        trust := user.trust
        compositeScore := user.compositeScore

        shortAddr := string(addr)[:12] + "..."
        detailURL := "/r/greg007/trustfactor:" + string(addr)

        result += "### " + svgbtn.TextButton(200, 30, "🔍 " + shortAddr, detailURL) + "\n"
        result += "**Score de confiance:** " + ufmt.Sprintf("%.2f", compositeScore) + "/10.0"

        if trust.Confidence >= 0.8 {
            result += " 🟢"
        } else if trust.Confidence >= 0.5 {
            result += " 🟡"
        } else {
            result += " 🔴"
        }

        result += " **Votes:** " + strconv.Itoa(trust.TotalVotes)
        if trust.TotalVotes > 0 {
            ratio := float64(trust.PositiveVotes) / float64(trust.TotalVotes) * 100
            result += " (" + ufmt.Sprintf("%.0f%% positif", ratio) + ")"
        }
        result += "\n\n"

        upvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Upvote&target=" + string(addr)
        downvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Downvote&target=" + string(addr)

        result += svgbtn.SuccessButton(80, 30, "👍", upvoteURL) + " "
        result += svgbtn.DangerButton(80, 30, "👎", downvoteURL) + " "
        result += svgbtn.SmallButton(80, 30, "Détails", detailURL)
        result += "\n\n---\n\n"
    }

    return result
}