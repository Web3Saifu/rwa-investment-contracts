# Sherlock Question Inventory

## X-Ray Inputs

- `x-ray/x-ray.md` - protocol overview, threat model, attack surfaces, dependency risks, test gaps
- `x-ray/entry-points.md` - permissionless, role-gated, admin, automation, and view surfaces
- `x-ray/invariants.md` - guards, inferred invariants, cross-contract invariants, economic invariants
- `x-ray/architecture.json` - actor/protocol/dependency relationships
- `x-ray/enumeration.json` - repo/test/formal coverage counts

## Output Rule

This file is question-only. It does not confirm bugs, reject bugs, assign severity, or perform proof work. Each item is a candidate investigation question generated from the X-Ray context.

## Count Summary

| Category | Count |
|---|---:|
| Value flow / accounting | 10 |
| Ownership / entitlement | 10 |
| Lifecycle / timing | 10 |
| External dependency behavior | 10 |
| Batch / cursor / indexing | 10 |
| Role / configuration | 10 |
| Recovery / escrow | 10 |
| Automation / liveness | 10 |
| Documentation intent mismatch | 10 |
| Unusual cross-feature questions | 10 |
| Total | 100 |

## Highest-Risk Question Areas

1. Can off-chain JPY minting create principal obligations that are not funded before distribution or maturity?
2. Can transferable NFT ownership cause yield, escrow, or principal entitlement to move in a way the business model does not intend?
3. Can failed USDT push payments, escrow recovery, and NFT burn ordering create stuck or double-meaning state?
4. Can batch cursors over sequential NFT IDs behave unexpectedly across partial distribution, partial maturity, failed transfers, and burns?
5. Can admin-operated lifecycle changes create honest-but-bad-timing risk for existing investors?

## Full Question Inventory

### Value Flow / Accounting

1. If `invest()` increases both `raisedAmount` and `productPool`, but `mintNFT()` increases only `raisedAmount`, what exact question must be asked about how off-chain JPY funding enters `productPool`?
2. If a product has both USDT investors and JPY-credit minted investors, can the two funding paths create different accounting meanings for the same NFT investment amount?
3. If `productPool` is reduced when yield is pushed or escrowed, does the remaining pool still represent only undistributed yield plus unrepaid principal?
4. If a yield transfer fails and becomes escrow, is that escrow economically removed from the pool in the same way as a successful transfer?
5. If an admin deposits after `isInsufficientBalance` is set, does the new `productPool` meaning include old unpaid obligations, future yield, principal, or all of them?
6. If an admin withdraws before all distributions or maturity are complete, what question should be asked about whether `productPool` still covers all remaining obligations?
7. If principal repayment at maturity decreases `productPool` and increases `totalReturnedAmount`, can partial maturity create a temporary state that frontends or automation misunderstand?
8. If zero raised amount causes distribution or maturity to complete early, what question should be asked about empty products and active product accounting?
9. If rounding tolerance is calculated per batch or token count, can accumulated dust make `productPool` look sufficient or insufficient at a boundary?
10. If `raisedAmount`, `productPool`, `distributedYieldPerCount`, and `totalReturnedAmount` are all product-level meanings, which combinations should never be compared as if they were the same unit of obligation?

### Ownership / Entitlement

1. If claims use current `ownerOf(tokenId)`, should escrowed yield belong to the original investor, the holder during distribution failure, or the holder at claim time?
2. If an NFT is transferred after yield escrow is created but before `claimYield()`, who should economically receive the escrowed yield?
3. If an NFT is transferred after principal escrow is created but before `claimPrincipal()`, who should economically receive the principal?
4. If an NFT is transferred after several distributions but before maturity, does the new holder inherit all unclaimed yield slots or only future rights?
5. If tier eligibility is checked only at purchase time, should a lower-tier buyer of a transferred NFT receive the same future economics as the eligible original purchaser?
6. If an admin changes `requiredTier` after product registration, should existing NFT holders be grandfathered, rechecked, or unaffected?
7. If a product is intended to represent regulated RWA ownership, what question should be asked about transferable bearer NFTs and off-chain compliance records?
8. If `claimPrincipal()` burns the NFT after successful payment, can any later entitlement still be expected by the former owner or frontend?
9. If an NFT owner is blocked by USDT at distribution time but later sells the NFT, does the blocked owner lose recovery rights by design?
10. If ownership controls escrow, what question should be asked about marketplaces showing NFTs without displaying attached unclaimed yield or principal?

