# Access Control

## Overview

```text
┌──────────────────────────── Investment Contract ────────────────────────────┐
│                                                                             │
│  ┌────────────── Safe only ──────────────┐  ┌────── whiteList only ──────┐  │
│  │ addAdmin                              │  │ distributeYield            │  │
│  │ deleteAdmin                           │  │ registerProduct            │  │
│  │ addMinter                             │  │ deposit                    │  │
│  │ deleteMinter                          │  │ withdraw                   │  │
│  │ Dictionary                            │  │ maturity                   │  │
│  │ mapping(bytes4 selector => imple)     │  │ setAllowedByTierAddress    │  │
│  └───────────────────────────────────────┘  │ setAllowedByTierId         │  │
│                                             └────────────────────────────┘  │
│  ┌────────────── minter only ────────────┐                                  │
│  │ mintNFT (JPY payment)                 │                                  │
│  └───────────────────────────────────────┘                                  │
│                                                                             │
│                      ┌──────────── All accessible ────────────┐             │
│                      │ Getter                                 │             │
│                      │ invest                                 │             │
│                      └────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘

                 │
                 ├─────────────→ NFT Contract
                 │
                 ▼

┌─────────────────────────────── NFT Contract ────────────────────────────────┐
│                                                                             │
│  ┌──────── InvestmentContract only ────────┐                                │
│  │ mint(uint256 productId, address to)     │                                │
│  │ burn(uint256 tokenId)                   │                                │
│  └─────────────────────────────────────────┘                                │
│                                                                             │
│  ┌────────────── All accessible ──────────────┐                             │
│  │ getTokenIds(uint256 productId)             │                             │
│  └────────────────────────────────────────────┘                             │
│                                                                             │
│  ┌───────────── whiteList only ───────────────┐                             │
│  │ setURI(string tokenId)                     │                             │
│  └────────────────────────────────────────────┘                             │
└─────────────────────────────────────────────────────────────────────────────┘


┌──────────────────── Safe Multisig Wallet ────────────────────┐
│ EOA / EOA / EOA / EOA / Dev EOA                              │
└──────────────────────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────── whiteList address ───────────────────────┐
│ Administrators (Admin EOA)                                   │
│ ChainLink                                                    │
│  └─ Automation Contract                                      │
└──────────────────────────────────────────────────────────────┘

┌──────────────────── minter address ──────────────────────────┐
│ Minter EOA(s)                                                │
└──────────────────────────────────────────────────────────────┘

Investors EOA ─────────────────────────→ invest / Getter / NFT reference
ChainLinkKeeper (forwarder) ───────────→ Automation Contract
```

---

## 1. Investment Contract

### 1.0 Deploy-time initialization (`initialize`)

| Item | Validation |
|---|---|
| `admins[]` | No zero addresses (`InvalidAddress`). No duplicates within calldata (`AlreadyExistsAdmin`). Same uniqueness rule as `addAdmin` |
| `minters[]` | No zero addresses (`InvalidAddress`) |
| `usdtAddress` / `safeMultisigWallet` | No zero addresses (`InvalidAddress`). One-time only (`initializer`) |

### 1.1 Safe only

| Function / Item | Permission | Note |
|---|---|---|
| `addAdmin` | Safe only | Max 255 admins (`MAX_ADMINS`). Duplicates revert with `AlreadyExistsAdmin` |
| `deleteAdmin` | Safe only | Removes first match only (admin array is unique at init and on add) |
| `addMinter` | Safe only | Max 255 minters (`MAX_MINTERS`). Duplicates revert with `AlreadyExistsMinter` |
| `deleteMinter` | Safe only | Removes first match only |
| `Dictionary` | Safe only | |
| `mapping(bytes4 selector => address imple)` | Safe only | |

### 1.2 whiteList only

| Function | Permission |
|---|---|
| `distributeYield` | whiteList only |
| `registerProduct` | whiteList only |
| `deposit` | whiteList only |
| `withdraw` | whiteList only |
| `maturity` | whiteList only |
| `setAllowedByTierAddress` | whiteList only. Array entries must be deployed contract addresses with no duplicates (`TierSbtNotContract` / `DuplicateEntry`) |
| `setAllowedByTierId` | whiteList only. No duplicate entries in `ids` (`DuplicateEntry`). Empty array allowed; tokenId 0 allowed |
| `setProductRequiredTier` | whiteList only. Updates an existing product's `requiredTier` (allowed when matured; non-zero tier requires registry) |

### 1.3 minter only

| Function | Permission | Implementation |
|---|---|---|
| `mintNFT` | minter only | `src/investment/functions/onlyMinters/MintNFT.sol` |

### 1.4 NFT owner only (escrow claims)

| Function | Permission |
|---|---|
| `claimYield` | Current `ownerOf(tokenId)` only (`nonReentrant`) |
| `claimPrincipal` | Same (principal escrowed after failed maturity push) |

### 1.5 All accessible

| Function | Permission |
|---|---|
| `Getter` | Readable by everyone (includes `getUnclaimedYield`, `getClaimableForToken`, etc.) |
| `invest` | Executable by everyone |

---

## 2. NFT Contract

### 2.1 InvestmentContract only

| Function | Permission |
|---|---|
| `mint(uint256 productId, address to)` | Investment Contract only |
| `burn(uint256 tokenId)` | Investment Contract only |

### 2.2 All accessible

| Function | Permission |
|---|---|
| `getTokenIds(uint256 productId)` | Readable by everyone |

### 2.3 whiteList only

| Function | Permission |
|---|---|
| `setURI(string tokenId)` | whiteList only |

---

## 3. Permission Principals

### 3.1 Safe Multisig Wallet

| Principal | Role |
|---|---|
| Safe Multisig Wallet | Top-level administration |
| EOA x 4 + Dev EOA | Signers of the Safe |

### 3.2 whiteList address

| Principal | Role |
|---|---|
| Administrators (Admin EOA) | Operational administration |
| ChainLink / Automation Contract | Automated execution system |

### 3.3 minter address

| Principal | Role |
|---|---|
| Minter EOA(s) | Manual JPY mint (`mintNFT`) |

### 3.4 External users

| Principal | Role |
|---|---|
| Investors EOA | Execute `invest`, reference Getter / NFT |
| ChainLinkKeeper (forwarder) | Trigger Automation Contract |

---

## 4. How to Read the Routing

| From | To | Purpose |
|---|---|---|
| Safe Multisig Wallet | Safe-only area | Add/remove admins and minters, update Dictionary |
| whiteList address | whiteList-only area | Product registration, distribution, maturity, deposits/withdrawals, tier settings |
| minter address | minter-only area | `mintNFT` (manual JPY mint) |
| Investors EOA | All-accessible area | `invest` / Getter |
| Investment Contract | NFT Contract | `mint` / `burn` |
| Investors EOA | NFT Contract | `getTokenIds` |
| whiteList address | NFT Contract | `setURI` |
| ChainLinkKeeper | Automation Contract | Automated execution trigger |

---

## 5. One-line Summary

- **Safe**: Top-level configuration changes (including admin / minter management)
- **whiteList**: Daily operations and automated execution
- **minter**: Manual JPY mint (`mintNFT` only)
- **Investor**: Investment and references
- **Investment Contract**: Principal actor for NFT mint / burn
