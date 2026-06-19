# X-Ray Report

> RWA Investment Contracts | ~1,967 production nSLOC | e647ccb (`main`) | Foundry + MC devkit | 18/06/26

---

## 1. Protocol Overview

**What it does:** A fractional RWA investment protocol where users subscribe with USDT or off-chain JPY credit, receive ERC721 investment NFTs, and later receive scheduled yield and principal repayment.

- **Users**: Investors buy product units, hold transferable NFTs, and claim escrowed yield/principal if push transfers fail.
- **Core flow**: Product registration -> USDT invest or JPY-backed mint -> scheduled yield distribution -> maturity principal repayment and NFT burn.
- **Key mechanism**: Per-product ERC721 NFTs store investment amount; product accounting tracks raised amount, product pool, distribution cursors, and maturity cursors.
- **Token model**: USDT-like ERC20 settlement token plus one InvestmentNFT ERC721 contract per product.
- **Admin model**: Safe multisig owns role management; whitelisted admins operate products; minters credit off-chain JPY subscriptions; Chainlink forwarder triggers automation.

For a visual overview of the protocol's architecture, see the [architecture diagram](architecture.svg).

### Contracts in Scope

| Subsystem | Key Contracts | nSLOC | Role |
|-----------|--------------|------:|------|
| Investment state/facade | `Schema`, `Storage`, `InvestmentFacade` | 133 | ERC-7201-style storage layout and MC facade surface |
| User value flows | `Invest`, `Claim` | 167 | USDT subscriptions and escrow recovery |
| Admin operations | `RegisterProduct`, `Deposit`, `Withdraw`, `DistributeYield`, `Maturity`, `SetTier` | 617 | Product lifecycle, pool funding, distribution, maturity, tier config |
| Role control | `Initialize`, `ControlAdmin`, `ControlMinter`, base role guards | 162 | Initial config and role arrays |
| Off-chain credit | `MintNFT` | 54 | Minter-operated NFT issuance after JPY settlement |
| Utilities | `CalculateYieldLib`, `DistributionDateLib`, `PurchasePermissionLib`, `UsdtTransferLib` | 320 | Yield math, date math, tier eligibility, USDT transfer wrapper |
| Periphery | `InvestmentNFT`, `Automation` | 203 | Product NFT and Chainlink upkeep router |

### Backwards-Compatibility Code

- `InvestmentFacade` empty functions - MC facade/interface surface; do not treat the empty bodies as executable product logic.
- Test/mock contracts embedded after `// Testing` inside several `src/` files - local test scaffolding, excluded from production scope.

### How It Fits Together

The core trick: product state lives in shared MC storage while each behavior is split into a small function contract.

### Product Setup

```text
Admin
└─ RegisterProduct.registerProduct
   ├─ validates cap, dates, distribution schedule, tier config
   ├─ CREATE2 deploys InvestmentNFT
   └─ writes Product + product indexes
```

### USDT Investment

```text
Investor
└─ Invest.invest
   ├─ PurchasePermissionLib.hasPurchasePermission
   ├─ product.raisedAmount/productPool += amount
   ├─ USDT.safeTransferFrom(investor, proxy)
   └─ InvestmentNFT.mint(investor, amount)
```

### Distribution

```text
Admin / Automation
└─ DistributeYield.distributeYield
   ├─ date and distribution-count checks
   ├─ InvestmentNFT.getNFTInfos(cursor)
   ├─ UsdtTransferLib.tryTransfer(owner, yield)
   └─ failed push records escrow by productId/tokenId/distributionIndex
```

### Maturity

```text
Admin / Automation
└─ Maturity.maturity
   ├─ maturity date + all distributions completed
   ├─ InvestmentNFT.getNFTInfos(cursor)
   ├─ pays principal plus escrowed yield if transfer succeeds
   ├─ escrow principal if transfer fails
   └─ burns NFT and removes active product after final batch
```

---

## 2. Threat & Trust Model

### Protocol Threat Profile

> Protocol classified as: **Yield / RWA distribution platform** with **NFT ownership and admin-operated settlement** characteristics

The code has no lending, AMM, oracle pricing, or leverage surface; the dominant risk is lifecycle accounting across product pools, transferable NFTs, scheduled payouts, and privileged operations.

### Actors & Adversary Model

| Actor | Trust Level | Capabilities |
|-------|-------------|-------------|
| Safe multisig | Trusted | Sets admins/minters through `addAdmin`, `deleteAdmin`, `addMinter`, `deleteMinter`; no timelock found in code. |
| Whitelisted admin | Trusted / operational | Registers products, funds/withdraws pools, distributes yield, matures products, configures tiers. |
| Minter | Bounded (role-limited) | Calls `mintNFT` for off-chain JPY subscriptions; can increase `raisedAmount` and mint NFTs without ERC20 transfer. |
| Chainlink forwarder | Bounded (automation-only) | Calls `Automation.performUpkeep`, which can call `distributeYield` or `maturity` if Automation is whitelisted. |
| Investor / NFT holder | Untrusted | Calls `invest`, transfers NFTs, claims escrowed yield/principal for currently owned NFTs. |
| USDT token | External dependency | Must transfer exact amounts or fail clearly; blacklist/failure behavior is handled by escrow in push-payment loops. |
| Tier SBT contracts | External dependency | ERC721/ERC1155 balances determine purchase eligibility for non-zero required tiers. |

