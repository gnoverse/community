# GnopenSea Frontend

Next.js frontend for the decentralized NFT marketplace GnopenSea on Gno.land.

## 🚀 Quick Start

### 1. Installation

```bash
npm install
```

### 2. Network Configuration

The frontend is configured for the Gno.land **Staging** network.

**Current settings** (see [`src/lib/gno.ts`](src/lib/gno.ts)):
- RPC: `https://rpc.gno.land:443`
- Chain ID: `staging`
- Marketplace: `gno.land/r/pierre115/gnopendao8`
- Registry: `gno.land/r/pierre115/daoregistry4`

### 3. Adena Wallet Configuration

To interact with the application, configure [Adena Wallet](https://adena.app/):

1. Install the Adena extension
2. Add the **Staging** network:
   - Network Name: `Gno Staging`
   - RPC URL: `https://rpc.gno.land:443`
   - Chain ID: `staging`
3. Switch to this network in Adena

### 4. Start Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to view the application.

---

## 📁 Project Structure

```
src/
├── app/
│   ├── page.tsx              # Homepage with NFT listings
│   ├── dao/
│   │   └── page.tsx          # DAO governance page
│   ├── layout.tsx            # Main layout
│   └── globals.css           # Global styles (holographic effects)
├── components/
│   ├── Header.tsx            # Header with wallet connect
│   ├── nft/
│   │   └── NFTCard.tsx       # NFT card component
│   └── ui/                   # UI components (buttons, cards, etc.)
├── lib/
│   ├── gno.ts               # RPC and realms configuration
│   ├── realm-calls.ts       # Smart contract calls
│   └── types.ts             # TypeScript types
└── hooks/
    └── useWallet.ts         # Adena wallet hook
```

---

## 🔧 Configuration

### Switching Networks

To switch to another network (test4, mainnet, etc.), modify [`src/lib/gno.ts`](src/lib/gno.ts):

```typescript
export const provider = new GnoJSONRPCProvider(
  "https://rpc.YOUR_NETWORK.gno.land"
);

export const CHAIN_ID = "YOUR_CHAIN_ID";
export const MARKETPLACE_REALM = "gno.land/r/YOUR_USERNAME/YOUR_REALM";
```

See [NETWORK_CONFIG.md](NETWORK_CONFIG.md) for more details.

---

## 🎨 Features

- ✅ Display NFTs listed on the marketplace
- ✅ Real-time statistics (active listings, volume, sales)
- ✅ Interface with holographic effects and animations
- ✅ Adena wallet connection
- ✅ Buy NFTs
- ✅ DAO governance system
- ✅ Vote on proposals (Yes/No)
- ✅ Execute proposals after voting period
- ✅ Countdown timer for active proposals

---

## 🛠️ Technologies

- **Next.js 16** - React framework
- **TypeScript** - Static typing
- **Tailwind CSS v4** - Styling
- **TanStack Query** - Query management
- **@gnolang/gno-js-client** - Gno.land RPC client
- **Adena Wallet** - Gno.land wallet

---

## 📝 Available Scripts

```bash
# Development
npm run dev

# Production build
npm run build

# Run in production
npm start

# Linter
npm run lint
```

---

## Environment Variables (Future)

To facilitate network switching, you can create a `.env.local` file:

```env
NEXT_PUBLIC_RPC_ENDPOINT=https://rpc.gno.land:443
NEXT_PUBLIC_CHAIN_ID=staging
NEXT_PUBLIC_MARKETPLACE_REALM=gno.land/r/pierre115/gnopendao8
NEXT_PUBLIC_REGISTRY_REALM=gno.land/r/pierre115/daoregistry4
```
Or your own path !
---

## 🔍 Troubleshooting

### "Network Error" in console

- Check that the Staging network is online
- Check your internet connection
- Visit [https://rpc.gno.land:443](https://rpc.gno.land:443)

### No data displayed

- The marketplace might be empty (no listed NFTs)
- Check the realms in [`src/lib/gno.ts`](src/lib/gno.ts)
- Open the console to see errors

### Wallet won't connect

- Check that Adena is installed
- Check that Adena is on the `staging` network
- Reload the page

---

## 📚 Complete Documentation

- [Network Configuration](NETWORK_CONFIG.md)
- [Smart Contracts (Backend)](../community/packages/r/pierre115/gnopendao/README.md)

---

## 🤝 Contribution

This project is part of the GnopenSea internship - Decentralized NFT marketplace with DAO governance.

---

## 📄 License

Internship project - All rights reserved
