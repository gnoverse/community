"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState, useEffect } from "react";
import { Header } from "@/components/Header";
import { NFTCard } from "@/components/nft/NFTCard";
import { getActiveListings, getMarketplaceStats, buyNFT } from "@/lib/realm-calls";
import { ShoppingBag, TrendingUp, Coins, Sparkles } from "lucide-react";

export default function Home() {
  const [isMounted, setIsMounted] = useState(false);
  const [buyingListingId, setBuyingListingId] = useState<number | null>(null);
  const queryClient = useQueryClient();

  useEffect(() => {
    setIsMounted(true);
  }, []);

  const { data: listings = [], isLoading } = useQuery({
    queryKey: ["listings"],
    queryFn: getActiveListings,
    retry: false,
    refetchOnWindowFocus: false,
  });

  const { data: stats } = useQuery({
    queryKey: ["stats"],
    queryFn: getMarketplaceStats,
    retry: false,
    refetchOnWindowFocus: false,
  });

  // Handle NFT purchase
  const handleBuyNFT = async (listingId: number, price: number) => {
    console.log("🛒 [handleBuyNFT] Starting purchase...");
    console.log("  Listing ID:", listingId);
    console.log("  Price:", price, "ugnot");

    // Check if wallet is connected
    if (!window.adena) {
      console.error("❌ Adena wallet not found");
      alert("Please install Adena wallet extension");
      return;
    }

    try {
      // Check if wallet is connected
      const account = await window.adena.GetAccount();
      console.log("🔍 DEBUG account object:", account);
      console.log("  account type:", typeof account);
      console.log("  account keys:", Object.keys(account || {}));
      console.log("  account.address:", account?.address);
      console.log("  account.data:", account?.data);
      console.log("  Full account:", JSON.stringify(account, null, 2));

      if (!account) {
        alert("Please connect your Adena wallet first");
        return;
      }
    } catch (error) {
      console.error("❌ Wallet not connected:", error);
      alert("Please connect your Adena wallet first");
      return;
    }

    setBuyingListingId(listingId);

    try {
      console.log("🚀 Calling buyNFT()...");
      const result = await buyNFT(listingId, price);
      console.log("📦 Transaction result:", result);

      // Success - refresh data
      console.log("✅ Purchase successful, refreshing data...");
      alert("NFT purchased successfully!");
      queryClient.invalidateQueries({ queryKey: ["listings"] });
      queryClient.invalidateQueries({ queryKey: ["stats"] });
    } catch (error: any) {
      console.error("❌ Purchase failed:", error);
      console.error("  Error type:", typeof error);
      console.error("  Error message:", error?.message);
      console.error("  Error stack:", error?.stack);
      console.error("  Full error object:", JSON.stringify(error, null, 2));

      // Show user-friendly error message
      if (error?.message) {
        alert(`Purchase failed: ${error.message}`);
      } else {
        alert("Purchase failed. Please try again.");
      }
    } finally {
      console.log("🏁 Purchase flow completed");
      setBuyingListingId(null);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 overflow-hidden relative">
      <Header />

      {/* Animated Grid Background */}
      <div className="fixed inset-0 pointer-events-none z-0">
        <div className="absolute inset-0 bg-grid-pattern"></div>
        <div className="absolute inset-0 bg-gradient-radial from-purple-900/30 via-transparent to-transparent"></div>
      </div>

      {/* Floating orbs */}
      <div className="fixed inset-0 pointer-events-none z-0">
        <div className="orb orb-1"></div>
        <div className="orb orb-2"></div>
        <div className="orb orb-3"></div>
      </div>

      {/* Particles */}
      {isMounted && (
        <div className="particles z-0">
          {[...Array(30)].map((_, i) => (
            <div
              key={i}
              className="particle"
              style={{
                left: `${Math.random() * 100}%`,
                animationDelay: `${Math.random() * 10}s`,
                animationDuration: `${8 + Math.random() * 4}s`,
              }}
            />
          ))}
        </div>
      )}

      <main className="relative z-10">
        {/* Hero compact et centré */}
        <div className="container mx-auto px-4 pt-20 pb-12">
          <div className="max-w-3xl mx-auto text-center space-y-8">
            {/* Title avec effet holographique AMÉLIORÉ */}
            <div className="relative py-8">
              <h1 className="text-7xl font-black tracking-tighter relative z-10 flex items-center justify-center gap-4">
                <span className="holographic-text inline-block">
                  GnopenSea
                </span>
                <span className="text-2xl font-light text-slate-400 italic">by Magnus</span>
              </h1>
              {/* Glow effect derrière le texte */}
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-32 bg-gradient-to-r from-purple-500/30 via-pink-500/30 to-cyan-500/30 blur-3xl animate-pulse-slow"></div>
              {/* Reflet holographique */}
              <div className="absolute -bottom-2 left-1/2 -translate-x-1/2 w-3/4 h-1 bg-gradient-to-r from-transparent via-purple-500/50 to-transparent blur-sm"></div>
            </div>

            <p className="text-lg text-slate-400 font-light max-w-xl mx-auto">
              Decentralized NFT marketplace powered by DAO governance
            </p>

            {/* Stats compacts au centre */}
            <div className="flex items-center justify-center gap-8 py-6">
              <StatBadge icon={ShoppingBag} value={stats?.activeListings || 0} label="Listed" />
              <div className="w-px h-12 bg-gradient-to-b from-transparent via-purple-500 to-transparent"></div>
              <StatBadge icon={TrendingUp} value={stats?.totalSales || 0} label="Sold" />
              <div className="w-px h-12 bg-gradient-to-b from-transparent via-cyan-500 to-transparent"></div>
              <StatBadge icon={Coins} value={`${((stats?.totalVolume || 0) / 1000000).toFixed(1)}Ꞡ`} label="Volume" />
            </div>
          </div>
        </div>

        {/* NFT Grid */}
        <div className="container mx-auto px-4 pb-20">
          <div className="max-w-6xl mx-auto">
            {/* Header section */}
            <div className="flex items-center justify-between mb-8">
              <div className="flex items-center gap-3">
                <div className="w-1 h-8 bg-gradient-to-b from-purple-500 to-cyan-500 rounded-full"></div>
                <h2 className="text-2xl font-bold text-white">Live Marketplace</h2>
              </div>
              <div className="flex items-center gap-2 text-sm text-slate-400">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                <span>Active</span>
              </div>
            </div>

            {isLoading ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {[...Array(6)].map((_, i) => (
                  <div key={i} className="aspect-square glass rounded-2xl animate-pulse-slow" 
                       style={{ animationDelay: `${i * 100}ms` }} />
                ))}
              </div>
            ) : listings.length === 0 ? (
              <div className="relative group">
                <div className="absolute inset-0 bg-gradient-to-r from-purple-500/20 via-pink-500/20 to-cyan-500/20 rounded-3xl blur-xl group-hover:blur-2xl transition-all"></div>
                <div className="relative glass rounded-3xl border border-white/5 p-20 text-center">
                  <div className="w-24 h-24 mx-auto mb-6 rounded-2xl bg-gradient-to-br from-purple-500/10 to-cyan-500/10 flex items-center justify-center backdrop-blur-xl">
                    <Sparkles className="h-12 w-12 text-purple-400 animate-pulse" />
                  </div>
                  <h3 className="text-2xl font-bold text-white mb-3">Awaiting First Drop</h3>
                  <p className="text-slate-400 max-w-md mx-auto">
                    Connect your wallet to explore the decentralized marketplace
                  </p>
                </div>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {listings.map((listing, i) => (
                  <div key={listing.listingId}
                       className="animate-fade-in-up"
                       style={{ animationDelay: `${i * 100}ms` }}>
                    <NFTCard
                      listing={listing}
                      onBuy={() => handleBuyNFT(listing.listingId, listing.price)}
                      isLoading={buyingListingId === listing.listingId}
                    />
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}

// Composant stat badge compact
function StatBadge({ icon: Icon, value, label }: { icon: any; value: string | number; label: string }) {
  return (
    <div className="flex flex-col items-center gap-2 group cursor-default">
      <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-purple-500/10 to-cyan-500/10 border border-white/5 flex items-center justify-center group-hover:scale-110 transition-transform">
        <Icon className="h-5 w-5 text-purple-400" />
      </div>
      <div className="text-center">
        <div className="text-2xl font-bold text-white">{value}</div>
        <div className="text-xs text-slate-500 uppercase tracking-wider">{label}</div>
      </div>
    </div>
  );
}