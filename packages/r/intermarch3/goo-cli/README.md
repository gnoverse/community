# Goo Oracle CLI

Command-line interface for the Gno Optimistic Oracle (GOO).

## Features

- **Request Management**: Create data requests with custom parameters (auto-queries default reward)
- **Value Proposals**: Propose values for pending requests (auto-queries and sends required bond)
- **AI-Powered Proposals**: Automatically research and propose values using Google Gemini AI with web search
- **Dispute System**: Challenge proposed values and participate in voting (auto-queries and sends required bond)
- **Voting Mechanism**: Commit-reveal voting with local vote storage (auto-queries vote token price)
- **Query Operations**: Read oracle state and parameters
- **Admin Functions**: Manage oracle configuration (requires admin privileges)
- **Verbose Mode**: Use `--verbose` or `-v` flag to see detailed gnokey output
- **Key Override**: Use `--key` flag to override the configured key name for any command
- **User-Friendly Errors**: Automatic parsing of contract errors into friendly messages

## Installation

```bash
# Install dependencies
go mod download

# use make
make build

# Install globally
make install
```

## Configuration

Initialize your configuration:

```bash
goo config init
```

This creates `~/.goo/config.yaml` with default values. Edit this file to customize:

```yaml
keyname: mykey
realm_path: gno.land/r/intermarch3/goo
chain_id: test4
remote: https://rpc.test4.gno.land:443
gas_fee: 1000000ugnot
gas_wanted: 2000000
google_api_key: ""  # Optional: for AI-powered proposals
```

View current configuration:

```bash
goo config show
```

## Usage

### Global Flags

All commands support these global flags:
- `--key <keyname>`: Override the key name from config
- `--verbose` or `-v`: Enable verbose output (shows full gnokey commands and output)

### Request Commands

**Create a new request:**
```bash
# Numeric question (reward auto-queried if not specified)
goo request create \
  --question "What is the ETH/USD price on 2025-10-27 12:00 UTC?" \
  --deadline "2025-10-28T12:00:00Z"

# Yes/No question
goo request create \
  --question "Did BTC reach $100,000 by 2025-10-27?" \
  --yesno \
  --deadline "2025-10-28T12:00:00Z"

# With custom reward
goo request create \
  --question "ETH/USD price?" \
  --deadline "2025-10-28T12:00:00Z" \
  --reward 2000000
```

**Get request details:**
```bash
goo request get 0000001
```

**Retrieve unfulfilled request funds:**
```bash
goo request retrieve-fund 0000001
```

### Propose Commands

**Propose a value (manual):**
```bash
goo propose value 0000001 3500
```

**Propose a value (AI-powered with web search):**
```bash
goo propose value 0000001 --search
```

**Resolve a non-disputed request:**
```bash
goo propose resolve 0000001
```

### Dispute Commands

**Create a dispute:**
```bash
goo dispute create 0000001
```

**Get dispute details:**
```bash
goo dispute get 0000001
```

**Resolve a dispute:**
```bash
goo dispute resolve 0000001
```

### Vote Commands

**Buy vote token:**
```bash
goo vote buy-token
```

**Check vote balance:**
```bash
goo vote balance
```

**Commit a vote:**
```bash
# With auto-generated salt
goo vote commit 0000001 3500

# With custom salt
goo vote commit 0000001 3500 --salt my-random-salt
```

**Reveal a vote:**
```bash
goo vote reveal 0000001
```

### Query Commands

**Get request result:**
```bash
goo query result 0000001
```

**Get oracle parameters:**
```bash
goo query params
```

**List requests:**
```bash
goo query list
goo query list --state Proposed
```

### Admin Commands

**Set resolution duration:**
```bash
goo admin set-resolution-duration 120
```

**Set requester reward:**
```bash
goo admin set-reward 2000000
```

**Set bond amount:**
```bash
goo admin set-bond 3000000
```

**Change admin:**
```bash
goo admin change-admin g1abcdef...
```

## Typical Workflow

1. **Setup:**
   ```bash
   goo config init
   ```

2. **Create a request:**
   ```bash
   goo request create --question "ETH/USD?" --deadline "2025-10-28T12:00:00Z"
   ```

3. **Propose a value (manual or AI-powered):**
   ```bash
   # Manual
   goo propose value 0000001 3500
   
   # Or let AI research it
   goo propose value 0000001 --search
   ```

4. **Someone disputes (if they disagree):**
   ```bash
   goo dispute create 0000001
   ```

5. **Buy vote token (if needed):**
   ```bash
   goo vote buy-token
   ```

6. **Commit vote:**
   ```bash
   goo vote commit 0000001 3500
   ```

7. **Reveal vote (after voting period):**
   ```bash
   goo vote reveal 0000001
   ```

8. **Resolve dispute:**
   ```bash
   goo dispute resolve 0000001
   ```

9. **Check result:**
   ```bash
   goo query result 0000001
   ```

## Vote Data Storage

When you commit a vote, the CLI automatically saves your vote data locally at:

```
~/.goo/votes/<request-id>.json
```

This file contains:
- Request ID
- Vote value
- Salt used for hashing
- Generated hash
- Timestamp

This data is automatically loaded when you reveal your vote.

## Advanced Features

### Verbose Mode

By default, the CLI shows clean, minimal output with user-friendly error messages. Use `--verbose` or `-v` to see:
- Full gnokey commands being executed
- Complete transaction output including TX hash and gas info
- Detailed error messages and stack traces

Example:
```bash
# Default mode (clean output)
goo propose value 0000001 3500

# Verbose mode (detailed output)
goo propose value 0000001 3500 --verbose
```

### Key Override

Override the configured key name for a single command without modifying your config:

```bash
# Use a different key for this transaction
goo propose value 0000001 3500 --key myotherkey
```

### Error Handling

The CLI automatically parses contract errors and displays friendly messages:
- ❌ Request not found - invalid request ID
- ❌ Proposal deadline has passed
- ❌ You need to buy a vote token first ('goo vote buy-token')
- And 30+ more error patterns

Unknown errors display the full error message for debugging.

## Project Structure

```
goo-cli/
├── cmd/goo/              # Main entry point
├── internal/
│   ├── commands/         # Command implementations
│   │   ├── request.go   # Request commands
│   │   ├── propose.go   # Propose commands
│   │   ├── dispute.go   # Dispute commands
│   │   ├── vote.go      # Vote commands
│   │   ├── query.go     # Query commands
│   │   ├── admin.go     # Admin commands
│   │   └── config.go    # Config commands
│   ├── gnokey/          # gnokey execution wrapper
│   │   └── executor.go  # Transaction and query execution
│   ├── config/          # Configuration management
│   │   └── config.go    # Config loading and key override
│   └── utils/           # Utility functions
│       ├── errors.go    # Error parsing and friendly messages
│       ├── format.go    # Formatting utilities
│       └── print.go     # Output helpers
└── pkg/types/           # Type definitions
```

## Developer

| [<img src="https://github.com/intermarch3.png?size=85" width=85><br><sub>Lucas Leclerc</sub>](https://github.com/intermarch3) |
| :---: |