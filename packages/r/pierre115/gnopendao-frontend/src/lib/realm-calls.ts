import { provider, MARKETPLACE_REALM, parseRealmResponse } from "./gno";
import { NFTListing, DAOProposal } from "./types";

// Get all active NFT listings
export async function getActiveListings(): Promise<NFTListing[]> {
  try {
    console.log("🔍 MARKETPLACE_REALM utilisé:", MARKETPLACE_REALM);

    const response = await provider.evaluateExpression(
      MARKETPLACE_REALM,
      "GetAllListings()"
    );

    const parsed = parseRealmResponse(response);

    console.log("🔍 DEBUG getActiveListings:");
    console.log("  Raw response:", response);
    console.log("  Parsed:", parsed);

    if (parsed === "No active listings") {
      return [];
    }

    const lines = parsed.split("\n").filter(line => line.trim());
    console.log("  Lines count:", lines.length);

    return lines
      .filter(line => {
        const parts = line.split("|");
        if (parts.length < 7) {
          console.warn("❌ Invalid listing format:", line);
          console.warn("   Expected 7 parts, got:", parts.length);
          return false;
        }
        return true;
      })
      .map((line, index) => {
        const parts = line.split("|");
        const [listingId, nftAddress, tokenId, price, seller, image, name] = parts;

        console.log(`\n📦 Listing #${index + 1} parsing:`);
        console.log("  RAW line:", line);
        console.log("  Parts count:", parts.length);
        console.log("  [5] Image raw:", `"${image}"`, "| Length:", image?.length || 0);
        console.log("  [6] Name raw:", `"${name}"`, "| Length:", name?.length || 0);

        // Use image from metadata directly (no hardcoding)
        const imageUrl = image?.trim() || "";
        const finalImage = (imageUrl && imageUrl !== '""')
          ? imageUrl
          : ""; // No default image, trust the backend

        const finalName = (name && name.trim() && name !== "\"\"")
          ? name.trim()
          : `NFT #${tokenId}`;

        console.log("  ✓ Final Image:", finalImage);
        console.log("  ✓ Final Name:", finalName);

        return {
          listingId: parseInt(listingId) || 0,
          nftAddress: nftAddress?.trim() || "",
          tokenId: tokenId?.trim() || "0",
          price: parseInt(price) || 0,
          seller: seller?.trim() || "",
          image: finalImage,
          name: finalName,
          active: true,
        };
      });
  } catch (error) {
    console.error("Failed to get listings:", error);
    return []; // Return empty array instead of crashing
  }
}

export async function getMarketplaceStats() {
  try {
    console.log("📊 [getMarketplaceStats] Fetching stats...");

    const [activeListings, totalSales, totalVolume, balance] = await Promise.all([
      provider.evaluateExpression(MARKETPLACE_REALM, "GetActiveListingsCount()"),
      provider.evaluateExpression(MARKETPLACE_REALM, "GetTotalSales()"),
      provider.evaluateExpression(MARKETPLACE_REALM, "GetTotalVolume()"),
      provider.evaluateExpression(MARKETPLACE_REALM, "GetBalance()"),
    ]);

    console.log("📊 Raw responses:");
    console.log("  activeListings:", `"${activeListings}"`);
    console.log("  totalSales:", `"${totalSales}"`);
    console.log("  totalVolume:", `"${totalVolume}"`);
    console.log("  balance:", `"${balance}"`);

    // Parse responses before converting to int (Gno.land returns formatted strings)
    const parsed = {
      activeListings: parseRealmResponse(activeListings),
      totalSales: parseRealmResponse(totalSales),
      totalVolume: parseRealmResponse(totalVolume),
      balance: parseRealmResponse(balance),
    };

    console.log("📊 Parsed responses:");
    console.log("  activeListings:", `"${parsed.activeListings}"`);
    console.log("  totalSales:", `"${parsed.totalSales}"`);
    console.log("  totalVolume:", `"${parsed.totalVolume}"`);
    console.log("  balance:", `"${parsed.balance}"`);

    const result = {
      activeListings: parseInt(parsed.activeListings) || 0,
      totalSales: parseInt(parsed.totalSales) || 0,
      totalVolume: parseInt(parsed.totalVolume) || 0,
      balance: parseInt(parsed.balance) || 0,
    };

    console.log("📊 Final stats:", result);

    return result;
  } catch (error) {
    console.error("Failed to get stats:", error);
    // Return default data instead of null
    return {
      activeListings: 0,
      totalSales: 0,
      totalVolume: 0,
      balance: 0,
    };
  }
}

