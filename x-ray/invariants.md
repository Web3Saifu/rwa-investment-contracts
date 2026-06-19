# Invariant Map

> RWA Investment Contracts | 24 guards | 10 inferred | 2 not enforced on-chain

---

## 1. Enforced Guards (Reference)

Per-call preconditions. Heading IDs below (`G-N`) are anchor targets from x-ray.md attack surfaces.

#### G-1
`if (product.productId == 0) revert ProductNotFound()` · `Invest.sol:44` · Prevents investment into an unregistered product record.

#### G-2
`if (unitCount == 0) revert ZeroAmount()` · `Invest.sol:47` · Prevents zero-value NFT issuance and zero-value pool accounting.

#### G-3
`if (product.isMaturity) revert MaturedProduct()` · `Invest.sol:50` · Stops new subscriptions after product lifecycle completion.

#### G-4
`if (block.timestamp >= product.offeringEndDate) revert OfferingPeriodEnded()` · `Invest.sol:54` · Enforces the subscription deadline.

#### G-5
`if (!PurchasePermissionLib.hasPurchasePermission(msg.sender, product.requiredTier)) revert NotEligible(product.requiredTier)` · `Invest.sol:58` · Ties public investment to the product's configured eligibility tier.

#### G-6
`if (product.raisedAmount + investmentAmount > product.offeringAmount) revert ExceedOfferingAmount()` · `Invest.sol:64` · Keeps subscriptions within the product cap.

#### G-7
`if (product.distributedCount >= product.totalDistributionCount) revert DistributionCompleted()` · `DistributeYield.sol:56` · Prevents extra yield rounds beyond the configured schedule.

#### G-8
`if (nextDistributionDate > block.timestamp) revert BeforeDistributionStartDate()` · `DistributeYield.sol:63` · Enforces the next scheduled distribution time.

#### G-9
`if (periodYield + periodToleranceRemainder - product.distributedYieldPerCount > product.productPool)` · `DistributeYield.sol:103` · Prevents yield settlement when the product pool cannot cover the batch.

#### G-10
`if (product.maturityDate > block.timestamp) revert BeforeMaturityDate()` · `Maturity.sol:42` · Enforces maturity-date settlement timing.

#### G-11
`if (product.totalDistributionCount > product.distributedCount) revert BeforeDistributionCompleted()` · `Maturity.sol:46` · Prevents principal repayment before all scheduled yield rounds are complete.

#### G-12
`if (product.raisedAmount - product.totalReturnedAmount > product.productPool)` · `Maturity.sol:61` · Prevents principal settlement when the product pool cannot cover remaining principal.

#### G-13
`if (IERC721(product.nftContract).ownerOf(tokenId) != msg.sender) revert NotNFTOwner()` · `Claim.sol:36` · Restricts escrow claims to the current NFT owner.

#### G-14
`if (amount == 0) revert NothingToClaim()` · `Claim.sol:42` · Prevents empty yield claims.

#### G-15
`if (!product.isMaturity) revert ProductNotMatured()` · `Claim.sol:67` · Allows principal escrow claims only after product maturity.

#### G-16
`if (principalAmount == 0) revert NothingToClaim()` · `Claim.sol:81` · Prevents empty principal claims.

#### G-17
`if (args.offeringAmount % args.minInvestment != 0) revert OfferingAmountNotDivisibleByMinInvestment()` · `RegisterProduct.sol:57` · Keeps the product offering divisible into whole investment units.

#### G-18
`if (lastDistributionDate > args.maturityDate) revert InvalidMaturityDate()` · `RegisterProduct.sol:86` · Prevents a distribution schedule that extends beyond maturity.

#### G-19
`if (args.requiredTier != 0 && allowedByTierAddress[args.requiredTier].length == 0) revert TierNotConfigured(args.requiredTier)` · `RegisterProduct.sol:90` · Prevents products with impossible non-zero tier eligibility.

#### G-20
`if (msg.sender != forwarderAddress) revert NotForwarder(msg.sender)` · `Automation.sol:94` · Restricts automated settlement execution to the configured Chainlink forwarder.

#### G-21
`if (amount <= 0) revert ZeroAmount()` · `InvestmentNFT.sol:108` · Prevents zero-amount investment NFTs.

#### G-22
`if (!(Storage.ConfigState().SAFE_MULTISIG_WALLET == msg.sender)) revert NotOwner()` · `OnlyOwnerBase.sol:9` · Restricts top-level role changes to the configured Safe wallet.

#### G-23
`if (!_isWhiteLists()) revert NotAdmin()` · `OnlyWhiteListsBase.sol:9` · Restricts operational admin functions to the whitelist.

#### G-24
`if (!_isMinter()) revert NotMinter()` · `OnlyMintersBase.sol:9` · Restricts off-chain JPY NFT crediting to configured minters.

---

## 2. Inferred Invariants (Single-Contract)

#### I-1

`Conservation` · On-chain: **Yes**

> `invest()` increases both `product.raisedAmount` and `product.productPool` by the same `investmentAmount`.

**Derivation** - delta-pair: `Invest.sol:79` and `Invest.sol:80`.

**If violated** - Product accounting can diverge between sold principal and pool balance.

---

#### I-2

`Bound` · On-chain: **Yes**

> A product's `raisedAmount` cannot exceed `offeringAmount` through `invest()` or `mintNFT()`.

**Derivation** - guard-lift: `Invest.sol:64` and `MintNFT.sol:56`; write sites are `Invest.sol:79` and `MintNFT.sol:61`.

**If violated** - More NFT principal can be issued than the product offering cap.

---

#### I-3

`Bound` · On-chain: **No**