**Adversary Ranking**

1. **Compromised admin/minter** - Can alter product lifecycle inputs, pool movement, eligibility, or off-chain-credit minting.
2. **NFT timing trader** - Can buy transferable NFTs before distribution or claim windows where business rules allow current-holder entitlement.
3. **Blocked or non-standard token recipient** - Can trigger escrow paths through failed USDT transfers.
4. **Keeper/automation disruption** - Can delay scheduled operations if the forwarder/admin setup is wrong or insufficient-balance flags remain active.
5. **Tier-gating bypass seeker** - Looks for gaps between initial eligibility and transferable NFT ownership.

See [entry-points.md](entry-points.md) for the full permissionless entry point map.

### Trust Boundaries

- **Safe-to-admin boundary** - Safe controls role arrays instantly via `ControlAdmin.sol:22-70` and `ControlMinter.sol:17-47`; no on-chain delay was found.

- **Admin-to-user funds boundary** - Whitelisted admins can move pool USDT to the Safe via `Withdraw.sol:33-53`, and can trigger payout loops via `DistributeYield.sol:44` and `Maturity.sol:30`.

- **Minter-to-accounting boundary** - `MintNFT.sol:32-68` increases `raisedAmount` and mints NFTs without increasing `productPool`; docs describe this as the off-chain JPY path.

- **Automation boundary** - `Automation.sol:92-110` is forwarder-gated but the downstream Investment calls still require the Automation contract to be whitelisted.

- **NFT transfer boundary** - Claim rights are tied to current `ownerOf(tokenId)` in `Claim.sol:36` and `Claim.sol:75`, matching the documented current-holder model.

### Key Attack Surfaces

