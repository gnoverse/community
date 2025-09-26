# TrustFactor

A Gno smart contract for managing trust scores between addresses.

## Features

- Set trust scores (0-100) for any address
- Query trust scores and evaluation details
- Web-based rendering of trust data

## Usage

### Setting a Trust Score
```go
SetTrustScore(targetAddress, 85) // Set score to 85/100
```

### Getting a Trust Score
```go
score, exists := GetTrustScore(address)
```

### Getting Full Trust Details
```go
details := GetTrustDetails(address)
```

## Web Interface

Visit the deployed realm to see trust scores rendered as a web page.