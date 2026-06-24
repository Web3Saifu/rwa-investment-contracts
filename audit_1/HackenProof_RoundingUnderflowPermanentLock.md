# Rounding-Induced Arithmetic Underflow Permanently Locks Principal in Affected Investment Products

## 1. Vulnerability Details

### Summary

`DistributeYield.distributeYield()` can permanently revert during continuation of a multi-batch yield distribution. The function subtracts the amount distributed in previous batches from a limit calculated using only the **remaining** rounding tolerance:

```solidity
periodYield + periodToleranceRemainder - product.distributedYieldPerCount
```

Per-NFT yields are rounded independently. A valid first batch can therefore produce a `distributedYieldPerCount` greater than `periodYield + periodToleranceRemainder` calculated for the next batch. Solidity 0.8 then raises an arithmetic-underflow panic before either balance check can execute.

The same product state is used on every retry, so every subsequent distribution attempt reverts at the same expression. Depositing additional USDT cannot resolve the failure because the panic occurs while calculating the amount to compare against the balances.

Because maturity requires every scheduled distribution to be completed, the incomplete distribution also prevents maturity. Consequently, principal cannot be returned and `claimPrincipal()` remains unavailable for every NFT in the affected product.

No malicious or privileged behavior is required. The failure is reachable through valid product parameters and ordinary investments that create more than one distribution batch with independently rounded NFT yields.

### Vulnerability Type

- Denial of service through unexpected arithmetic revert
- Permanent lock of user principal in the current implementation
- Incorrect rounding and batch-accounting interaction

### Affected Components

- `src/investment/functions/onlyWhiteLists/DistributeYield.sol`
- `src/investment/functions/onlyWhiteLists/Maturity.sol`
- `src/investment/utils/CalculateYieldLib.sol`

### Root Cause

The protocol processes at most 50 NFTs in each distribution call. After a non-final batch, it stores the cumulative rounded payout in `product.distributedYieldPerCount`:

```solidity
product.distributedYieldPerCount += _distributedYield;
```

On the next call, `calculatePeriodToleranceRemainder()` reduces the tolerance according to the number of completed batches:

```solidity
uint256 alreadyBatchCounted = distributedTokenId / MAX_BATCH_SIZE;
return periodTolerance - (MAX_BATCH_SIZE * alreadyBatchCounted) + alreadyBatchCounted;
```

However, `distributeYield()` then subtracts the **cumulative** payout from `periodYield` plus this reduced tolerance:

```solidity
if (periodYield + periodToleranceRemainder - product.distributedYieldPerCount > product.productPool) {
    // ...
}
```

These values do not share the same accounting basis: `distributedYieldPerCount` includes all prior batches, while `periodToleranceRemainder` excludes tolerance attributed to those batches. Independent upward rounding of NFT yields can therefore make the subtrahend larger than the minuend.

The same unsafe subtraction is evaluated again for the contract-balance check.

### Concrete Reproduction

The attached Foundry PoC constructs a valid product with:

- Minimum investment: `250 USDT`
- Expected yield: `1` basis point
- First distribution period: `631` seconds
- Total distribution count: `1`
- Total NFTs: `51`, requiring two distribution batches
- One NFT representing `250,000 USDT`
- Fifty NFTs representing `250 USDT` each
- Total principal: `262,500 USDT`

The protocol calculates:

```text
periodYield                         = 525
large-position rounded yield       = 500
minimum-position rounded yield     = 1
total period tolerance             = 53
```

The first call processes token IDs 1 through 50:

```text
distributedYieldPerCount = 500 + (49 * 1) = 549
distributedTokenId       = 50
distributedCount         = 0
```

For the second batch, the remaining tolerance is:

```text
periodToleranceRemainder = 53 - 50 + 1 = 4
```

The balance precheck therefore evaluates:

```text
periodYield + periodToleranceRemainder - distributedYieldPerCount
= 525 + 4 - 549
= 529 - 549
```

