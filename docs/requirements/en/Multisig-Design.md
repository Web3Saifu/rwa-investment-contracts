# Multisig Design Requirements (Safe)

---

## 1. Design Objectives

| Objective | Description |
|-----------|-------------|
| **Stronger security** | Reduce risk from unauthorized access or key loss by not relying on a single private key. |
| **Shared custody** | Introduce multi-party approval to strengthen organizational governance. |
| **Flexible asset management** | Safely manage ownership of tokens, NFTs, and smart contracts. |

---

## 2. System Overview

1. **Create a multisig wallet**  
   Use Safe to create a wallet with multiple owners and an approval threshold.

2. **Manage assets and contracts**  
   Handle withdrawals and smart contract upgrades through the wallet.

3. **Approval workflow**  
   Clarify propose, approve, and execute steps.

---

## 3. Key Components

### 3.1 Owners

| Item | Content |
|------|---------|
| **Role** | As wallet administrators, propose and approve transactions. |
| **Count** | Recommend at least three owners, balancing security and usability. |
| **Key management** | Each owner secures their private key; use hardware wallets where possible. |

### 3.2 Approval Threshold

| Item | Content |
|------|---------|
| **Configuration** | Set minimum approvals (M-of-N) required to execute a transaction. |
| **Recommendations** | Choose majority (e.g., 2 of 3) or unanimous, per organizational policy. |

### 3.3 Transaction Flow

1. **Propose** — One owner proposes a transaction.  
2. **Notify** — Other owners are notified.  
3. **Approve** — Others review and approve or reject.  
4. **Execute** — When enough approvals are collected, execute the transaction.

### 3.4 Asset and Contract Scope

| Type | Examples |
|------|----------|
| **ERC20 tokens** | ETH, USDT, custom tokens. |
| **ERC721 / 1155** | NFTs, in-game items. |
| **Smart contracts** | Admin rights for upgradeable contracts. |

---

## 4. Design Details

### 4.1 Wallet Creation

**Deploy a Safe instance**

- Create a new wallet using the official Safe web app ([https://safe.global/](https://safe.global/)).  
- Select the network (Mainnet, Testnet, etc.).

**Add owners**

- Enter each owner’s Ethereum address.  
- Prefer hardware or high-security wallets.

**Set approval threshold**

- Set required approvals per organizational policy.

### 4.2 Asset Migration

**Transfer assets**

- Send assets from existing wallets to the Safe.

**Transfer contract ownership**

- Point smart contract ownership to the Safe address.

### 4.3 Transaction Management

| Phase | Content |
|-------|---------|
| **Propose** | An owner creates a new transaction in the Safe UI. |
| **Approve** | Others are notified and approve or reject in the UI. |
| **Execute** | When the threshold is met, the transaction can be executed. |

### 4.4 Upgradeable Contracts

**Delegate upgrade authority**

- Set the contract’s upgrade admin to the Safe.

**Upgrade procedure**

1. Deploy the new implementation  
2. Create an upgrade proposal  
3. Propose a transaction to point the proxy to the new implementation  
4. Approve and execute with owner approvals  

---

## 5. Security Considerations

### 5.1 Key Management

- Each owner secures private keys.  
- Prefer hardware wallets and offline backups.

### 5.2 Owner Selection

| Aspect | Content |
|--------|---------|
| **Trust** | Choose trusted members. |
| **Diversity** | Include members in different locations or teams to spread risk. |

### 5.3 Transaction Verification

| Aspect | Content |
|--------|---------|
| **Content review** | Each owner reviews proposed transaction data in detail. |
| **Tools** | Use decoders, simulators, and similar tools. |

### 5.4 Contract Audits

| Aspect | Content |
|--------|---------|
| **Pre-upgrade audit** | Subject upgraded contract code to third-party security review. |
| **Periodic review** | Revisit contracts and operations against current security practice. |

---

## 6. Operations and Governance

### 6.1 Governance Model

- **Decision process** — Document steps from proposal to approval.  
- **Policies** — Define use of funds, limits, and emergency response.

### 6.2 Adding and Removing Owners

- **Process** — Clarify how to add or remove owners.  
- **Approvals** — Require multisig approval for owner changes.

### 6.3 Emergency Response

- **Backup owners** — Designate backups for contingencies.  
- **Contact channels** — Ensure fast communication between owners.

---

## 7. Implementation Steps

| Order | Content |
|-------|---------|
| 1 | **Requirements** — Clarify owner count, threshold, assets, and contracts. |
| 2 | **Safe setup** — Create the Safe and configure owners. |
| 3 | **Migration** — Move assets and contract ownership. |
| 4 | **Testing** — Validate flows on a testnet. |
| 5 | **Security audit** — Third-party review of configuration and process. |
| 6 | **Production** — Go live on Mainnet. |

---

## 8. Testing and Verification

**Testnet simulation**

- Validate all functions on testnets (e.g., Sepolia; note: historic names like Ropsten/Goerli may be deprecated).

**Scenario testing**

- Cover normal and failure scenarios.

**User training**

- Train owner teams on procedures.

---

## 9. Documentation and Support

| Item | Content |
|------|---------|
| **Runbooks** | Owner procedure manuals. |
| **FAQ** | Common questions and answers. |
| **Support** | Contacts and escalation for incidents. |
