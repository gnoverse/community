export interface NFTListing {
  listingId: number;
  nftAddress: string;
  tokenId: string;
  price: number;
  seller: string;
  image?: string;
  name?: string;
  active: boolean;
}

export interface DAOProposal {
  id: number;
  title: string;
  body: string;
  yesVotes: number;
  noVotes: number;
  totalVotes: number;
  votingEnded: boolean;
  deadline?: number; // Unix timestamp in milliseconds
  status?: "active" | "passed" | "failed";
}

export interface DAOStats {
  totalMembers: number;
  activeProposals: number;
  archivedProposals: number;
  treasuryBalance: number;
}

export interface WalletState {
  address: string | null;
  isConnected: boolean;
  isDAOMember: boolean;
}