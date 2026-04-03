# 🌍 Geo-Resto

A Gno-based realm for creating a decentralized, on-chain record of real-world places and visits.

## Core Features

- **Location Management**: Add and verify geographic locations, creating a permanent, user-owned registry.
- **Proof of Presence**: Check-in at locations using a secure challenge-response mechanism to prove you were there.
- **Event System**: Organize location-based events like meetups, airdrops, or community gatherings.
- **QR Code Verification**: A robust system for event organizers to securely verify attendee presence in real-time.
- **On-Chain History**: All data is immutable, timestamped, and verifiable on the Gno blockchain.

## How It Works

The realm is organized into modules that handle specific tasks:

- `geo_resto.gno`: The main entry point and public API.
- `location.gno`: Manages location data.
- `visit.gno`: Handles check-ins and visit history.
- `event.gno`: Manages the event lifecycle.
- `auth.gno`: Secures the system with rate-limiting, access control, and verification logic.
- `renderer.gno`: Renders the web interface.

## Quick Start

### Add a Location
```gno
AddLocation("Eiffel Tower", "Iconic tower in Paris", 48.8584, 2.2945, "landmark")
```

### Check-In at a Location
1.  **Get the challenge:**
    ```gno
    GetLocationChallenge("loc_1")
    ```
2.  **Submit the proof (challenge response):**
    ```gno
    CheckIn("loc_1", "proof_from_challenge")
    ```

### Create an Event
```gno
CreateEvent("loc_1", "Tech Meetup", "Weekly discussion", "", 1, startTime, endTime)
```

## Event QR Code Verification

A secure system for proving event attendance.

- **Organizers**: Create an event to get a QR code. At the event, generate temporary verification codes for attendees using `GenerateAttendeeCode("event_1")`.
- **Attendees**: Get verified by the organizer.
- **Stats**: Organizers can track attendance with `GetVerifiedAttendees("event_1")` and `GetEventVerificationStats("event_1")`.

## Future Ideas

- **Zero-Knowledge Proofs**: For privacy-preserving check-ins.
- **Community Governance**: Location ratings, reviews, and decentralized moderation.
- **Enhanced Visuals**: Richer map interfaces and data visualizations.

## Testing

Run the full test suite with:
```bash
gno test
```