// Get active DAO proposals
export async function getActiveProposals(): Promise<DAOProposal[]> {
  try {
    console.log("🗳️ [getActiveProposals] Fetching proposals...");

    const response = await provider.evaluateExpression(
      MARKETPLACE_REALM,
      "GetAllActiveProposals()"
    );

    console.log("🗳️ Raw response:", `"${response}"`);

    const parsed = parseRealmResponse(response);

    console.log("🗳️ Parsed response:", parsed);

    if (parsed.includes("No active proposals")) {
      console.log("🗳️ No active proposals found");
      return [];
    }

    // Parse the response - format: "ID: X | Title | Yes: Y | No: Z | Deadline: timestamp | Ended: bool"
    const lines = parsed.split("\n").filter(line => line.trim());

    console.log("🗳️ Total lines:", lines.length);
    console.log("🗳️ Lines:", lines);

    return lines
      .map((line, index) => {
        console.log(`🗳️ Parsing line ${index}:`, `"${line}"`);

        const idMatch = line.match(/ID: (\d+)/);
        const titleMatch = line.match(/\| ([^|]+) \|/);
        const yesMatch = line.match(/Yes: (\d+)/);
        const noMatch = line.match(/No: (\d+)/);
        const deadlineMatch = line.match(/Deadline: (\d+)/);
        const endedMatch = line.match(/Ended: (true|false)/);

        const yesVotes = yesMatch ? parseInt(yesMatch[1]) : 0;
        const noVotes = noMatch ? parseInt(noMatch[1]) : 0;
        const deadline = deadlineMatch ? parseInt(deadlineMatch[1]) * 1000 : Date.now(); // Convert to milliseconds
        const votingEnded = endedMatch ? endedMatch[1] === "true" : false;

        return {
          id: idMatch ? parseInt(idMatch[1]) : index,
          title: titleMatch ? titleMatch[1].trim() : "Proposal",
          body: "",
          yesVotes,
          noVotes,
          totalVotes: yesVotes + noVotes,
          votingEnded,
          deadline,
        };
      })
      .filter((proposal) => {
        // Filter out invalid proposals (lines that don't match the expected format)
        const hasValidId = proposal.id > 0;
        const hasValidTitle = proposal.title !== "Proposal";
        return hasValidId && hasValidTitle;
      });
  } catch (error) {
    console.error("Failed to get proposals:", error);
    return [];
  }
}

// Get finished DAO proposals
export async function getFinishedProposals(): Promise<DAOProposal[]> {
  try {
    console.log("🗳️ [getFinishedProposals] Fetching finished proposals...");

    const response = await provider.evaluateExpression(
      MARKETPLACE_REALM,
      "GetAllFinishedProposals()"
    );

    console.log("🗳️ Raw response:", `"${response}"`);

    const parsed = parseRealmResponse(response);

    console.log("🗳️ Parsed response:", parsed);

    if (parsed.includes("No finished proposals")) {
      console.log("🗳️ No finished proposals found");
      return [];
    }

    // Parse the response - format: "ID: 1 | Title | Yes: 5 | No: 2 | Status: passed"
    const lines = parsed.split("\n").filter(line => line.trim());

    console.log("🗳️ Total lines:", lines.length);
    console.log("🗳️ Lines:", lines);

    return lines
      .map((line, index) => {
        console.log(`🗳️ Parsing line ${index}:`, `"${line}"`);

        const idMatch = line.match(/ID: (\d+)/);
        const titleMatch = line.match(/\| ([^|]+) \|/);
        const yesMatch = line.match(/Yes: (\d+)/);
        const noMatch = line.match(/No: (\d+)/);
        const statusMatch = line.match(/Status: (\w+)/);

        const yesVotes = yesMatch ? parseInt(yesMatch[1]) : 0;
        const noVotes = noMatch ? parseInt(noMatch[1]) : 0;

        const status = statusMatch ? statusMatch[1] : undefined;
        const validStatus: "passed" | "failed" | "active" | undefined =
          status === "passed" ? "passed" :
          status === "failed" ? "failed" :
          status === "active" ? "active" : undefined;

        return {
          id: idMatch ? parseInt(idMatch[1]) : index,
          title: titleMatch ? titleMatch[1].trim() : "Proposal",
          body: "",
          yesVotes,
          noVotes,
          totalVotes: yesVotes + noVotes,
          votingEnded: true,
          status: validStatus,
        };
      })
      .filter((proposal) => {
        // Filter out invalid proposals (lines that don't match the expected format)
        const hasValidId = proposal.id > 0;
        const hasValidTitle = proposal.title !== "Proposal";
        return hasValidId && hasValidTitle;
      });
  } catch (error) {
    console.error("Failed to get finished proposals:", error);
    return [];
  }
}

