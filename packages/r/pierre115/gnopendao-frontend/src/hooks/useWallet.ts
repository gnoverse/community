"use client";

import { useState, useEffect } from "react";
import { WalletState } from "@/lib/types";

declare global {
  interface Window {
    adena?: any;
  }
}

export function useWallet() {
  const [wallet, setWallet] = useState<WalletState>({
    address: null,
    isConnected: false,
    isDAOMember: false,
  });

  useEffect(() => {
    checkAdenaConnection();
  }, []);

  const checkAdenaConnection = async () => {
    if (typeof window === "undefined" || !window.adena) return;

    try {
      const account = await window.adena.GetAccount();
      setWallet({
        address: account.address,
        isConnected: true,
        isDAOMember: false, // TODO: check via realm
      });
    } catch (error) {
      console.log("Adena not connected");
    }
  };

  const connect = async () => {
    if (!window.adena) {
      alert("Please install Adena wallet extension");
      window.open("https://adena.app", "_blank");
      return;
    }

    try {
      await window.adena.AddEstablish("GnopenSea");
      const account = await window.adena.GetAccount();

      setWallet({
        address: account.address,
        isConnected: true,
        isDAOMember: false,
      });
    } catch (error) {
      console.error("Failed to connect:", error);
    }
  };

  const disconnect = () => {
    setWallet({
      address: null,
      isConnected: false,
      isDAOMember: false,
    });
  };

  return { wallet, connect, disconnect };
}