### Lifecycle / Timing

1. If public `invest()` is allowed until `offeringEndDate`, but `mintNFT()` is bounded by `operationStartDate`, what lifecycle assumption explains the difference?
2. If distribution starts after operation start, what question should be asked about products whose offering window overlaps or nearly overlaps distribution timing?
3. If maturity requires all distributions completed, can delayed distributions push principal repayment later than business expectations?
4. If a distribution date falls after maturity because of month-end normalization, what question should be asked about schedule validation?
5. If `isMaturity` has no reverse path, what question should be asked about accidental early maturity on zero raised products?
6. If a product is insufficient during distribution, does the lifecycle pause only that distribution, all future distributions, or maturity too?
7. If admin execution is possible independent of automation, what question should be asked about out-of-order manual calls around distribution and maturity?
8. If `distributedCount` advances for zero-raised products, can lifecycle completion happen without any NFT supply?
9. If a product has multiple distribution rounds, can a missed round later be executed at the same timestamp as a later round?
10. If a product is partially matured across batches, what lifecycle state should users see while some NFTs are burned and others are still active?

### External Dependency Behavior

1. If USDT transfer succeeds without returning a boolean, does the wrapper treat that as success in every relevant path?
2. If USDT blacklists a recipient, does each push-payment path isolate that recipient without blocking unrelated holders?
3. If USDT transfer returns false instead of reverting, does the escrow path behave the same as when it reverts?
4. If USDT has fee-on-transfer behavior, what question should be asked about internal `productPool` versus actual received balance?
5. If the settlement token rebases or changes balances unexpectedly, which accounting assumptions would become questionable?
6. If a Tier SBT contract reverts on `balanceOf`, can one bad eligibility dependency block all public investments for a tier?
7. If a Tier SBT changes ERC165 support or token ID balances after product registration, how does eligibility meaning drift?
8. If Chainlink forwarder configuration is wrong, can admins recover all settlement actions manually?
9. If the Automation contract is not whitelisted in Investment, does `performUpkeep()` become a silent liveness failure or an explicit revert?
10. If an external dependency changes behavior after products are live, which existing product states become most fragile?

### Batch / Cursor / Indexing

1. If `getNFTInfos(startTokenId)` walks sequential token IDs, what question should be asked about burned token gaps before the cursor?
2. If distribution processes at most 50 NFTs per call, can token 51 receive different treatment from token 50 at a boundary?
3. If maturity burns NFTs during a batch, how does the next maturity call avoid reading burned IDs?
4. If a transfer fails for one token in a batch, does the cursor advance based on token ID, successful payment count, or array position?
5. If `distributedTokenId` is reset after a round completes, can stale state from the previous round affect the next round?
6. If `distributedYieldPerCount` accumulates during partial batches, can an interrupted round calculate the next batch differently?
7. If an NFT is transferred between distribution batch 1 and batch 2, which owner should receive later batch yield?
8. If token IDs are sequential but ownership changes are arbitrary, what question should be asked about per-token versus per-owner batch fairness?
9. If `tokenIdCounter` is used as the last token ID, what happens if the final token has been burned while earlier unsettled tokens remain?
10. If a getter loops over claimable slots, can mid-round distribution state hide or overstate a token's claimable yield?

### Role / Configuration

1. If Safe can add or remove admins instantly, what questions should be asked about live products during role changes?
2. If Safe can add or remove minters instantly, what questions should be asked about off-chain subscriptions already accepted but not minted?
3. If an admin configures tier SBT addresses, can a wrong address make a product impossible or unexpectedly open?
4. If `requiredTier` can change after product registration, what investor expectation could become false?
5. If minters can mint NFTs without token transfer, what operational reconciliation questions must be asked before maturity?
6. If admins can withdraw from product pools, what question should be asked about minimum reserve constraints for future obligations?
7. If an admin honestly follows docs but calls deposit after minting instead of before, which temporary states become risky?
8. If multiple admins operate the same product, can one admin's distribution, deposit, or withdraw timing surprise another admin's assumptions?
9. If role arrays are used for authorization, what question should be asked about duplicate, stale, or deleted role entries?
10. If product setup uses CREATE2 for NFT deployment, can product ID reuse, deployment failure, or address predictability create operational edge cases?

