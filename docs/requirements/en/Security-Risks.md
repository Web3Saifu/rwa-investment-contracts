# Security Risks and Anticipated Contract Attacks

Given subscriptions from investors, NFT-based interest management, and ERC20 distributions, the following areas require particular attention.

---

## 1. General Smart Contract Attack Risks

### 1.1 Reentrancy

**Assessment note**: Acceptable with native/USDT-style tokens under operational assumptions.

| Item | Content |
|------|---------|
| **Where?** | When sending tokens to users for distributions or principal repayment, if `transfer` or `call` invokes external contracts. |
| **Why dangerous?** | ERC20 `transfer` is usually safer than raw `call`, but any direct external call can create reentrancy if the callee re-enters and abuses state. |
| **Mitigation** | Follow **check-effects-interactions** on Solidity 0.8+; update state before external calls. Consider OpenZeppelin **ReentrancyGuard**. |

---

### 1.2 Integer Overflow / Underflow

| Item | Content |
|------|---------|
| **Where?** | When computing share ratios or distribution amounts from user subscriptions; `uint256` multiply/add may grow unexpectedly. |
| **Why dangerous?** | Solidity 0.8+ reverts on overflow/underflow by default, but custom libraries or low-level ops need care. |
| **Mitigation** | Prefer standard `uint256` arithmetic and 0.8 safety. Define upper bounds (max investment, max distribution) at design time. |

---

### 1.3 Front-Running

**Assessment note**: Timing is somewhat fixed; acceptable.

| Item | Content |
|------|---------|
| **Where?** | Around specific products or distribution times; attackers may prioritize transactions with higher gas. |
| **Why dangerous?** | Examples: acquiring rare NFTs, or buying NFTs just before distribution if eligibility is “holder at execution.” |
| **Mitigation** | Consider snapshotting holders at a block, or blocking transfers after eligibility is fixed. Time locks increase difficulty (not perfect). |

---

### 1.4 Denial of Service

**Assessment note**: Gas considered; acceptable.

| Item | Content |
|------|---------|
| **Where?** | Large one-shot NFT issuance or distributions may hit block gas limits. |
| **Why dangerous?** | Loops over all users in one transaction can exceed gas limits. |
| **Mitigation** | Batch distributions, compute recipients off-chain, split across transactions. With Chainlink Automation, avoid huge single-array processing. |

---

### 1.5 Access Control Gaps

**Assessment note**: Designed; acceptable.

| Item | Content |
|------|---------|
| **Where?** | Admin-only functions missing `onlyOwner` / `onlyRole`. |
| **Why dangerous?** | Third parties could register products or trigger maturity, undermining business logic. |
| **Mitigation** | Use `Ownable` / `AccessControl` correctly; use multisig (Safe) for admin addresses. |

---

### 1.6 Unchecked External Call Return Values

**Assessment note**: USDT-only may be OK; consider fixing before broader token support.

| Item | Content |
|------|---------|
| **Where?** | ERC20 `transfer` often returns bool; ignoring failures hides unsuccessful transfers. |
| **Why dangerous?** | Logic may proceed as if tokens moved when they did not. |
| **Mitigation** | Always check return values, e.g. `require(token.transfer(...))` or SafeERC20. |

### 1.4 USDT blacklist / push failure halting distribution (F-2026-16871 — mitigated)

| Item | Detail |
|------|--------|
| **Where** | `distributeYield` / `maturity` USDT `transfer` loops (Tether blacklist, etc.). |
| **Risk** | Previously one failure reverted the whole batch, blocking all investors. |
| **Mitigation** | `UsdtTransferLib.tryTransfer` (low-level `call`, empty return = success). Failed amounts go to **`tokenId` escrow**; batch cursors advance. Investors use **`claimYield` / `claimPrincipal`** as `ownerOf`. Funds stay in contract if claim still fails (e.g., still blacklisted); other investors/products continue. |

### 1.4b Admin array uint8 loop counter DoS (F-2026-16866 — mitigated)

| Item | Detail |
|------|--------|
| **Where** | `_isWhiteLists()`, `initialize()`, `InvestmentNFT.setURI()` admin array loops. The counter was `uint8`, causing `i++` to overflow-revert when admin count reaches 256. |
| **Risk** | `_isWhiteLists` gates all major operations (deposit, withdraw, mintNFT, distributeYield, maturity, registerProduct, etc.), permanently disabling all whitelist-gated functions. |
| **Mitigation** | All loop counters unified to `uint256`. `addAdmin` now enforces `MAX_ADMINS = 255` cap to prevent unbounded array growth. |

