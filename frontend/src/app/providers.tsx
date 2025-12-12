"use client";
import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { AppKitProvider, createAppKit } from "@reown/appkit/react";
import { WagmiAdapter } from "@reown/appkit-adapter-wagmi";
import { celo } from "@reown/appkit/networks";

const projectId = process.env.NEXT_PUBLIC_REOWN_PROJECT_ID as string;
const networks = [celo];

const wagmiAdapter = new WagmiAdapter({
  networks,
  projectId
});

  createAppKit({
    adapters: [wagmiAdapter],
    projectId,
    networks: networks as any,
    defaultNetwork: celo,
  metadata: {
    name: "Citadel Onchain",
    description: "Community-backed savings vault",
    url: "https://citadel.local",
    icons: ["https://avatars.githubusercontent.com/u/179229932"]
  },
  features: {
    analytics: true
  }
});

export default function Providers({ children }: { children: React.ReactNode }) {
  const queryClient = new QueryClient();
  return (
    <WagmiProvider config={wagmiAdapter.wagmiConfig as any}>
      <QueryClientProvider client={queryClient}>
        <AppKitProvider projectId={projectId} networks={networks as any}>
          {children}
        </AppKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
