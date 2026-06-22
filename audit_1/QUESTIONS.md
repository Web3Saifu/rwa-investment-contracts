# Pre-Audit Questionnaire - RWA Investment Contracts

Answers inferred from repository evidence on 2026-06-21. Unknown deployment and organizational facts remain explicitly unknown.

| Question | Answer |
|---|---|
| Project type | RWA yield/investment protocol with transferable ERC721 positions |
| Blockchain/framework | EVM, Solidity 0.8.28, Foundry, MC modular proxy |
| Backend/frontend/database | None in scope |
| Deployment status / TVL | Unknown |
| Upgradeability | Yes; MC Dictionary ownership is transferred to the configured Safe multisig by the deploy script |
| Source availability | Repository source available locally |
| Roles | Safe owner, admins, minters, investors, Chainlink forwarder |
| User funds | USDT-like ERC20 deposits, yield, principal, and escrow liabilities |
| External integrations | USDT, ERC721/ERC1155 tier SBTs, Chainlink Automation |
| Prior security work | Audit PDF plus remediation documents and regression tests under `docs/audit/fix/` and `test/fix/` |
| CI/tests | GitHub Actions workflow exists but is `workflow_dispatch` only; Foundry unit, fuzz-style, regression, and scenario tests exist |
| Audit focus | FULL repository audit, with deep attention to contract business logic and lifecycle accounting |
| Report format | Markdown |
| Exclusions | Third-party `lib/` source is dependency evidence, not first-party line-by-line scope; AUDITOR's own files are audit tooling |