- **Product lifecycle accounting** &nbsp;[[I-1](invariants.md#i-1), [I-7](invariants.md#i-7), [I-8](invariants.md#i-8)] - `Invest.sol:79-86`, `DistributeYield.sol:159`, and `Maturity.sol:125-126` are the main places where raised principal, product pool, and payout progress must stay aligned.

- **Off-chain JPY mint path** &nbsp;[[I-2](invariants.md#i-2)] - `MintNFT.sol:60-65` mints investment NFTs and increases `raisedAmount` without a token transfer, so audit the operational assumption against `Deposit.sol:52-59`.

- **Escrowed push-payment recovery** &nbsp;[[I-10](invariants.md#i-10), [X-3](invariants.md#x-3)] - `DistributeYield.sol:125-135`, `Maturity.sol:90-107`, and `Claim.sol:45-101` coordinate failed transfers, current ownership, and state clearing.

- **Batch cursor correctness** &nbsp;[[X-2](invariants.md#x-2)] - `distributedTokenId` and `maturedTokenId` advance from `InvestmentNFT.getNFTInfos()` batches; check edge cases around burns, transfers, and token ID gaps.

- **Tier and transfer model** &nbsp;[[I-3](invariants.md#i-3), [E-2](invariants.md#e-2)] - `Invest.sol:58` gates purchase, while NFTs remain transferable and `SetTier.sol:94-109` can update required tiers.

- **Automation skip and recovery state** &nbsp;[[X-4](invariants.md#x-4), [I-9](invariants.md#i-9)] - `Automation.sol:48-78` skips insufficient-balance products and relies on admin deposits clearing `isInsufficientBalance`.

### Upgrade Architecture Concerns

- **MC/proxy implementation split** - `Initialize.sol:16-18` disables direct implementation initialization, but storage-layout compatibility across split function contracts remains a core review item.

- **Shared ERC-7201 slots** - `Storage.sol:10-32` hardcodes storage locations; any future slot change would affect all facets.

### Protocol-Type Concerns

**As an RWA distribution platform:**

- `CalculateYieldLib.sol:40-47` and `calculateIndividualPeriodYield` use scaled rounding; confirm aggregate rounding tolerance across 50-token batches.
- `DistributionDateLib.sol:20-35` normalizes and month-end adjusts schedules; confirm expected dates under leap years and month-end products.
- `InvestmentNFT.sol:137-154` reads sequential token IDs and calls `ownerOf`; burned token gaps are worth checking against all settlement cursor paths.

### Temporal Risk Profile

**Deployment & Initialization:**
- `Initialize.sol:20-49` is one-time and validates zero/duplicate admins, but the initial Safe/admin/minter choices are fully trusted.

**Scheduled Operations:**
- `DistributeYield.sol:63` and `Maturity.sol:42-46` enforce timing, while `Automation.sol:40-78` only suggests the next operation; direct admin execution remains possible.

### Composability & Dependency Risks

**Dependency Risk Map:**

> **USDT / ERC20 settlement token** - via `Invest`, `Deposit`, `Withdraw`, `DistributeYield`, `Maturity`, `Claim`
> - Assumes: transfer amount semantics and token balance reflect settlement value.
> - Validates: SafeERC20 for pull/admin transfers; low-level `tryTransfer` for push loops.
> - Mutability: external token contract, not controlled by this repo.
> - On failure: distribution/maturity push failure escrows by tokenId; direct claim failure reverts.

> **InvestmentNFT** - via Investment product flows
> - Assumes: token ID cursor and investment amount map remain consistent.
> - Validates: onlyOwner on mint/burn where owner is the deploying Investment contract.
> - Mutability: protocol-owned per product.
> - On failure: downstream distribution/maturity call reverts if NFT reads fail.

> **Tier SBTs** - via `PurchasePermissionLib`
> - Assumes: ERC165 and ERC721/ERC1155 balance checks are accurate eligibility signals.
> - Validates: admin setters require non-zero contract addresses and ERC1155 support for ID-based rules.
> - Mutability: external SBT contracts can have their own issuer/admin policies.
> - On failure: unsupported or zero-code SBT entries do not grant permission.

> **Chainlink Automation forwarder** - via `Automation.performUpkeep`
> - Assumes: configured forwarder is correct for the upkeep.
> - Validates: `msg.sender == forwarderAddress`.
> - Mutability: external service/configuration.
> - On failure: automation stalls; whitelisted admins can still call Investment settlement functions directly.

**Token Assumptions**:
- USDT-like token: assumes product pool accounting and actual token balances stay aligned after successful SafeERC20 or `tryTransfer` calls.

---

## 3. Invariants

> ### Full invariant map: **[invariants.md](invariants.md)**
>
> A dedicated reference file contains the complete invariant analysis - do not look here for the catalog.
>
> - **24 Enforced Guards** (`G-1` ... `G-24`) - per-call preconditions with `Check` / `Location` / `Purpose`
> - **10 Single-Contract Invariants** (`I-1` ... `I-10`) - Conservation, Bound, StateMachine, Temporal
> - **4 Cross-Contract Invariants** (`X-1` ... `X-4`) - caller/callee pairs that cross scope boundaries
> - **2 Economic Invariants** (`E-1` ... `E-2`) - higher-order properties deriving from `I-N` + `X-N`

---

## 4. Documentation Quality

| Aspect | Status | Notes |
|--------|--------|-------|
| README | Present | `README.md` describes setup, submodules, toolchain, env vars, deployment, and CI. |
| NatSpec | Adequate | Most production functions include purpose and error notes; several utilities document math assumptions. |
| Spec/Whitepaper | Present | Requirements/design/security docs exist under `docs/`; architecture PDF was detected but not parsed in this run. |
| Inline Comments | Adequate | Important lifecycle branches and mitigations are commented; embedded tests in `src/` add noise for static scans. |

---

## 5. Test Analysis

| Metric | Value | Source |
|--------|-------|--------|
| Test files | 24 | File scan (always reliable) |
| Test functions | 51 | File scan (always reliable) |
| Line coverage | Unavailable - missing submodule/import paths under `lib/mc`, OpenZeppelin, forge-std, and Chainlink | Coverage tool |
| Branch coverage | Unavailable - coverage did not compile | Coverage tool |

### Test Depth

| Category | Count | Contracts Covered |
|----------|-------|-------------------|
| Unit | 51 | Broad function-contract and periphery tests, including fix regressions |
| Integration | Present | Scenario tests under `test/investment/Investment.scenario*.t.sol` |
| Fork | 0 | none detected |
| Stateless Fuzz | 0 by external test-file scan; embedded `src/` tests include fuzz-style functions | File scan |
| Stateful Fuzz (Foundry) | 0 | none detected |
| Formal Verification | 0 | Certora/Halmos/HEVM not detected |

### Gaps

- Stateful invariant fuzzing is absent for product pool, distribution cursor, escrow, and maturity accounting.
- Formal specs are absent for yield rounding, transferable NFT entitlement, and active-product indexing.
- Coverage could not be measured until submodules are initialized.

---

## 6. Developer & Git History

> Repo shape: squashed_import - the current branch has one visible commit (`e647ccb Initial public release`), so meaningful evolution/hotspot analysis is not available.

- **Analyzed branch**: `main` at `e647ccb`.
- **Review signals**: `docs/audit/fix/` contains many remediation notes and matching regression tests under `test/fix/`.
- **Hotspots**: No git churn signal is available because history is squashed/imported.
- **Security-relevant docs**: Security docs explicitly discuss mitigations for USDT push failures, admin-loop DoS, zero-investor automation loops, deposit recovery, schedule exceeding maturity, tier registry configuration, duplicate initialization admins, and implementation initialization.

---

## X-Ray Verdict

**Tier: Yellow - audit-ready after dependency setup refresh.**

The protocol has a clear product lifecycle model, documented access control, explicit regression notes, and tests are present. The main blocker for deeper automated confidence is environmental: submodules/imports are missing locally, so compile, tests, and coverage could not be executed. The highest-value audit areas are lifecycle accounting, off-chain JPY mint/deposit reconciliation, escrow recovery, batch cursor correctness, and the current-holder NFT entitlement model.
