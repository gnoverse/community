"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Button } from "@/components/ui/button";
import { useWallet } from "@/hooks/useWallet";
import { Wallet, LogOut } from "lucide-react";

export function Header() {
  const { wallet, connect, disconnect } = useWallet();
  const pathname = usePathname();

  return (
    <header className="fixed top-0 z-50 w-full">
      <div className="absolute inset-0 bg-slate-950/50 backdrop-blur-xl border-b border-white/5"></div>
      <div className="container relative flex h-16 items-center justify-between px-4">
        <Link href="/" className="flex items-center gap-3 group">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-purple-500 to-cyan-500 flex items-center justify-center group-hover:rotate-12 transition-transform">
            <span className="text-white font-black text-sm">G</span>
          </div>
          <span className="text-lg font-bold text-white hidden sm:block">GnopenSea</span>
        </Link>

        <nav className="absolute left-1/2 -translate-x-1/2 hidden md:flex items-center gap-1 glass rounded-full px-2 py-1">
          <Link
            href="/"
            className={`px-4 py-2 text-sm font-medium rounded-full transition-all ${
              pathname === "/"
                ? "bg-white/10 text-white"
                : "text-slate-400 hover:text-white hover:bg-white/5"
            }`}
          >
            Market
          </Link>
          <Link
            href="/dao"
            className={`px-4 py-2 text-sm font-medium rounded-full transition-all ${
              pathname === "/dao"
                ? "bg-white/10 text-white"
                : "text-slate-400 hover:text-white hover:bg-white/5"
            }`}
          >
            DAO
          </Link>
        </nav>

        {wallet.isConnected ? (
          <div className="flex items-center gap-2">
            <div className="flex items-center gap-2 px-3 py-1.5 rounded-full glass border border-white/10">
              <div className="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse" />
              <span className="text-xs font-mono text-white hidden sm:block">
                {wallet.address?.slice(0, 4)}...{wallet.address?.slice(-4)}
              </span>
            </div>
            <Button 
              variant="ghost" 
              size="icon"
              onClick={disconnect}
              className="hover:bg-red-500/10 hover:text-red-400 rounded-full w-8 h-8"
            >
              <LogOut className="h-3.5 w-3.5" />
            </Button>
          </div>
        ) : (
          <Button 
            onClick={connect}
            className="bg-gradient-to-r from-purple-500 to-cyan-500 hover:from-purple-600 hover:to-cyan-600 text-white font-semibold rounded-full px-5 h-9 text-sm"
          >
            <Wallet className="mr-2 h-3.5 w-3.5" />
            Connect
          </Button>
        )}
      </div>
    </header>
  );
}