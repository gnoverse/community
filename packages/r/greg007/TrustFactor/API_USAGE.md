# TrustFactor API - Guide d'utilisation pour autres realms

## 🚀 Comment intégrer TrustFactor dans votre realm

### 1. Import du package
```go
import "gno.land/r/greg007/trustfactor"
```

### 2. Fonctions disponibles

#### `QueryTrustScore(addr std.Address) (float64, bool)`
**Usage principal** - Obtenir le score de confiance d'un utilisateur
```go
// Exemple d'utilisation dans votre realm
func CheckUserTrust(userAddr std.Address) string {
    score, exists := trustfactor.QueryTrustScore(userAddr)
    if !exists {
        return "Utilisateur non enregistré dans TrustFactor"
    }

    if score >= 8.0 {
        return "Utilisateur très fiable ✅"
    } else if score >= 6.0 {
        return "Utilisateur fiable 🟡"
    } else {
        return "Utilisateur peu fiable ⚠️"
    }
}
```

#### `QueryUserDetails(addr std.Address) (float64, int, float64, bool)`
**Détails complets** - Score, nombre de votes, niveau de confiance
```go
func GetUserReputationDetails(userAddr std.Address) string {
    score, totalVotes, confidence, exists := trustfactor.QueryUserDetails(userAddr)
    if !exists {
        return "Utilisateur inconnu"
    }

    return ufmt.Sprintf("Score: %.2f | Votes: %d | Confiance: %.1f%%",
                       score, totalVotes, confidence*100)
}
```

#### `IsTrustedUser(addr std.Address, minScore float64) bool`
**Vérification rapide** - Teste si l'utilisateur atteint un seuil
```go
func CanAccessPremiumFeature(userAddr std.Address) bool {
    // Seuls les utilisateurs avec score >= 7.0 peuvent accéder
    return trustfactor.IsTrustedUser(userAddr, 7.0)
}
```

#### `GetUserRank(addr std.Address) (int, int, bool)`
**Classement** - Position de l'utilisateur dans le ranking
```go
func ShowUserRank(userAddr std.Address) string {
    rank, total, exists := trustfactor.GetUserRank(userAddr)
    if !exists {
        return "Utilisateur non classé"
    }

    return ufmt.Sprintf("Rang: %d sur %d utilisateurs", rank, total)
}
```

#### `GetTopTrustedUsers(limit int) []std.Address`
**Top utilisateurs** - Liste des utilisateurs les plus fiables
```go
func ShowTopUsers() string {
    topUsers := trustfactor.GetTopTrustedUsers(5)
    result := "🏆 Top 5 utilisateurs les plus fiables:\n"

    for i, addr := range topUsers {
        score, _ := trustfactor.QueryTrustScore(addr)
        result += ufmt.Sprintf("%d. %s (%.2f)\n", i+1, string(addr)[:12]+"...", score)
    }

    return result
}
```

#### `GetScoreFreshness(addr std.Address) (int64, bool)`
**Fraîcheur** - Ancienneté de la dernière activité
```go
func IsRecentlyActive(userAddr std.Address) bool {
    daysSince, exists := trustfactor.GetScoreFreshness(userAddr)
    if !exists {
        return false
    }

    // Considérer comme récent si activité dans les 30 derniers jours
    return daysSince <= 30
}
```

## 💡 Cas d'usage recommandés

### 🛒 **E-commerce / Marketplace**
```go
func ValidateSeller(sellerAddr std.Address) bool {
    // Vendeur doit avoir score >= 6.0 ET être actif récemment
    isTrusted := trustfactor.IsTrustedUser(sellerAddr, 6.0)
    daysSince, exists := trustfactor.GetScoreFreshness(sellerAddr)

    return isTrusted && exists && daysSince <= 60
}
```

### 🗳️ **Système de gouvernance**
```go
func CanVoteOnProposal(voterAddr std.Address) bool {
    // Voter doit avoir score >= 5.0 ET au moins 3 votes reçus
    score, totalVotes, _, exists := trustfactor.QueryUserDetails(voterAddr)

    return exists && score >= 5.0 && totalVotes >= 3
}
```

### 💬 **Forum / Chat**
```go
func GetUserBadge(userAddr std.Address) string {
    score, exists := trustfactor.QueryTrustScore(userAddr)
    if !exists {
        return "👤 Nouveau"
    }

    if score >= 9.0 {
        return "👑 Expert"
    } else if score >= 7.0 {
        return "⭐ Vétéran"
    } else if score >= 5.0 {
        return "✅ Membre"
    } else {
        return "⚠️ Débutant"
    }
}
```

### 🔒 **Contrôle d'accès**
```go
func CanAccessVIPArea(userAddr std.Address) bool {
    // VIP = Top 10% des utilisateurs
    rank, total, exists := trustfactor.GetUserRank(userAddr)
    if !exists {
        return false
    }

    topTenPercent := total / 10
    return rank <= topTenPercent
}
```

## ⚠️ Bonnes pratiques

1. **Toujours vérifier l'existence** avec le booléen de retour
2. **Définir des seuils adaptés** à votre cas d'usage
3. **Combiner plusieurs critères** (score + votes + fraîcheur)
4. **Prévoir des cas de fallback** pour utilisateurs non enregistrés
5. **Documenter vos seuils** pour la transparence

## 🔗 Intégration type

```go
package myawesomerealm

import (
    "std"
    "gno.land/r/greg007/trustfactor"
    "gno.land/p/nt/ufmt"
)

func ProcessTransaction(from, to std.Address, amount int) {
    // Vérifier la fiabilité des parties
    fromScore, fromExists := trustfactor.QueryTrustScore(from)
    toScore, toExists := trustfactor.QueryTrustScore(to)

    // Ajuster les frais en fonction de la confiance
    fees := calculateFees(amount, fromScore, toScore)

    // Log pour audit
    ufmt.Printf("Transaction: %s (%.2f) -> %s (%.2f) | Frais: %d",
               string(from), fromScore, string(to), toScore, fees)
}
```