# GnoBounty

A decentralized bounty system for managing rewards on GitHub issues (or any issue tracker) using the Gno blockchain, with DAO-based validation through validator voting.

## Features

- **Create Bounties**: Post a bounty on any issue by providing the issue URL and sending GNOT tokens
- **Apply for Bounties**: Submit your merged PR link to apply for a bounty
- **DAO Validation**: 3 validators are randomly selected to vote on each application
- **Automatic Claims**: Bounties are automatically claimed when 2/3 validators approve
- **Validator System**: Decentralized validation through registered validators
- **Cancel Bounties**: Creators can cancel unclaimed bounties and receive a refund
- **List Bounties**: Browse all active bounties with reward amounts
- **Transparent**: All bounties and applications are stored on-chain and publicly viewable

## How to Use

### Creating a Bounty

To create a bounty, call the `CreateBounty` function with the issue URL and description, and send GNOT tokens:

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/greg007/gnobounty" \
  -func "CreateBounty" \
  -args "https://github.com/gnolang/gno/issues/1234" \
  -args "Fix the rendering bug in GRC20 token display" \
  -send "5000000ugnot" \
  -gas-fee "1000000ugnot" \
  -gas-wanted "2000000" \
  -broadcast \
  -chainid "dev" \
  -remote "localhost:26657" \
  mykey
```

**Parameters:**
- `issueURL`: The URL of the issue (GitHub, GitLab, etc.)
- `description`: A brief description of what needs to be done
- `send`: The bounty amount in ugnot (1 GNOT = 1,000,000 ugnot)

**Minimum bounty**: 1 GNOT (1,000,000 ugnot)

### Viewing Bounties

Visit the realm in your browser to see all active bounties:

```
https://gno.land/r/greg007/gnobounty
```

Or view a specific bounty by ID:

```
https://gno.land/r/greg007/gnobounty/1
```

### Applying for a Bounty

When you complete work on a bounty, submit your merged PR link to apply:

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/greg007/gnobounty" \
  -func "ApplyForBounty" \
  -args "1" \
  -args "https://github.com/gnolang/gno/pull/5678" \
  -gas-fee "1000000ugnot" \
  -gas-wanted "2000000" \
  -broadcast \
  -chainid "dev" \
  -remote "localhost:26657" \
  mykey
```

**Parameters:**
- First arg: Bounty ID
- Second arg: URL of your merged pull request

**What happens next:**
1. Your application is created
2. 3 random validators are selected from the validator pool
3. Validators review your PR and vote to approve or reject
4. If 2 out of 3 validators approve, the bounty is automatically transferred to you!

### Validator Voting

If you're a registered validator, you can vote on applications assigned to you:

```bash
# Approve an application
gnokey maketx call \
  -pkgpath "gno.land/r/greg007/gnobounty" \
  -func "Vote" \
  -args "1" \
  -args "true" \
  -gas-fee "1000000ugnot" \
  -gas-wanted "2000000" \
  -broadcast \
  -chainid "dev" \
  -remote "localhost:26657" \
  mykey

# Reject an application
gnokey maketx call \
  -pkgpath "gno.land/r/greg007/gnobounty" \
  -func "Vote" \
  -args "1" \
  -args "false" \
  -gas-fee "1000000ugnot" \
  -gas-wanted "2000000" \
  -broadcast \
  -chainid "dev" \
  -remote "localhost:26657" \
  mykey
```

**Parameters:**
- First arg: Application ID
- Second arg: "true" to approve, "false" to reject

### Legacy: Manual Claiming (deprecated)

The old manual claim system is still available but deprecated in favor of DAO validation:

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/greg007/gnobounty" \
  -func "ClaimBounty" \
  -args "1" \
  -args "g1abc123...xyz" \
  -gas-fee "1000000ugnot" \
  -gas-wanted "2000000" \
  -broadcast \
  -chainid "dev" \
  -remote "localhost:26657" \
  mykey
```

### Cancelling a Bounty

If you need to cancel a bounty and get your funds back:

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/greg007/gnobounty" \
  -func "CancelBounty" \
  -args "1" \
  -gas-fee "1000000ugnot" \
  -gas-wanted "2000000" \
  -broadcast \
  -chainid "dev" \
  -remote "localhost:26657" \
  mykey
```