This underflows and reverts with Solidity's arithmetic panic.

### Why the Lock Persists

1. The reverting call does not advance `distributedTokenId` or `distributedCount`.
2. Every retry recomputes the same values and reaches the same underflow.
3. Additional deposits only change token balances and `productPool`; they do not change the operands that underflow.
4. `Maturity.maturity()` reverts with `BeforeDistributionCompleted` while `distributedCount < totalDistributionCount`.
5. `claimPrincipal()` reverts with `ProductNotMatured` until maturity has completed.
6. No function in the current implementation resets, skips, or repairs this stalled distribution state.

Therefore, without changing the implementation, all principal associated with the affected product remains inaccessible through the protocol.

### Impact

The failure blocks the final yield batch, product maturity, NFT burning, principal repayment, and principal claims for all investors in the affected product.

The PoC locks `262,500 USDT`, including the complete `250,000 USDT` position used to demonstrate end-user impact. This is 100% of that user's principal and 100% of the principal represented by the affected product. Whether this amount exceeds 2% of live protocol TVL depends on the deployed protocol state at the time of assessment.

### Preconditions and Reachability

The issue requires:

1. A product whose yield and first-period parameters produce susceptible rounding values.
2. More than 50 NFTs, so distribution continues in a second transaction.
3. A distribution of NFT sizes that causes cumulative individually rounded yield to exceed the next call's reduced allowance.

All of these states are accepted by the current implementation. No malformed token, callback, compromised role, or external dependency failure is required.

### Suggested Mitigation

Use one consistent accounting basis for the period-wide limit and the cumulative amount already distributed. For example, calculate the remaining upper bound from the full period tolerance:

```solidity
uint256 maximumPeriodPayout = periodYield + periodTolerance;

if (product.distributedYieldPerCount > maximumPeriodPayout) {
    revert IInvestmentErrors.InvalidDistributionAccounting();
}

uint256 remainingPeriodPayout = maximumPeriodPayout - product.distributedYieldPerCount;

if (remainingPeriodPayout > product.productPool) {
    product.isInsufficientBalance = true;
    emit IInvestmentEvents.InsufficientProductPoolForDistribution(productId);
    return;
}

if (remainingPeriodPayout > usdt.balanceOf(address(this))) {
    revert IInvestmentErrors.InsufficientFunds();
}
```

Alternatively, calculate the exact payout for the next NFT batch before performing balance checks. In either design, do not subtract a cumulative prior payout from a limit containing only the remaining tolerance.

Add regression tests covering 49, 50, 51, 99, 100, and 101 NFTs with mixed investment sizes and upward/downward rounding.

## 2. Validation Steps

### Prerequisites

- Foundry installed
- Repository dependencies initialized
- Run commands from the repository root

### PoC File

```text
test/audit/HP_RoundingUnderflowPermanentLock.t.sol
```

### Execute the PoC

```powershell
forge test --match-path test/audit/HP_RoundingUnderflowPermanentLock.t.sol -vv
```

### Expected Result

```text
[PASS] test_permanentProductLockFromRoundingUnderflow()
1 passed; 0 failed
```

### What the PoC Proves

1. The product and all 51 investments are accepted by the protocol.
2. The simulated yield budget is deposited successfully.
3. The first distribution batch succeeds and records `distributedYieldPerCount = 549`.
4. The second batch reverts with an arithmetic panic.
5. A large additional deposit does not repair the failure.
6. Maturity reverts because distribution remains incomplete.
7. Principal claiming reverts because the product cannot mature.
8. The NFT and its full principal amount remain recorded but inaccessible.

## 3. Supporting File

Attach the following file to the HackenProof submission:

```text
test/audit/HP_RoundingUnderflowPermanentLock.t.sol
```

The PoC is self-contained within the repository's existing Foundry test environment and makes no production-code modifications.
