"use client";
import { createConfig, WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { celo } from "viem/chains";
import { http } from "viem";
import { AppKitProvider } from "@reown/appkit/react";
import { createAppKit } from "@reown/appkit";
import { AppKitWagmiConnector } from "@reown/appkit-wagmi/react";

const projectId = process.env.NEXT_PUBLIC_REOWN_PROJECT_ID as string;
const citadelChain = {
  ...celo,
  rpcUrls: {
    default: { http: ["https://forno.celo.org"] },
    public: { http: ["https://forno.celo.org"] }
  }
};

const config = createConfig({
  chains: [citadelChain],
  transports: { [citadelChain.id]: http(citadelChain.rpcUrls.default.http[0]) }
});

createAppKit({ projectId, metadata: { name: "Citadel Onchain", url: "https://citadel.local", description: "Community-backed savings vault" } });

export default function Providers({ children }: { children: React.ReactNode }) {
  const queryClient = new QueryClient();
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <AppKitProvider projectId={projectId}>
          <AppKitWagmiConnector>
            {children}
          </AppKitWagmiConnector>
        </AppKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