> Non-zero `requiredTier` is required to reference a configured tier, but admin can change it after product registration without considering current holders.

**Derivation** - guard-lift: `RegisterProduct.sol:90` and `SetTier.sol:99`; write sites are `RegisterProduct.sol:127` and `SetTier.sol:108`.

**If violated** - Product eligibility assumptions can change during the product lifecycle.

---

#### I-4

`Temporal` · On-chain: **Yes**

> Public USDT investment is only accepted before `offeringEndDate`.

**Derivation** - temporal: `Invest.sol:54` compares `block.timestamp` against stored `product.offeringEndDate`.

**If violated** - Investors could subscribe after the disclosed offering window.

---

#### I-5

`Temporal` · On-chain: **Yes**

> Maturity can execute only after `maturityDate` and after all distributions have been counted.

**Derivation** - temporal/state guard: `Maturity.sol:42` and `Maturity.sol:46`.

**If violated** - Principal could be repaid before the scheduled lifecycle is complete.

---

#### I-6

`StateMachine` · On-chain: **Yes**

> `product.isMaturity` moves from false to true in maturity and has no production reverse path.

**Derivation** - edge: `false` at registration `RegisterProduct.sol:128` -> `true` at `Maturity.sol:51` or `Maturity.sol:113`; no production setter resets it.

**If violated** - Matured products could re-enter active investment/distribution paths.

---

#### I-7

`Conservation` · On-chain: **Yes**

> Successful distribution decreases `product.productPool` by exactly the batch `_distributedYield`.

**Derivation** - delta accounting: `_distributedYield` accumulates at `DistributeYield.sol:126`/`134-135`; pool decreases at `DistributeYield.sol:159`.

**If violated** - Distributed or escrowed yield can become inconsistent with remaining product pool.

---

#### I-8

`Conservation` · On-chain: **Yes**

> Successful maturity batch decreases `product.productPool` and increases `product.totalReturnedAmount` by the same returned principal amount.

**Derivation** - delta-pair: `_returnedAmount` accumulates at `Maturity.sol:100`/`107`; writes are `Maturity.sol:125` and `Maturity.sol:126`.

**If violated** - Principal repayment progress and remaining pool balance can diverge.

---

#### I-9

`StateMachine` · On-chain: **Yes**

> `activeProductIdKeys` membership is added on registration and removed on maturity using 1-indexed `activeIndex`.

**Derivation** - edge: add at `RegisterProduct.sol:135-136`; swap-and-pop remove at `Maturity.sol:132-147`.

**If violated** - Automation and getters can scan stale or missing active products.

---

#### I-10

`Bound` · On-chain: **No**

> `claimPrincipal()` sends `principalAmount + totalUnclaimedYield` before clearing escrow state.

**Derivation** - order observation: transfer at `Claim.sol:93` precedes clearing at `Claim.sol:97-101`; protected by `nonReentrant` at `Claim.sol:62`.

**If violated** - This relies on the reentrancy guard and token behavior to keep escrow state from being reused during the external transfer.

---

## 3. Inferred Invariants (Cross-Contract)

#### X-1

On-chain: **Yes**

> Investment facets assume `InvestmentNFT.mint()` records the same investment amount used in product accounting.

**Caller side** - `Invest.sol:79-86` and `MintNFT.sol:61-65` update product accounting then mint the NFT.

**Callee side** - `InvestmentNFT.sol:112-116` increments token ID and stores `_investmentAmounts[tokenIdCounter] = amount`.

**If violated** - NFT-based yield/principal calculations would no longer match product accounting.

---

#### X-2

On-chain: **Yes**

> Distribution and maturity cursors assume `InvestmentNFT.getNFTInfos(startTokenId)` returns existing token IDs in ascending batches of up to 50.

**Caller side** - `DistributeYield.sol:114-157` and `Maturity.sol:71-123` advance cursors from returned token IDs.

**Callee side** - `InvestmentNFT.sol:137-154` builds sequential token info from `startTokenId` to `min(start + 49, tokenIdCounter)`.

**If violated** - Batch settlement cursors can skip or repeat NFT positions.

---

#### X-3

On-chain: **Yes**

> Claim functions assume current `ownerOf(tokenId)` controls escrowed yield and principal for that NFT.

**Caller side** - `Claim.sol:36` and `Claim.sol:75` check current ERC721 ownership before paying.

**Callee side** - `InvestmentNFT.sol:125-129` burns only from the investment contract owner path and clears investment amount after burn.

**If violated** - Escrow could be claimed by an address that no longer owns the investment NFT.

---

#### X-4

On-chain: **Yes**

> Automation assumes `getActiveProducts()` excludes matured products and exposes products needing distribution or maturity.

**Caller side** - `Automation.sol:40-78` scans active products and skips `isMaturity` / `isInsufficientBalance`.

**Callee side** - `Getter.sol:50-55` reads `activeProductIdKeys`; `Maturity.sol:132-147` removes matured products.

**If violated** - Upkeep can target stale products or miss live products.

---

## 4. Economic Invariants

#### E-1

On-chain: **Yes**

> Subscribed principal is represented by NFTs and can be repaid by walking the NFT set at maturity.

**Follows from** - `I-1` + `X-1` + `X-2` + `I-8`.

**If violated** - Principal accounting, NFT ownership, and maturity repayment no longer reconcile.

---

#### E-2

On-chain: **No**

> Eligibility is enforced at purchase time, but NFT transferability means later distribution ownership is not tied to the original purchaser's tier.

**Follows from** - `I-3` + `X-3`.

**If violated** - This may be intentional per requirements, but auditors should verify it matches business and compliance expectations.

