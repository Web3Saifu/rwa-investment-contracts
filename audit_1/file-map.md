# Repository File Map

**Audited commit:** `90b5c86157afd4d433bfa7e5b6d9c76bfa663a75`

| Area | Files | Security role |
|---|---|---|
| Shared state | `src/investment/storage/{Schema,Storage}.sol` | Product, role, tier, config, and escrow storage |
| Public value flow | `Invest.sol`, `Claim.sol` | USDT subscription and failed-transfer recovery |
| Minter flow | `onlyMinters/{OnlyMintersBase,MintNFT}.sol` | Off-chain JPY-backed NFT issuance |
| Admin lifecycle | `onlyWhiteLists/{RegisterProduct,Deposit,Withdraw,DistributeYield,Maturity,SetTier}.sol` | Product setup, funding, payouts, maturity, and eligibility |
| Safe role control | `onlyOwner/{OnlyOwnerBase,ControlAdmin,ControlMinter}.sol` | Admin/minter list management |
| Math and integrations | `utils/{CalculateYieldLib,DistributionDateLib,PurchasePermissionLib,UsdtTransferLib}.sol` | Yield/date math, SBT checks, low-level USDT transfer |
| Periphery | `periphery/{InvestmentNFT,Automation}.sol` | ERC721 position and Chainlink upkeep router |
| Upgrade/deployment | `script/deploy/*.sol`, `mc.toml`, `foundry.toml` | MC facet wiring, initialization, Safe ownership transfer |
| Tests | Embedded `// Testing` contracts, `test/investment/`, `test/fix/`, `test/audit/` | Unit, fuzz-style, scenario, regression, and audit PoCs |
| Operations | `.github/workflows/test.yml`, `.env.example`, `.env.sample`, `.gitignore` | CI and deployment configuration |

## Critical State Transitions

`registerProduct -> invest/mintNFT -> deposit/withdraw -> distributeYield -> maturity -> claimYield/claimPrincipal`

## Key Invariants

1. Product pool debits must equal pushed or escrowed liabilities.
2. Only the current NFT owner may receive or claim position value.
3. Burning an NFT must leave no associated claim that depends on `ownerOf`.
4. Distribution dates must be ordered before maturity under the same timestamp representation.
5. Revoking a role must make its authorization predicate false.

