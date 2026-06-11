# Web3 Fractional Investment Platform — Requirements Specification

## 1. Purpose and Scope

### 1.1 Purpose

The goal of this project is to build a **fractional investment platform leveraging Web3**, with emphasis on the following three points.

1. **System overview**
   Provide a mechanism for investors to invest in diverse real-world assets (RWA) through a **simple and transparent** approach.

2. **Benefits of adoption**
   **Efficiency** of the investment process, **improved transparency**, and **reduced operational burden** on administrators.

3. **rollout flow**
   Clarify the path from system adoption through operational go-live, demonstrating ease of adoption (to be defined together with frontend and operations).

### 1.2 Problems and Objectives

- Build a Web3-based platform where investors can make **fractional investments** in **diverse real-world assets** (e.g., real estate, art, precious metals, energy resources).
- **Tokenize investors’ interests (including dividend entitlements)** using **ERC721 NFTs**, and distribute asset **returns** transparently and efficiently.
- For assets other than real estate, legal authorization for fractional investment can be difficult; a **regulation-compliant solution** is required. As a business direction, aim for a **flexible platform** that can expand to other RWAs while building a system aligned with the **Act on Specified Joint Real Estate Ventures** (final legal interpretation and filings remain with legal counsel and regulators; this document limits itself to system requirements).

### 1.3 Target Customers

| Segment | Description |
|---------|-------------|
| **Industry** | Asset managers and operators conducting asset management under applicable regulations |
| **Roles** | Investors (individuals and corporations), asset management leads, IT leads |
| **Needs** | Transparency in the investment process, flexibility to invest from small amounts, regulatory compliance and safety, efficient return distribution and administration |

---

## 2. Background and Challenges

The following issues affect investors and operators; this system seeks to eliminate or mitigate them.

1. **Investment complexity**
   Small-ticket investment opportunities are scarce, making diversification difficult.

2. **Lack of transparency**
   Concerns about fairness and reliability of return distribution.

3. **Regulatory fit**
   For assets other than real estate, legal structuring for fractional investment is difficult; **regulation-aligned** design is required.

---

## 3. System Overview

This system is a **“Web3 fractional investment platform.”** Investors can invest **from small amounts** in diverse real-world assets; **ERC721 NFTs** tokenize interests; **transparent administration** and **return distribution and principal repayment via ERC20 tokens (operationally mainly USDT, etc.)** are realized.

### 3.1 Main Features (Summary)

| Feature | Summary |
|---------|---------|
| Subscription | Investors select a product and subscribe with an investment amount (units) |
| NFT issuance | Mint **ERC721** proportional to subscription and distribute to wallets |
| Profit distribution | At designed times, distribute in ERC20 to **NFT holders at that moment** |
| Maturity | Principal repayment and **NFT burn** |
| Administration | Product registration and information needed to track progress and distributions |

### 3.2 Feature Details and Benefits

| Feature | Detail | Benefit |
|---------|--------|---------|
| **JPY deposits** | Investors deposit JPY via bank transfer, etc. Operationally, administrators verify amounts and wallet associated with the application. On-chain, this is assumed to work with **pooling USDT equivalent to off-chain deposits** and **NFT issuance**. | **JPY-denominated** deposits are easier for domestic investors |
| **Subscription** | Select a product and specify desired amount (units). | **Fractional** subscription online |
| **NFT issuance** | Mint **ERC721** by subscription amount (units). Link **investment amount** to the token and manage by **product ID**. | **Visibility** of interest and basis for **transfer** (secondary market) |
| **Profit distribution** | Distribute in **ERC20** by subscription share (units / amount). **holders at the time the distribution is executed** are eligible. | Transparent, low operational load |
| **Maturity** | At maturity, repay principal in **ERC20** and **burn** the NFT. | Automate end-of-lifecycle processing |
| **Administration** | Product registration, progress, return distribution status. | Single place to monitor operations |

### 3.3 Business Benefits

- **Broader investor base**: Fractional investment widens the audience; design aims to extend beyond real estate (art, precious metals, etc.).
- **Transparency**: Interest management via NFTs and on-chain distribution and event records.
- **Regulatory flexibility**: Use Act on Specified Joint Real Estate Ventures–aligned business and system as a base for other RWAs (legal judgment separate).
- **Competitive examples**: Cross-asset flexibility, **on-chain distribution**, domestic UX via **JPY deposits + Web3**.

### 3.4 Examples and Use Cases

1. **Retail investors**
   Invest small amounts in real estate, precious metals, etc. Select products and receive interest as NFTs. Clear distribution schedules improve visibility of expected returns.

2. **Corporate fundraising**
   Crowdfund project capital and distribute part of returns to NFT holders. Transparent progress and returns build trust.

---

## 4. Out of Scope and Policy (Clarified in This Document)