### 1.4c Zero-investor product causing Automation infinite loop (F-2026-16869 — mitigated)

| Item | Detail |
|------|--------|
| **Where** | `distributeYield` / `maturity` for products with `raisedAmount == 0` (no investors subscribed). `getNFTInfos` returns an empty array since no NFTs were minted, causing the loop to execute zero iterations. |
| **Risk** | `distributedCount` never increments, so Chainlink Automation's `checkUpkeep` returns the same product every cycle, starving all subsequent products. `maturity` permanently reverts with `BeforeDistributionCompleted`. |
| **Mitigation** | Early return guard when `raisedAmount == 0`: immediately increment `distributedCount` / set `isMaturity = true` and return, skipping yield calculation and NFT external calls entirely. |
**Yield Sweep (F-2026-17209)**: `maturity` and `claimPrincipal` now aggregate all unclaimed yield slots and transfer them together with the principal before burning the NFT. On success, individual `YieldClaimed` events are emitted per slot, then the NFT is burned. On failure, the principal is escrowed (yield remains escrowed) and the NFT is not burned, preventing permanent yield lock after burn.

### 1.4d Restored funding does not resume Automation (F-2026-16870 — mitigated)

| Item | Detail |
|------|--------|
| **Where** | `deposit` after `distributeYield` / `maturity` set `isInsufficientBalance = true` due to insufficient `productPool`. |
| **Risk** | Previously `deposit` increased `productPool` but never cleared the `isInsufficientBalance` flag. Automation's `checkUpkeep` unconditionally skips flagged products, so settlement could not resume automatically even after full funding restoration. Operators had to manually call `distributeYield` / `maturity`. |
| **Mitigation** | `deposit` now unconditionally clears `isInsufficientBalance` after updating `productPool`. If the pool is still short on the next upkeep cycle, `distributeYield` / `maturity` will re-set the flag, so clearing is safe and idempotent. |

### 1.4e Distribution schedule exceeding maturity date causes principal lock (F-2026-16949 — mitigated)

| Item | Detail |
|------|--------|
| **Where** | `registerProduct` when distribution schedule parameters (`distributionStartDate` + `distributionInterval` x (`totalDistributionCount` - 1)) extend past `maturityDate`. |
| **Risk** | `maturity` requires all distributions to complete first. If the schedule exceeds `maturityDate`, maturity processing cannot execute at the disclosed date, locking investor principal for the overshoot period (months to years). Product registration is a one-shot operation with no on-chain recovery. |
| **Mitigation** | Added `DistributionDateLib.calculateNextDistributionDate` computation in `registerProduct` to derive the last distribution date. Reverts with `InvalidMaturityDate` when `lastDistributionDate > maturityDate`, preventing misconfigured schedules at registration time. |

### 1.4f Product registration with unconfigured Tier Registry (F-2026-16955 — mitigated)

| Item | Detail |
|------|--------|
| **Where** | `registerProduct` with `requiredTier != 0` while `allowedByTierAddress[requiredTier]` was empty (before fix). |
| **Risk** | All `invest` / `mintNFT` calls revert with `NotEligible` because `hasPurchasePermission` always returns false — temporary DoS for that product. Mis-registration could also waste gas on CREATE2 NFT deployment. |
| **Mitigation** | `registerProduct` now reverts with `TierNotConfigured` when `requiredTier != 0` and the tier has no SBT contracts in the registry. Operational flow: configure Tier Registry before product registration. |
| **Follow-up** | If the wrong `requiredTier` was already stored, admins can fix it per product via `SetTier.setProductRequiredTier` (non-zero tier still requires registry; matured products allowed). Emit `ProductRequiredTierUpdated` for off-chain disclosure. |

### 1.4g Duplicate admin entries at initialize (F-2026-16872 — mitigated)

