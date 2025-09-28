# TrustFactor Registry

A decentralized trust scoring system built on Gno.land that allows users to rate each other and build community reputation.

## Overview

TrustFactor is a trust and reputation system where users can:
- Register with an initial trust score of 5.0/10.0
- Vote on other users (upvote/downvote) based on their own reputation
- View detailed profiles and leaderboards
- Search and filter users by address

## Architecture

The system is organized into 4 main files:

### `types.gno` - Data Structures
- **TrustScore**: Core trust rating with metadata
- **VoteHistory**: Individual voting event records
- **UserDisplay**: Helper struct for rendering

### `logic.gno` - Core Business Logic
- User registration and voting
- Score calculation algorithms
- Performance optimization with caching
- Public API for external realms
- Admin functions

### `render.gno` - User Interface
- URL parameter extraction
- Search results rendering
- User profile pages
- Main page with filtering

### `trustfactor.gno` - Entry Point
- Main Render function for routing

## Public API Functions

### User Registration & Basic Info

#### `Register()`
Registers a new user with initial score of 5.0
```go
func Register(_ realm)
```

#### `GetTrustScore(addr std.Address) (float64, bool)`
Returns the raw trust score for a user
```go
score, exists := GetTrustScore(userAddr)
```

#### `GetCompositeScore(addr std.Address) (float64, bool)`
Returns calculated composite score (with time decay and confidence)
```go
compositeScore, exists := GetCompositeScore(userAddr)
```

#### `GetTrustDetails(addr std.Address) TrustScore`
Returns complete trust information
```go
trustDetails := GetTrustDetails(userAddr)
```

### Voting Functions

#### `Upvote(target std.Address)`
Increases target's trust score based on voter's reputation
```go
func Upvote(_ realm, target std.Address)
```

#### `Downvote(target std.Address)`
Decreases target's trust score based on voter's reputation
```go
func Downvote(_ realm, target std.Address)
```

### Public API for External Realms

#### `QueryTrustScore(addr std.Address) (float64, bool)`
External API to get composite trust score
```go
score, exists := QueryTrustScore(userAddr)
```

#### `QueryUserDetails(addr std.Address) (float64, int, float64, bool)`
Returns (score, totalVotes, confidence, exists)
```go
score, votes, confidence, exists := QueryUserDetails(userAddr)
```

#### `IsTrustedUser(addr std.Address, minScore float64) bool`
Check if user meets minimum trust threshold
```go
isTrusted := IsTrustedUser(userAddr, 7.0)
```

#### `GetUserRank(addr std.Address) (int, int, bool)`
Returns (rank, totalUsers, exists)
```go
rank, total, exists := GetUserRank(userAddr)
```

#### `GetTopTrustedUsers(limit int) []std.Address`
Get N most trusted users
```go
topUsers := GetTopTrustedUsers(10)
```

#### `GetScoreFreshness(addr std.Address) (int64, bool)`
Returns days since last score update
```go
daysSince, exists := GetScoreFreshness(userAddr)
```

### Data Access Functions

#### `GetAllUsers() map[std.Address]TrustScore`
Returns all trust scores (internal use)

#### `GetVoteHistory(addr std.Address) []VoteHistory`
Returns voting history for a user

#### `FilterUsers(searchTerm string, limit int, offset int) ([]std.Address, int)`
Search and paginate users

#### `GetSortedUsers() []std.Address`
Returns users sorted by composite score (cached)

#### `GetPerformanceStats() (int, int, int64)`
Returns (totalUsers, cachedUsers, lastSortTime)

## Scoring Algorithm

### Base Score
- New users start with 5.0/10.0
- Votes impact score based on voter's reputation weight
- Maximum impact per vote: 0.3 points
- Minimum impact per vote: 0.05 points

### Time Decay Factor
- 0-7 days: 100% (no decay)
- 8-30 days: 95%
- 31-90 days: 85%
- 90+ days: 70%

### Confidence Calculation
Based on:
- Vote count (more votes = higher confidence)
- Average voter weight (higher reputation voters = more confidence)
- Positive vs negative ratio

### Final Composite Score
```
timeAdjustedScore = baseScore × timeDecayFactor
confidenceMultiplier = 1.0 + (confidence - 0.5) × 0.4
finalScore = timeAdjustedScore × confidenceMultiplier
```
Clamped to 0.0 - 10.0 range.

## Security Features

- Users cannot vote for themselves
- One vote per user pair (prevents spam)
- Vote weight based on voter's reputation
- Emergency user removal (owner only)
- Clean audit trail via vote history

## Performance Optimizations

- Cached sorted user lists (5 minute TTL)
- Limited vote history per user (50 entries max)
- Efficient quicksort for leaderboards
- Substring search with early termination

## Usage Examples

### Basic Integration
```go
// Check if user is trusted enough for privileged action
if trustfactor.IsTrustedUser(userAddr, 7.0) {
    // Allow privileged action
}

// Get user's reputation details
score, votes, confidence, exists := trustfactor.QueryUserDetails(userAddr)
if exists && confidence > 0.8 {
    // High confidence user
}
```

### Advanced Usage
```go
// Get top 10 trusted users for featured display
topUsers := trustfactor.GetTopTrustedUsers(10)

// Check score freshness
daysSince, exists := trustfactor.GetScoreFreshness(userAddr)
if exists && daysSince > 90 {
    // Score may be stale
}
```

## Admin Functions (Owner Only)

### `RemoveUser(target std.Address)`
Emergency removal of malicious users

### `TransferOwnership(newOwner std.Address)`
Transfer contract ownership

## Constants

- `MAX_HISTORY_SIZE = 50` - Maximum vote history entries per user
- `SORT_CACHE_TTL = 300` - Cache TTL in seconds (5 minutes)

## Web Interface

The system provides a complete web interface at `/r/greg007/trustfactor` with:
- User registration
- Search functionality
- Detailed user profiles
- Voting buttons
- Leaderboards
- Responsive design with SVG buttons