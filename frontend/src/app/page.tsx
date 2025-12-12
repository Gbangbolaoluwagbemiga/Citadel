"use client";
import { useState } from "react";
import { useAccount, useConnect } from "wagmi";
import { readContract } from "wagmi/actions";
import abiJson from "@/abi/CitadelVault.json";
import { AppKitButton } from "@reown/appkit/react";

const CITADEL_ADDRESS = process.env.NEXT_PUBLIC_CITADEL_ADDRESS as `0x${string}`;

export default function Home() {
  const { address, isConnected } = useAccount();
  const { connectors, connectAsync } = useConnect();
  const [vaultId, setVaultId] = useState<string>("");
  const [vault, setVault] = useState<any>(null);

  async function connect() {
    const wc = connectors[0];
    await connectAsync({ connector: wc });
  }

  async function loadVault() {
    if (!vaultId) return;
    const res = await readContract({
      address: CITADEL_ADDRESS,
      abi: (abiJson as any).abi,
      functionName: "getVault",
      args: [BigInt(vaultId)]
    });
    setVault(res);
  }

  return (
    <div style={{ padding: 24 }}>
      <h1>Citadel Onchain</h1>
      <div style={{ marginBottom: 12 }}>
        <AppKitButton />
      </div>
      {isConnected && <div>Connected: {address}</div>}
      <div style={{ marginTop: 16 }}>
        <input placeholder="Vault ID" value={vaultId} onChange={(e) => setVaultId(e.target.value)} />
        <button onClick={loadVault}>Load</button>
      </div>
      {vault && (
        <pre style={{ marginTop: 16 }}>{JSON.stringify(vault, null, 2)}</pre>
      )}
    </div>
  );
}