**Note:** You can only cancel bounties that haven't been claimed yet.

## API Reference

### Bounty Functions

#### `CreateBounty(cur realm, issueURL, description string) uint64`
Creates a new bounty and returns the bounty ID. Must send GNOT with the transaction.

#### `GetBounty(id uint64) *Bounty`
Returns bounty details by ID.

#### `CancelBounty(cur realm, id uint64)`
Cancels a bounty and refunds the creator. Only callable by the bounty creator on unclaimed bounties.

#### `ListBounties() string`
Returns a formatted list of all active bounties.

#### `GetBountyDetails(id uint64) string`
Returns detailed information about a specific bounty with apply button.

#### `GetBountyCount() uint64`
Returns the total number of bounties created.

### Application & Voting Functions

#### `ApplyForBounty(cur realm, bountyID uint64, prLink string) uint64`
Submit an application for a bounty with your merged PR link. Returns the application ID.
- Automatically selects 3 random validators
- Creates a pending application
- Returns application ID

#### `Vote(cur realm, applicationID uint64, approve bool)`
Vote on an application (validator only). Must be one of the selected validators.
- `approve`: true to approve, false to reject
- Automatically claims bounty if 2/3 validators approve

#### `GetApplication(id uint64) *Application`
Returns application details by ID.

#### `GetApplicationsForBounty(bountyID uint64) []*Application`
Returns all applications for a specific bounty.

#### `GetApplicationsForValidator(validatorAddr address) []*Application`
Returns all applications assigned to a validator for voting.

#### `GetApplicationCount() uint64`
Returns the total number of applications created.

### Validator Management Functions

#### `AddValidator(cur realm, validatorAddr address)`
Adds a new validator to the system (admin function).

#### `RemoveValidator(cur realm, validatorAddr address)`
Deactivates a validator (admin function).

#### `IsValidator(addr address) bool`
Checks if an address is an active validator.

#### `GetActiveValidatorCount() int`
Returns the number of active validators.

#### `ListValidators() string`
Returns a formatted list of all validators and their status.

### Rendering Functions

#### `RenderMyVotes(validatorAddr address) string`
Shows pending applications that need votes from the specified validator, with approve/reject buttons.

#### `Render(path string) string`
Main render function for the realm.

### Bounty Structure

```go
type Bounty struct {
    ID          uint64    // Unique bounty identifier
    IssueURL    string    // Link to the issue
    Description string    // Description of the work
    Amount      int64     // Reward amount in ugnot
    Creator     address   // Address of the bounty creator
    CreatedAt   time.Time // When the bounty was created
    IsClaimed   bool      // Whether the bounty has been claimed
    Claimer     address   // Address of the claimer (if claimed)
    ClaimedAt   time.Time // When the bounty was claimed
}
```

## Example Workflow

1. **Alice creates a bounty** for fixing a bug, sending 5 GNOT:
   ```
   CreateBounty("https://github.com/project/repo/issues/42", "Fix memory leak in parser")
   ```

2. **Bob sees the bounty** and decides to work on it. He visits the issue URL and starts coding.

3. **Bob completes the work** and submits a pull request fixing the issue.

4. **Alice verifies the fix** and approves Bob's claim:
   ```
   ClaimBounty(cross, 1, "g1bob123...xyz")
   ```

5. **Bob receives 5 GNOT** automatically to his address!

## Security Considerations

- Only the bounty creator can approve claims
- Bounties are locked in the realm contract until claimed or cancelled
- Once claimed, bounties cannot be cancelled
- The realm must have sufficient funds to pay out bounties

## Notes

- This implementation uses the new Gno standard library split (post-#3874)
- Amounts are stored in ugnot (micro-GNOT): 1 GNOT = 1,000,000 ugnot
- The `address` type is used as a builtin instead of `std.Address`
- Uses new imports:
  - `gno.land/r/sys/chain` for `Coin` and `Coins` types
  - `gno.land/r/sys/chain/banker` for banker operations (`NewBanker`, `BankerType*`, `OriginSend`)
  - `gno.land/r/sys/chain/runtime` for realm functions (`PreviousRealm`, `CurrentRealm`)

## License

MIT
