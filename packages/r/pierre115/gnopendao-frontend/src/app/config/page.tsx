'use client';

import { provider, MARKETPLACE_REALM, CHAIN_ID } from "@/lib/gno";

export default function ConfigPage() {
  // Display actual configuration
  const config = {
    rpcEndpoint: process.env.NEXT_PUBLIC_RPC_ENDPOINT || "NOT DEFINED (using fallback)",
    chainId: process.env.NEXT_PUBLIC_CHAIN_ID || "NOT DEFINED (using fallback)",
    marketplace: process.env.NEXT_PUBLIC_MARKETPLACE_REALM || "NOT DEFINED (using fallback)",
    registry: process.env.NEXT_PUBLIC_REGISTRY_REALM || "NOT DEFINED (using fallback)",
  };

  return (
    <div className="container mx-auto px-4 py-20">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold mb-8 text-white">🔧 Frontend Configuration</h1>

        <div className="bg-secondary p-8 rounded-lg border border-border">
          <h2 className="text-2xl font-semibold mb-4 text-purple-400">Environment Variables</h2>

          <div className="space-y-4 font-mono text-sm">
            <div>
              <div className="text-gray-400">NEXT_PUBLIC_RPC_ENDPOINT:</div>
              <div className="text-green-400 break-all">{config.rpcEndpoint}</div>
            </div>

            <div>
              <div className="text-gray-400">NEXT_PUBLIC_CHAIN_ID:</div>
              <div className="text-green-400">{config.chainId}</div>
            </div>

            <div>
              <div className="text-gray-400">NEXT_PUBLIC_MARKETPLACE_REALM:</div>
              <div className="text-green-400">{config.marketplace}</div>
            </div>

            <div>
              <div className="text-gray-400">NEXT_PUBLIC_REGISTRY_REALM:</div>
              <div className="text-green-400">{config.registry}</div>
            </div>
          </div>

          <div className="mt-8 p-4 bg-yellow-900/20 border border-yellow-500 rounded">
            <p className="text-yellow-300 font-semibold">⚠️ Note:</p>
            <p className="text-sm text-gray-300 mt-2">
              These values are compiled at build time. If you modify `.env.local`,
              you MUST restart the Next.js server (Ctrl+C then `npm run dev`).
            </p>
          </div>

          <div className="mt-8">
            <h3 className="text-xl font-semibold mb-4 text-cyan-400">Connection Test</h3>
            <button
              onClick={async () => {
                try {
                  const response = await provider.evaluateExpression(MARKETPLACE_REALM, "GetMarketplaceFee()");
                  alert(`✅ Connection successful!\nMarketplace Fee: ${response}`);
                } catch (error: any) {
                  alert(`❌ Connection error:\n${error.message}`);
                }
              }}
              className="px-6 py-3 bg-purple-500 hover:bg-purple-600 rounded-lg font-semibold"
            >
              Test marketplace connection
            </button>
          </div>
        </div>

        <div className="mt-8 p-6 bg-blue-900/20 border border-blue-500 rounded">
          <h3 className="text-xl font-semibold mb-2 text-blue-300">💡 Connection problem?</h3>
          <ul className="text-sm text-gray-300 space-y-2 list-disc list-inside">
            <li>Check that the `.env.local` file exists in `gnopensea-frontend/`</li>
            <li>Restart the Next.js server after modifying `.env.local`</li>
            <li>If "NOT DEFINED", the file is not loaded correctly</li>
            <li>Variables MUST start with `NEXT_PUBLIC_` to be accessible client-side</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
