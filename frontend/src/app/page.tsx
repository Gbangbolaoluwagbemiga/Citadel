"use client";
import { useState } from "react";
import { useAccount } from "wagmi";
import { readContract, writeContract } from "wagmi/actions";
import abiJson from "@/abi/CitadelVault.json";
import { AppKitButton } from "@reown/appkit/react";

const CITADEL_ADDRESS = process.env.NEXT_PUBLIC_CITADEL_ADDRESS as `0x${string}`;

export default function Home() {
  const { address, isConnected } = useAccount();
  const [vaultId, setVaultId] = useState<string>("");
  const [vault, setVault] = useState<any>(null);
  const [status, setStatus] = useState<{paused:boolean;admin:`0x${string}`}|null>(null);

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

  async function loadStatus() {
    const paused = await readContract({ address: CITADEL_ADDRESS, abi: (abiJson as any).abi, functionName: "paused", args: [] });
    const admin = await readContract({ address: CITADEL_ADDRESS, abi: (abiJson as any).abi, functionName: "admin", args: [] }) as `0x${string}`;
    setStatus({ paused: paused as boolean, admin });
  }

  async function callPause(action: "pause"|"unpause") {
    await writeContract({ address: CITADEL_ADDRESS, abi: (abiJson as any).abi, functionName: action, args: [] });
    await loadStatus();
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
      <div style={{ marginTop: 12 }}>
        <button onClick={loadStatus}>Load Status</button>
        {status && (
          <div style={{ marginTop: 8 }}>
            <div>Paused: {String(status.paused)}</div>
            <div>Admin: {status.admin}</div>
            {isConnected && address?.toLowerCase() === status.admin.toLowerCase() && (
              <div style={{ marginTop: 8 }}>
                <button onClick={() => callPause("pause")}>Pause</button>
                <button onClick={() => callPause("unpause")} style={{ marginLeft: 8 }}>Unpause</button>
              </div>
            )}
          </div>
        )}
      </div>
      {vault && (
        <pre style={{ marginTop: 16 }}>{JSON.stringify(vault, null, 2)}</pre>
      )}
    </div>
  );
}
