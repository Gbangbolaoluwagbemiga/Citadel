# Citadel Onchain

Citadel Onchain is a simple, unique savings vault built on Celo that helps people reach financial goals and resist impulse spending through social trust. Users lock funds until a chosen date, set an optional beneficiary, and appoint guardians (friends, family, community leaders) who can collectively authorize early withdrawals via an on‑chain threshold.

**Real‑world problem**
- People struggle to keep savings intact for planned needs (rent, tuition, equipment) and often withdraw early.
- Citadel adds social accountability: early withdrawal requires a pre‑defined number of guardian approvals.
- Fits Celo’s mobile‑first mission by enabling community‑backed savings for everyday goals.

**Core features**
- Create time‑locked vaults with `unlockAt`, `target` and optional `beneficiary`.
- Appoint guardians and a threshold for early withdrawal approvals.
- Accept deposits from anyone to support the goal.
- Withdraw to owner after unlock or early approvals; optionally withdraw to beneficiary after unlock.
- Transparent events for vault lifecycle and guardian approvals.

**Contract**
- File: `contracts/CitadelVault.sol`
- Compiler: Solidity `^0.8.20`

Public interface
- `createVault(unlockAt, target, beneficiary, guardians[], threshold, token) → id`
- `setBeneficiary(id, beneficiary)`
- `deposit(id)` payable
- `depositToken(id, amount)` for ERC20 vaults
- `approveEarly(id)` guardian approval
- `withdrawOwner(id, amount)` owner withdraw; unlocked or early enabled
- `withdrawToBeneficiary(id, amount)` owner withdraw to beneficiary; only after unlock
- `addGuardians(id, guardians[])`
- `removeGuardians(id, guardians[])`
- `setThreshold(id, threshold)`
- `getGuardians(id) → address[]`
- `getVault(id) → (owner, beneficiary, unlockAt, target, balance, threshold, approvals, earlyEnabled, token)`

Events
- `VaultCreated(id, owner, unlockAt, target, threshold)`
- `Deposited(id, from, amount, newBalance)`
- `EarlyApproval(id, guardian, approvals, enabled)`
- `Withdrawn(id, to, amount, remaining)`
- `BeneficiarySet(id, beneficiary)`

**Security considerations**
- Reentrancy guard on withdrawals.
- Native CELO uses `call`; ERC20 uses `transfer`.
- Guardians cannot move funds.
- Guardian changes reset approvals and disable early unlock until re-approved.

**How it works**
- A user creates a vault with an unlock timestamp and guardian list/threshold.
- Anyone can contribute via `deposit(id)`.
- Guardians call `approveEarly(id)`; when approvals ≥ threshold, early withdrawals are enabled for the owner.
- After `unlockAt`, the owner can withdraw to self or to an optional beneficiary.

**Deploy**
- Local (Hardhat)
  - `npm install`
  - `npm run compile`
  - `npm run deploy:local` → prints deployed address
- Celo Alfajores
  - Copy `.env.example` to `.env`
  - Set `ALFAJORES_RPC_URL`, `PRIVATE_KEY`
  - `npm run deploy:alfajores`

**Example flows**
- Create vault: owner calls `createVault(unlockAt, target, beneficiary, guardians, threshold, token)`
  - `token = 0x0` for native CELO; set ERC20 address for cUSD or other
- Fund native: users call `deposit(id)` with `msg.value`
- Fund ERC20: users call `depositToken(id, amount)` after `approve`
- Early unlock: guardians call `approveEarly(id)` until threshold met; owner calls `withdrawOwner(id, amount)`
- Normal unlock: after time passes, owner calls `withdrawOwner(id, amount)` or `withdrawToBeneficiary(id, amount)`

**Why this is unique and simple**
- Simple primitives: time lock, deposits, threshold approvals.
- Real‑world impact: social accountability improves savings discipline and supports community goals.
- Extensible: future modules can add yield strategies, milestone‑based releases, or Celo Attestations.

**Roadmap**
- Add guardian rotation and revocation.
- Add milestone schedules and partial releases.
- Integrate Celo Attestation Service for guardian identity.
- Provide Hardhat/Foundry scaffolding and tests.
