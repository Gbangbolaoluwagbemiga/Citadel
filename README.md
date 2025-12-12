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
- `createVault(unlockAt, target, beneficiary, guardians[], threshold) → id`
- `setBeneficiary(id, beneficiary)`
- `deposit(id)` payable
- `approveEarly(id)` guardian approval
- `withdrawOwner(id, amount)` owner withdraw; unlocked or early enabled
- `withdrawToBeneficiary(id, amount)` owner withdraw to beneficiary; only after unlock
- `getVault(id) → (owner, beneficiary, unlockAt, target, balance, threshold, approvals, earlyEnabled)`

Events
- `VaultCreated(id, owner, unlockAt, target, threshold)`
- `Deposited(id, from, amount, newBalance)`
- `EarlyApproval(id, guardian, approvals, enabled)`
- `Withdrawn(id, to, amount, remaining)`
- `BeneficiarySet(id, beneficiary)`

**Security considerations**
- Uses a minimal reentrancy guard on withdrawal paths.
- Ether transfers use `call` and error on failure.
- Guardians cannot withdraw funds; they only signal early unlock.
- Owner controls beneficiary; beneficiary withdrawals require the vault to be unlocked.

**How it works**
- A user creates a vault with an unlock timestamp and guardian list/threshold.
- Anyone can contribute via `deposit(id)`.
- Guardians call `approveEarly(id)`; when approvals ≥ threshold, early withdrawals are enabled for the owner.
- After `unlockAt`, the owner can withdraw to self or to an optional beneficiary.

**Deploy on Celo (Alfajores testnet)**
- Fastest path: Remix
  - Open Remix → upload `contracts/CitadelVault.sol` → Select compiler `0.8.20`
  - In Deploy & Run, set Environment to Injected Provider and connect a wallet on Alfajores
  - Deploy `CitadelVault`
- Hardhat or Foundry can be set up later for local builds, tests, and scripts.

**Example flows**
- Create vault: owner calls `createVault(unlockAt, target, beneficiary, guardians, threshold)`
- Fund: users call `deposit(id)` with `msg.value`
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