### Recovery / Escrow

1. If yield push fails and escrow is stored by `productId/tokenId/distributionIndex`, can the same slot ever be recreated after claim?
2. If principal push fails at maturity, does principal escrow preserve all yield slots that also failed or remained unclaimed?
3. If `claimYield()` clears before transfer but restores on failure, what question should be asked about atomicity under non-standard tokens?
4. If `claimPrincipal()` transfers before clearing, what later proof question exists around reentrancy guard and token behavior?
5. If a user claims some yield slots before maturity, does maturity sweep only the remaining slots?
6. If a user is blocked during maturity and later unblocked, does recovery preserve exact principal plus unpaid yield?
7. If a user transfers an NFT after principal is escrowed, does recovery follow current ownership by design?
8. If an NFT is burned after successful maturity, can any escrow remain attached to that token ID?
9. If escrowed yield is economically removed from `productPool`, what question should be asked about contract token balance versus internal accounting?
10. If a claim fails repeatedly, can repeated attempts change product-level accounting or only leave escrow unchanged?

### Automation / Liveness

1. If Automation skips products with `isInsufficientBalance`, who is responsible for detecting and funding them?
2. If multiple products are active, can one insufficient product hide or delay another product that is ready?
3. If `checkUpkeep()` prioritizes maturity over distribution when both appear ready, can any product state make that priority wrong?
4. If automation is down, can manual admin execution fully preserve the same state transitions?
5. If the forwarder submits stale `performData`, does Investment re-check the real product state before settling?
6. If `activeProductIdKeys` is stale, can automation target a matured or missing product?
7. If maturity removes products from the active set only after the final batch, how should automation treat partially matured products?
8. If insufficient balance is cleared by deposit, does automation resume at the correct distribution or maturity cursor?
9. If automation scans active products in order, can a large number of products cause recurring delay for later products?
10. If keepers can only call Automation but admins can call Investment directly, what question should be asked about divergent operational paths?

### Documentation Intent Mismatch

1. Does the documentation say current NFT holder owns economics, or does it imply original investor ownership?
2. Does the off-chain JPY flow documentation require deposit before mint, mint before deposit, or only eventual reconciliation?
3. Does the business model expect tier eligibility only at purchase time, or also at claim and transfer time?
4. Does the maturity documentation describe partial-batch settlement clearly enough for users whose NFTs are not in the first batch?
5. Does the escrow documentation tell users that transferring an NFT can transfer attached recovery rights?
6. Does the admin guide define when withdraw is safe relative to future distribution and maturity obligations?
7. Does the automation documentation describe insufficient-balance recovery as manual admin responsibility?
8. Does the security documentation treat USDT blacklist behavior as a normal recovery path or an exceptional incident?
9. Does the product metadata/URI model tell markets or users about product maturity, escrow, or claimable status?
10. Does the test documentation explain why no stateful invariant fuzzing exists for the lifecycle accounting surface?

### Unusual Cross-Feature Questions

1. What if an NFT is transferred between a failed yield push and a later failed principal push; do both recovery rights intentionally follow the new holder?
2. What if a product is JPY-minted, underfunded, marked insufficient, then funded after some schedule dates have passed; which distribution dates remain meaningful?
3. What if a tier SBT reverts only for one investor during a high-demand offering; can that investor be excluded while others continue?
4. What if an admin changes `requiredTier` after NFTs trade on a market; does the market price still reflect the same product rights?
5. What if a recipient is USDT-blocked for yield, sells the NFT, then becomes unblocked before maturity; who does the protocol intend to make whole?
6. What if distribution creates escrow for token 1, token 1 is transferred several times, and then maturity sweeps all old slots to the final holder?
7. What if a product has exactly 50, 51, or 100 NFTs; which batch boundary questions should be asked before trusting cursor logic?
8. What if a product has zero yield but still has principal maturity and escrow recovery; do zero-yield paths share all the same safety assumptions?
9. What if a trusted admin is honest but late, and deposits after `isInsufficientBalance` blocked automation; which user-facing promises become delayed?
10. What if frontend claimable data is stale during a mid-round distribution; can users make transfer or claim decisions using incomplete economic state?