// Get total DAO members count
export async function getDAOMembersCount(): Promise<number> {
  try {
    const response = await provider.evaluateExpression(
      MARKETPLACE_REALM,
      "GetTotalMembers()"
    );

    const parsed = parseRealmResponse(response);
    return parseInt(parsed) || 0;
  } catch (error) {
    console.error("Failed to get DAO members count:", error);
    return 0;
  }
}

// Buy NFT transaction
export async function buyNFT(listingId: number, price: number) {
  console.log("\n💳 [buyNFT] Preparing transaction...");
  console.log("  Listing ID:", listingId);
  console.log("  Price:", price, "ugnot");
  console.log("  Marketplace Realm:", MARKETPLACE_REALM);

  if (!window.adena) {
    throw new Error("Adena wallet not found");
  }

  const walletAddress = await getWalletAddress();
  console.log("  Caller address:", walletAddress);

  const messages = [{
    type: "/vm.m_call",
    value: {
      caller: walletAddress,  // Required for /vm.m_call
      send: `${price}ugnot`,
      pkg_path: MARKETPLACE_REALM,
      func: "BuyNFT",
      args: [listingId.toString()],
    },
  }];

  console.log("\n📨 Transaction message:");
  console.log(JSON.stringify(messages, null, 2));

  // FIXED: According to official docs, messages go directly (NO tx wrapper!)
  const txParams = {
    messages,
    memo: "",  // Optional memo field
  };

  console.log("\n⚙️ Transaction params (no tx wrapper):");
  console.log(JSON.stringify(txParams, null, 2));

  try {
    console.log("\n🔐 Calling Adena.DoContract()...");
    const result = await window.adena.DoContract(txParams);

    console.log("\n✅ Transaction submitted!");
    console.log("  Result:", result);
    console.log("  Result type:", typeof result);
    console.log("  Result stringified:", JSON.stringify(result, null, 2));

    // Check if transaction was actually successful
    if (result && result.code !== undefined && result.code !== 0) {
      console.error("❌ Transaction failed with code:", result.code);
      console.error("  Log:", result.log);
      throw new Error(`Transaction failed: ${result.log || 'Unknown error'}`);
    }

    return result;
  } catch (error: any) {
    console.error("\n❌ Transaction error:");
    console.error("  Error:", error);
    console.error("  Error message:", error?.message);
    console.error("  Error log:", error?.log);
    console.error("  Error code:", error?.code);
    throw error;
  }
}

// Vote on proposal
export async function voteOnProposal(proposalId: number, choice: "yes" | "no") {
  if (!window.adena) {
    throw new Error("Adena wallet not found");
  }

  const walletAddress = await getWalletAddress();

  const messages = [{
    type: "/vm.m_call",
    value: {
      caller: walletAddress,  // Required for /vm.m_call
      send: "",
      pkg_path: MARKETPLACE_REALM,
      func: "Vote",
      args: [proposalId.toString(), choice],
    },
  }];

  try {
    const result = await window.adena.DoContract({
      messages,
      memo: "",
    });

    return result;
  } catch (error) {
    console.error("Vote failed:", error);
    throw error;
  }
}

// Execute (tally) a proposal after voting period
export async function tallyProposal(proposalId: number) {
  console.log("\n⚖️ [tallyProposal] Executing proposal...");
  console.log("  Proposal ID:", proposalId);

  if (!window.adena) {
    throw new Error("Adena wallet not found");
  }

  const walletAddress = await getWalletAddress();
  console.log("  Caller address:", walletAddress);

  const messages = [{
    type: "/vm.m_call",
    value: {
      caller: walletAddress,
      send: "",
      pkg_path: MARKETPLACE_REALM,
      func: "TallyProposal",
      args: [proposalId.toString()],
    },
  }];

  console.log("\n📨 Transaction message:");
  console.log(JSON.stringify(messages, null, 2));

  try {
    console.log("\n🔐 Calling Adena.DoContract()...");
    const result = await window.adena.DoContract({
      messages,
      memo: "",
    });

    console.log("\n✅ Tally successful!");
    console.log("  Result:", result);

    return result;
  } catch (error: any) {
    console.error("\n❌ Tally error:");
    console.error("  Error:", error);
    console.error("  Error message:", error?.message);
    throw error;
  }
}

// Helper to get wallet address
async function getWalletAddress(): Promise<string> {
  console.log("\n🔍 [getWalletAddress] Getting wallet address...");
  const account = await window.adena.GetAccount();
  console.log("  Raw account:", account);
  console.log("  account.address:", account?.address);
  console.log("  account.data:", account?.data);
  console.log("  account.data?.address:", account?.data?.address);

  // Try different possible locations for the address
  const address = account?.address || account?.data?.address || account?.data?.[0]?.address;
  console.log("  Final address:", address);

  return address;
}