| Item | Detail |
|------|--------|
| **Where** | `Initialize.initialize(admins, ...)` at deploy time. Previously duplicate addresses in calldata were pushed; only `addAdmin` rejected duplicates with `AlreadyExistsAdmin`. |
| **Risk** | `deleteAdmin` removes only the first match, so one deletion may leave admin rights. Extra gas in `_isWhiteLists` scans and wasted `MAX_ADMINS` slots. Info-level; no privilege escalation. |
| **Mitigation** | `initialize` now reverts on duplicates within calldata (`j < i` loop, `AlreadyExistsAdmin`), aligning with `addAdmin` unique-admin invariant. |

---

## 2. Risks Related to Special Features

### 2.1 NFT Issuance for Interest

**Assessment note**: `safeMint` and incrementing `tokenId` are fine.

**Double-mint risk**

- Bugs that mint duplicates or roll back `tokenIdCounter`.

**Resale vs. distribution**

- If NFTs trade freely, ambiguity between “holder at distribution” vs “holder at snapshot” causes disputes.

**Mitigation**

- Use clear ID management with `_safeMint` or `ERC721Enumerable` as appropriate.  
- **Lock the rule** for who receives distributions.

---

### 2.2 JPY Deposits and Wallets

**Off-chain deposit fraud** — **Assessment note**: Acceptable under operational assumptions.

- Claims of bank transfer without actual credit; mistaken admin approval could mint NFTs improperly.

**KYC / AML**

- Legal requirements may mandate identity checks—mostly backend, but watch for impersonation of user IDs.

---

### 2.3 Maturity Processing

**Assessment note**: Add checks that all distributions completed before maturity (`distributeYield` checks as well).

**Forced NFT burn**

- Burning before all distributions complete due to logic errors.

**Principal calculation**

- Bugs in repayment formula cause over- or under-payment.  
- Handle failed transfers to investors.

---

### 2.4 Administration

**Assessment note**: Contract-level checks in place; acceptable.

**Reliance on admin UI**

- Frontend or admin tool bugs may call contract functions with wrong arguments.

**Mitigation**

- Strong on-chain validation (e.g., product exists, dates not in the past).

---

## 3. ERC20 Profit Distribution

### 3.1 Token Contract Security

**Assessment note**: USDT acceptable.

- If the distribution token has owner powers, assess mint/freeze abuse.  
- Assess unauthorized mint; **NFT minting is owner-only—OK**.

---

### 3.2 Fees / Insufficient Gas or Token Balance

**Assessment note**: Re-check balances at distribution time.

- Large batches may fail from insufficient contract ETH or token balance.  
- Consider splitting distributions across transactions.

---

### 3.3 Double Claiming

**Assessment note**: Distribution state on proxy prevents double claims.

- Poor design could allow claiming the same distribution twice.  
- Track per-distribution-id consumption in logic.

---

## 4. Other Considerations

### 4.1 Privacy / Regulation

- Excessive on-chain investor data raises privacy issues.  
- Keep KYC and bank details off-chain; minimal on-chain data.

---

### 4.2 Social Engineering

**Assessment note**: Safe (multisig) in use.

- Not contract-specific, but compromised admin or multisig keys can drain funds.  
- Multisig and key hygiene matter.

---

### 4.3 Upgrades / Proxy Pattern

- Upgradeable contracts may be used as requirements change.  
- Careless upgrades can break state or leak admin rights—strict procedures and permissions.

**Implementation contract direct initialization prevention (F-2026-17010 — mitigated)**: Under the ERC-7546 / MC framework, function contracts are deployed as standalone contracts. Any contract inheriting OpenZeppelin `Initializable` must call `_disableInitializers()` in its constructor to prevent external callers from directly invoking `initialize` on the implementation. Proxy-based initialization is unaffected (delegatecall uses the proxy's own storage).

**Duplicate admin prevention at initialize (F-2026-16872 — mitigated)**: `initialize` reverts with `AlreadyExistsAdmin` when the `admins` calldata array contains duplicates, matching the `addAdmin` unique-admin invariant. See `docs/audit/fix/F-2026-16872-initialize-duplicate-admin-check.md`.

---

## Summary

- Beyond baseline attacks (reentrancy, overflow, access control), **front-running / timing** around NFT trading and distributions is possible.  
- Watch **gas limits** on large loops—batch or off-chain calculation.  
- **Strict admin control** and multisig reduce single-key compromise.  
- **Maturity, principal repayment, and burns** need strong validation and transaction design.  
- **KYC/AML** and bank flows need off-chain security.  
- **Security audits and thorough testing** are essential when handling user funds.