| Item | Policy |
|------|--------|
| **KYC** | **KYC is not mandatory** as a business requirement. **On-chain**, implementations may require **purchase eligibility per product (e.g., SBT tier)** (see “Gap vs. implementation” below). |
| **NFT trading** | **Open-market** NFT trading is **allowed** (marketplace out of this repo; contracts allow standard transfers). |
| **Early redemption** | **No** special relief such as **mid-term repayment** from the operator or **NFT return** (maturity processing per contract is the rule). |
| **Cumulative dividends (CAMEL, etc.)** | **No** accrual to pre-transfer holders; **only holders at distribution time** are eligible. |

---

## 5. Functional Requirements (Detail)

### 5.1 Investment via ERC20 (direct subscription)

- Use a designated **ERC20** (implementation-configurable `USDT_ADDRESS`); investors **subscribe** after `approve`.
- **Investment amount = minimum investment × units** (product master `minInvestment` × `unitCount`).
- **Mint NFT** to the investor wallet per subscription and record **investment amount** on the NFT.

### 5.2 Subscription tied to JPY deposits (off-chain deposit + on-chain reflection)

- JPY actually settles off-chain; **on contract**, administrators **credit the same ERC20 pool** (e.g., `deposit`) and combine with **investor-targeted `mintNFT`** so **subscription balance and NFTs** align—a **two-step** model (frontend/ops procedures may be defined separately).

### 5.3 ERC20 withdrawals (operations)

- **Investor interest and principal** are delivered by **sending USDT to investor wallets** in **distribution** and **maturity** flows.
- **Withdrawals from the product pool** (business use, treasury, etc.) are defined as **admin** actions sending to **multisig or other safe destinations** (implementation: `withdraw`).

### 5.4 NFT issuance

- Bind one **ERC721** contract per product (this repo: `InvestmentNFT`).
- NFTs represent **rights to receive distributions**, not the asset itself.
- Store **investment amount** on the NFT and tie to **product ID**.

### 5.5 Profit distribution

- Per **preconfigured** schedule, administrators run **distribution** (fully automated cron optional: `Automation`, etc.).
- **Units and amounts** per investor are tracked on NFTs; send ERC20 **proportionally** to **holders at distribution time**.
- **On USDT transfer failure** (e.g., blacklist): accrue yield to **`tokenId`-keyed escrow**, batch continues; current **NFT owner** may `claimYield` (`YieldTransferFailed` + getters).
- If an **NFT is transferred**, the **new holder** receives subsequent distributions and may claim escrow; **no retroactive distribution** to past holders (no CAMEL).
- **Distribution timing**: Support settings biased toward **multiple times from operations start through pre-maturity** and/or **lump sum at maturity**. Implementation may use `distributionStartDate`, `distributionInterval`, `totalDistributionCount`, `isMonthEnd`, etc.

### 5.6 Maturity processing

- After maturity, repay **outstanding principal** in **ERC20** to **NFT holders** and **burn** NFTs.
- **On transfer failure**: escrow principal, **defer burn**; current owner `claimPrincipal` (`PrincipalTransferFailed`).
- Enforce **ordering** (e.g., reject maturity if distribution counts are incomplete) (implemented).

### 5.7 Administration

- **Register and update** investment products (raise cap, minimum investment, subscription end, maturity, expected yield, operations start, distribution start, count/interval, metadata URI, required tier, etc.).
- **Getters and events** for views/dashboards (combined with off-chain aggregation).

---

## 6. Frontend Composition (Requirements)

### 6.1 Investor-facing

| Screen | Purpose | Main content |
|--------|---------|----------------|
| Product list / detail | Present products and decision inputs | Amount, maturity, yield, remaining units, etc. |
| Subscription (USDT) | On-chain subscription | Wallet connect, amount (units), `invest` / allowance |
| Subscription (JPY) | Off-chain deposit request | Amount, bank instructions, customer and wallet info |

### 6.2 Administrator-facing

| Screen | Purpose | Main content |
|--------|---------|----------------|
| Product registration / admin | Master data and lifecycle | Forms, progress, maturity (repayment, burn) |
| Deposit request admin | JPY deposit and on-chain reflection | Deposit confirmation, approval, `deposit` / `mintNFT` |
| Distribution admin | Accuracy and audit trail | Distribution history, transactions |
| System monitoring | Audit | NFT issuance history, anomalous transactions |

---

## 7. Non-Functional Requirements (Summary)

- **Transparency**: Major state changes, distributions, and maturity are traceable via events and on-chain state.
- **Security**: Combine admin actions with **allowlists**, **multisig withdrawal destinations**, etc. (see `Security-Risks.md` and multisig design).
- **Operational clarity**: **Preconditions** for invest, distribute, and maturity (time, balance, counts) return clear errors.

---

## 9. Change History

| Date | Description |
|------|-------------|
| 2024-12-01 | First edition |
