# AUDITOR Full Security Audit Report

## Executive Summary

**Repository:** rwa-investment-contracts  
**Commit:** 90b5c86157afd4d433bfa7e5b6d9c76bfa663a75  
**Date:** 2026-06-21  
**Scope:** FULL repository, Solidity/EVM production code plus repository security controls  
**Repository Risk Score:** 6 - MEDIUM

The audit confirmed three contract-level issues with executable PoCs: persistent minter authorization after revocation, inconsistent raw/normalized schedule validation, and tier-wide purchase DoS from a reverting SBT. No permissionless direct-drain path was confirmed. All 283 Foundry tests pass, including the three audit PoCs; this means the PoCs demonstrate reachable behavior rather than regressions in the existing suite.

### Severity Distribution

| Score | Count |
|---:|---:|
| 6 | 1 |
| 5 | 2 |
| 4 | 1 |
| 3 | 3 |
| **Total findings** | **7** |

### Items Verified

| Metric | Count |
|---|---:|
| Total checklist items | 1182 |
| PASS | 48 |
| FAIL | 15 |
| PARTIAL | 170 |
| N/A | 949 |
| Completion | 100% verdict coverage |

## Corpus Coverage

| AUDITOR file | Loaded |
|---|---|
| checklists/01-program-account-validation.md | Yes |
| checklists/02-program-access-control.md | Yes |
| checklists/03-program-arithmetic-safety.md | Yes |
| checklists/04-program-cpi-pda.md | Yes |
| checklists/05-program-state-machine.md | Yes |
| checklists/06-program-economic-logic.md | Yes |
| checklists/07-program-opsec-governance.md | Yes |
| checklists/08-typescript-safety.md | Yes |
| checklists/09-backend-security.md | Yes |
| checklists/10-frontend-security.md | Yes |
| checklists/11-supply-chain.md | Yes |
| checklists/12-secrets-opsec.md | Yes |
| checklists/13-deployment-infrastructure.md | Yes |
| checklists/14-python-safety.md | Yes |
| checklists/15-general-language-safety.md | Yes |
| checklists/16-formal-verification-testing.md | Yes |
| checklists/17-logging-monitoring-incident-response.md | Yes |
| checklists/18-privacy-compliance-change-management.md | Yes |
| CORPUS-MANIFEST.md | Yes |
| COSTS.md | Yes |
| discovery/file-map.md | Yes |
| discovery/grep-commands.md | Yes |
| FULL-AUDIT.md | Yes |
| known-vectors/001-private-key-leak.md | Yes |
| known-vectors/002-flash-loan-price-manipulation.md | Yes |
| known-vectors/003-reentrancy-cpi.md | Yes |
| known-vectors/004-missing-access-control.md | Yes |
| known-vectors/005-oracle-manipulation.md | Yes |
| known-vectors/006-first-depositor-share-inflation.md | Yes |
| known-vectors/007-mev-sandwich-attack.md | Yes |
| known-vectors/008-rug-pull-admin-backdoor.md | Yes |
| known-vectors/009-unchecked-cpi-target.md | Yes |
| known-vectors/010-pda-confusion-type-cosplay.md | Yes |
| known-vectors/011-integer-overflow-underflow.md | Yes |
| known-vectors/012-arithmetic-rounding-exploit.md | Yes |
| known-vectors/013-missing-signer-check.md | Yes |
| known-vectors/014-account-reinitialization.md | Yes |
| known-vectors/015-unchecked-account-owner.md | Yes |
| known-vectors/016-token-account-mismatch.md | Yes |
| known-vectors/017-vault-donation-attack.md | Yes |
| known-vectors/018-fee-on-transfer-token-exploit.md | Yes |
| known-vectors/019-freeze-authority-griefing.md | Yes |
| known-vectors/020-program-upgrade-hijack.md | Yes |
| known-vectors/021-governance-attack-vote-buying.md | Yes |
| known-vectors/022-bridge-exploit-fake-proof.md | Yes |
| known-vectors/023-token-2022-transfer-hook-attack.md | Yes |
| known-vectors/024-stale-missing-account-close.md | Yes |
| known-vectors/025-compute-budget-exhaustion-dos.md | Yes |
| known-vectors/026-pda-seed-collision.md | Yes |
| known-vectors/027-missing-discriminator-check.md | Yes |
| known-vectors/028-front-running-transaction.md | Yes |
| known-vectors/029-withdraw-before-update-race.md | Yes |
| known-vectors/030-infinite-mint-uncapped-supply.md | Yes |
| known-vectors/031-nosql-injection-mongodb.md | Yes |
| known-vectors/032-sql-injection.md | Yes |
| known-vectors/033-mass-assignment-vibe-coding.md | Yes |
| known-vectors/034-baas-auth-bypass-supabase-firebase.md | Yes |
| known-vectors/035-jwt-algorithm-confusion.md | Yes |
| known-vectors/036-ssrf-server-side-request-forgery.md | Yes |
| known-vectors/037-cors-misconfiguration.md | Yes |
| known-vectors/038-idor-insecure-direct-object-reference.md | Yes |
| known-vectors/039-rate-limiting-bypass.md | Yes |
| known-vectors/040-command-injection.md | Yes |
| known-vectors/041-path-traversal-lfi.md | Yes |
| known-vectors/042-xml-external-entity-xxe.md | Yes |
| known-vectors/043-prototype-pollution.md | Yes |
| known-vectors/044-server-side-template-injection.md | Yes |
| known-vectors/045-webhook-forgery.md | Yes |
| known-vectors/046-graphql-introspection-depth-attack.md | Yes |
| known-vectors/047-websocket-hijacking.md | Yes |
| known-vectors/048-redos-regex-denial-of-service.md | Yes |
| known-vectors/049-http-response-splitting.md | Yes |
| known-vectors/050-session-fixation.md | Yes |
| known-vectors/051-account-enumeration.md | Yes |
| known-vectors/052-unbounded-request-body-dos.md | Yes |
| known-vectors/053-missing-wallet-signature-verification.md | Yes |
| known-vectors/054-default-credentials-in-production.md | Yes |
| known-vectors/055-exposed-debug-admin-endpoints.md | Yes |
| known-vectors/056-xss-via-svg-image-injection.md | Yes |
| known-vectors/057-stored-xss-user-content.md | Yes |
| known-vectors/058-dom-based-xss.md | Yes |
| known-vectors/059-clickjacking.md | Yes |
| known-vectors/060-oauth-state-forgery-csrf-via-oauth.md | Yes |
| known-vectors/061-sensitive-data-in-url-parameters.md | Yes |
| known-vectors/062-client-side-auth-bypass.md | Yes |
| known-vectors/063-postmessage-origin-bypass.md | Yes |
| known-vectors/064-localstorage-token-theft.md | Yes |
| known-vectors/065-clipboard-hijacking-crypto-address.md | Yes |
| known-vectors/066-css-exfiltration.md | Yes |
| known-vectors/067-wallet-blind-signing-exploit.md | Yes |
| known-vectors/068-subresource-integrity-bypass.md | Yes |
| known-vectors/069-third-party-script-compromise.md | Yes |
| known-vectors/070-open-redirect.md | Yes |
| known-vectors/071-missing-csp-content-security-policy.md | Yes |
| known-vectors/072-api-key-exposure-in-client-bundle.md | Yes |
| known-vectors/073-dangling-dns-subdomain-takeover.md | Yes |
| known-vectors/074-insecure-external-link-no-rel.md | Yes |
| known-vectors/075-console-data-leak-in-production.md | Yes |
| known-vectors/076-dependency-confusion-substitution-attack.md | Yes |
| known-vectors/077-malicious-npm-package-typosquatting.md | Yes |
| known-vectors/078-secrets-in-git-history.md | Yes |
| known-vectors/079-env-file-committed-to-repo.md | Yes |
| known-vectors/080-ci-cd-pipeline-injection.md | Yes |
| known-vectors/081-insecure-docker-configuration.md | Yes |
| known-vectors/082-exposed-admin-debug-endpoints-in-production.md | Yes |
| known-vectors/083-missing-rate-limiting-on-critical-endpoints.md | Yes |
| known-vectors/084-prototype-pollution.md | Yes |
| known-vectors/085-server-side-request-forgery-ssrf.md | Yes |
| known-vectors/086-insecure-deserialization.md | Yes |
| known-vectors/087-insufficient-logging-monitoring.md | Yes |
| known-vectors/088-insecure-cors-configuration.md | Yes |
| known-vectors/089-unpatched-server-dependencies.md | Yes |
| known-vectors/090-missing-https-tls-misconfiguration.md | Yes |
| known-vectors/091-upgrade-authority-not-secured.md | Yes |
| known-vectors/092-dns-hijacking-domain-takeover.md | Yes |
| known-vectors/093-improper-error-handling-error-leak.md | Yes |
| known-vectors/094-missing-input-length-limits.md | Yes |
| known-vectors/095-insecure-randomness.md | Yes |
| known-vectors/096-missing-security-headers.md | Yes |
| known-vectors/097-stale-leaked-development-credentials.md | Yes |
| known-vectors/098-broken-access-control-on-api-endpoints.md | Yes |
| known-vectors/099-insecure-websocket-connections.md | Yes |
| known-vectors/100-insufficient-backup-disaster-recovery.md | Yes |
| known-vectors/INDEX.md | Yes |
| OUTPUT-RULES.md | Yes |
| QUESTIONS.md | Yes |
| README.md | Yes |
| SKILL.md | Yes |
| templates/instruction-worksheet.md | Yes |
| templates/report-template.md | Yes |
| TOP-100-HACKS.md | Yes |

Corpus verification: 131 markdown files, 11,189 lines, zero read failures. This includes INDEX.md and KV-001 through KV-100.

## Scope & Methodology

- Read every first-party production Solidity file before embedded `// Testing` sections, then reviewed tests, scripts, configs, prior remediation docs, and dependency pins.
- Traced role, product, pool, escrow, NFT, distribution cursor, and maturity state transitions.
- Ran source/history secret scans, CI/config review, npm audit, Foundry full tests, format check, and both Foundry coverage modes.
- Applied checklist 15 to Solidity and always-on checklists 11-13 and 16-18. Solana, backend, frontend, TypeScript, and Python-only items are individually marked N/A.
- Existing X-Ray and prior fixes were orientation and duplicate filters, not proof. Findings below are supported by current source and new PoCs.

## Findings

### [F-001] Duplicate initial minters survive revocation

| Field | Value |
|---|---|
| Severity | 6 - MEDIUM |
| Checklist/vector | GL-014, KV-004 |
| Location | `Initialize.sol:35`, `ControlMinter.sol:36`, `OnlyMintersBase.sol:15` |
| PoC | `test/audit/AUDITOR_DuplicateInitialMinter.t.sol` |

**Description:** Initialization rejects duplicate admins but pushes minters without duplicate or maximum-count validation. `deleteMinter` removes only the first matching array element, while `onlyMinters` authorizes if any duplicate remains.

**Impact:** A Safe can emit a successful `MinterRemoved` event yet the address remains able to call `mintNFT`, creating unfunded economic positions up to product offering limits. This requires a duplicate deployment configuration, so it is not permissionless.

**Evidence:** `test_duplicateInitialMinterSurvivesRevocation()` passes and calls a minter-restricted selector after revocation.

**Recommendation:** Apply the same duplicate check and 255-entry cap used for admins/addMinter during initialization. Consider deleting all matches defensively or replacing arrays with membership mappings.

### [F-002] Midnight normalization bypasses lifecycle ordering

| Field | Value |
|---|---|
| Severity | 5 - MEDIUM |
| Checklist/vector | GL-001 |
| Location | `RegisterProduct.sol:66-86`, `DistributionDateLib.sol:27-29` |
| PoC | `test/audit/AUDITOR_NormalizedScheduleBypass.t.sol` |

**Description:** Raw `operationStartDate` and `distributionStartDate` are ordered, but the final distribution check compares maturity to a date floored to midnight. Non-midnight inputs can therefore have maturity before both operation and raw distribution start while registration succeeds.

**Impact:** Yield can become callable before operation begins and can accrue over a raw first period extending beyond maturity. The over-accrual is bounded by the within-day normalization gap but violates product economics and temporal invariants.

**Evidence:** The PoC registers maturity at 01:00, operation at 22:00, and distribution at 23:00 on the same day; effective distribution becomes 00:00 and all assertions pass.

**Recommendation:** Require all lifecycle inputs to be normalized midnight values, or perform every ordering/yield calculation using one canonical normalized representation while explicitly requiring `operationStartDate <= maturityDate` and raw/effective distribution <= maturity.

### [F-003] Reverting tier dependency blocks all valid investors

| Field | Value |
|---|---|
| Severity | 5 - MEDIUM |
| Checklist/vector | FV-047, KV-025 |
| Location | `SetTier.sol:17-33`, `PurchasePermissionLib.sol:49-55` |
| PoC | `test/audit/AUDITOR_RevertingTierSBT.t.sol` |

**Description:** Tier registration checks only nonzero code length. Runtime eligibility directly calls `IERC165.supportsInterface`; a revert aborts the loop before later valid SBTs are checked.

**Impact:** A misconfigured, unavailable, malicious, or upgraded SBT can temporarily deny every `invest` call for products using that tier. Admins can recover by replacing the registry entry, so funds are not permanently locked.

**Evidence:** The PoC registers a reverting contract before a valid ERC721 held by the investor; eligibility reverts with `SBT unavailable`.

**Recommendation:** Validate ERC165/ERC721/ERC1155 support at registration and wrap runtime interface/balance probes in `try/catch`, treating failed probes as false so later entries remain reachable.

### [F-004] CI does not gate changes and actions are not immutably pinned

| Field | Value |
|---|---|
| Severity | 4 - LOW |
| Checklist/vector | DEP-060, DEP-067, FV-040, PC-031, KV-080 |
| Location | `.github/workflows/test.yml:3-20` |

**Description:** The only workflow uses `workflow_dispatch`, so pushes and pull requests are not automatically tested. Actions use mutable major tags rather than commit SHAs.

**Impact:** Regressions can merge without test execution, and upstream tag movement expands supply-chain trust. This is a repository-process weakness, not an on-chain exploit by itself.

**Recommendation:** Add `pull_request` and protected-branch `push` triggers, require the check in branch protection, and pin actions to reviewed commit SHAs.

### Informational / hardening findings

- **F-005 (3):** `.gitignore` lacks broad key/certificate patterns even though current/history scans are clean.
- **F-006 (3):** No emergency pause/circuit-breaker exists; document whether Safe upgrades are the intended emergency mechanism.
- **F-007 (3):** No changelog or repository incident-response runbook was found.

## Detailed Item Results

### Checklist 1: 01-program-account-validation.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| AV-001 | [N/A] | Every account deserialized from AccountInfo has its owner field validated against the expected program ID | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-002 | [N/A] | No account in #[derive(Accounts)] uses raw AccountInfo<'info> (deprecated in Anchor 1.0)  must use UncheckedAccount<'info> or typed Account<'info, T> | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-003 | [N/A] | Every UncheckedAccount<'info> has a /// CHECK: doc comment that describes the ACTUAL runtime validation performed (not just "safe because...") | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-004 | [N/A] | Every /// CHECK: comment corresponds to real code  grep for the validation logic referenced in the comment | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-005 | [N/A] | Accounts typed as Account<'info, T> automatically check owner + discriminator  verify T matches the expected state struct | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-006 | [N/A] | Token accounts use Account<'info, TokenAccount> or InterfaceAccount<'info, TokenAccount>  never raw AccountInfo | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-007 | [N/A] | Mint accounts use Account<'info, Mint>  never raw AccountInfo | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-008 | [N/A] | System program, token program, rent sysvar are typed with Program<'info, System>, Program<'info, Token>, Sysvar<'info, Rent>  not AccountInfo | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-009 | [N/A] | No account marked as Account<'info, T> where T is a different program's state struct without explicit owner override | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-010 | [N/A] | The program ID declared in declare_id!() matches the deployed program ID and the keypair file | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-011 | [N/A] | Every on-chain account uses Anchor's 8-byte discriminator (automatic with #[account] macro)  check no manual serialization bypasses it | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-012 | [N/A] | No instruction accepts an account typed as struct A where struct B has the same memory layout prefix (type cosplay attack) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-013 | [N/A] | If remaining_accounts are deserialized manually, verify discriminator is checked (e.g., AccountDeserialize::try_deserialize()) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-014 | [N/A] | If remaining_accounts are deserialized, verify the account address matches the expected PDA derivation  discriminator checks alone are insufficient | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-015 | [N/A] | No account struct reuses the first 8 bytes of another account struct's discriminator (collision check) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-016 | [N/A] | Account structs use #[account] attribute (not manual BorshSerialize/BorshDeserialize without discriminator) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-017 | [N/A] | If accounts are migrated between versions, old discriminators cannot be confused with new ones | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-018 | [N/A] | Every account that should be mutable is marked #[account(mut)] | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-019 | [N/A] | No account is marked #[account(mut)] when it should be read-only (unnecessary mutability) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-020 | [N/A] | has_one = field constraints are used on accounts that reference other accounts (e.g., has_one = manager, has_one = fund) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-021 | [N/A] | has_one constraints are ALSO backed by runtime require_keys_eq! checks (defense-in-depth) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-022 | [N/A] | init accounts use payer, space, and seeds + bump correctly | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-023 | [N/A] | init_if_needed is NOT used unless explicitly required  it opens reinitialization vectors | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-024 | [N/A] | If init_if_needed IS used, there is a guard against reinitialization (e.g., checking a version/initialized flag) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-025 | [N/A] | close = destination constraints send lamports to the correct recipient  check destination is constrained | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-026 | [N/A] | Closed accounts have their data zeroed (Anchor does this automatically with close, verify no manual close bypasses it) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-027 | [N/A] | seeds constraints use all necessary seed components (prevent PDA collision across different entities) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-028 | [N/A] | bump values are stored in state and reused (bump = account.bump)  not re-derived every time | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-029 | [N/A] | constraint = <expr> custom constraints use proper error types, not generic ConstraintRaw | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-030 | [N/A] | realloc constraints include realloc::payer and realloc::zero appropriately | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-031 | [N/A] | No duplicate mutable accounts without explicit #[account(mut, dup)] opt-in (Anchor 1.0 rejects by default) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-032 | [N/A] | All remaining_accounts are iterated and validated before use  no blind pass-through | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-033 | [N/A] | For each remaining account, owner is verified (account.owner == expected_program) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-034 | [N/A] | For each remaining account used as a token account, mint and authority are verified | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-035 | [N/A] | For each remaining account used as a PDA, the address is re-derived and compared | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-036 | [N/A] | The count of remaining_accounts is validated (not more or fewer than expected) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-037 | [N/A] | Remaining accounts passed to external CPI (e.g., Jupiter) are at minimum program-ownership validated | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-038 | [N/A] | No remaining account can be the same as a named account in the struct (duplicate account confusion) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-039 | [N/A] | If remaining accounts represent investor positions, each position's fund field matches the current fund | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-040 | [N/A] | All init accounts allocate sufficient space  calculate manually: 8 (discriminator) + each field size | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-041 | [N/A] | No account can be created with less than rent-exempt minimum lamports | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-042 | [N/A] | Variable-length fields (Vec, String) in account structs have a maximum length enforced | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-043 | [N/A] | realloc operations check the new size doesn't exceed the maximum allowed account size (10 MB) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-044 | [N/A] | No instruction allows reducing account size below the minimum required for its data | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-045 | [N/A] | Every token account used in transfers has its mint field validated against expected mint | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-046 | [N/A] | Every token account used in transfers has its owner/authority field validated | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-047 | [N/A] | Vault token accounts are verified as owned by the expected PDA (fund PDA) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-048 | [N/A] | Associated Token Accounts are derived correctly  getAssociatedTokenAddressSync or associated_token:: seed derivation | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-049 | [N/A] | Token accounts with delegate field  verify delegate authorization before using delegated_amount | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-050 | [N/A] | Token accounts are checked for frozen state if freeze authority exists | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-051 | [N/A] | WSOL (wrapped SOL) accounts use the correct native mint address (So11111111111111111111111111111111111111112) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-052 | [N/A] | Token-2022 accounts are not confused with original Token Program accounts (different program IDs) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-053 | [N/A] | No instruction can re-initialize an already-initialized account (check init vs init_if_needed) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-054 | [N/A] | If manual initialization is used (not Anchor init), an is_initialized flag is checked | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-055 | [N/A] | After account closure, the same PDA seeds cannot be re-derived to create a new account with stale associations | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-056 | [N/A] | Revival attack: after close, can an attacker send lamports to the closed account address to prevent garbage collection and re-use stale data? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AV-057 | [N/A] | If an account is closed mid-transaction, subsequent instructions in the same transaction cannot access stale data from that account | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |

### Checklist 2: 02-program-access-control.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| AC-001 | [N/A] | Every instruction that moves tokens, SOL, or lamports has at least one Signer<'info> in its accounts struct | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-002 | [N/A] | Every instruction that modifies on-chain state has at least one Signer<'info>  no permissionless state mutation | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-003 | [N/A] | The signer's pubkey is linked to a state field via has_one (e.g., has_one = manager on Fund account) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-004 | [N/A] | No instruction relies solely on passing an account as AccountInfo and checking is_signer manually (prefer Anchor Signer<'info>) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-005 | [N/A] | If manual is_signer check is used, it's a hard require!(account.is_signer, Error), not an if-else that silently skips | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-006 | [N/A] | Admin/manager instructions: manager: Signer<'info> AND fund: Account<'info, Fund> with has_one = manager | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-007 | [N/A] | Investor instructions: investor: Signer<'info> AND position/withdrawal with has_one = investor | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-008 | [N/A] | Delegate instructions: delegate signer is validated against token_account.delegate == Some(delegate.key()) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-009 | [N/A] | No instruction allows a third party to act on behalf of a signer without explicit delegation mechanism | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-010 | [N/A] | There is no instruction callable by anyone (permissionless) that can move value  if one exists, document why | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-011 | [N/A] | List all roles in the program (manager, investor, delegate, admin, anyone) and map each instruction to exactly one role | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-012 | [N/A] | No instruction has ambiguous role  "manager OR investor" must be explicitly documented and justified | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-013 | [N/A] | Role escalation: can a non-manager call a manager instruction by spoofing accounts? Verify each manager instruction | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-014 | [N/A] | Role escalation: can a non-investor call an investor instruction by spoofing position accounts? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-015 | [N/A] | Admin role (if exists): how is admin defined? Hardcoded pubkey? Program authority? Multisig? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-016 | [N/A] | If admin role exists, what can admin do? Can admin drain funds? Can admin pause/unpause? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-017 | [N/A] | Is there a "superadmin" or "god mode" that bypasses all checks? Document and flag | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-018 | [N/A] | Fund manager cannot impersonate an investor (manager key  investor key check if needed) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-019 | [N/A] | Investor cannot impersonate the manager (investor key  manager key for manager-only operations) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-020 | [N/A] | Manager can only operate on their own fund (not another manager's fund) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-021 | [N/A] | Investor can only operate on their own position (not another investor's position) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-022 | [N/A] | Manager cannot directly withdraw investor funds (only through fee mechanism) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-023 | [N/A] | Manager fee percentage has a maximum cap enforced on-chain | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-024 | [N/A] | Manager cannot change fee after fund creation (or changes are time-locked) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-025 | [N/A] | Treasury address is validated on every fee transfer  cannot be changed to attacker-controlled address | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-026 | [N/A] | Treasury address is hardcoded or stored in an immutable configuration  not a mutable field | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-027 | [N/A] | Platform fee minimum is enforced (admin_fee >= minimum)  manager cannot set it to zero | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-028 | [N/A] | No instruction allows transferring fund PDA ownership from one manager to another without governance | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-029 | [N/A] | Whitelist management (if exists)  only authorized role can add/remove programs | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-030 | [N/A] | Is there a pause mechanism? (fund.paused flag or similar) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-031 | [N/A] | If pause exists, who can trigger it? (Should be restricted to manager/admin) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-032 | [N/A] | If pause exists, does it actually prevent all value-moving operations? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-033 | [N/A] | If pause exists, can manager still withdraw their own fees while paused? (Should they?) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-034 | [N/A] | If pause exists, can investors still withdraw while paused? (Should they  emergency exit?) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-035 | [N/A] | If NO pause mechanism exists  flag as LOW/MEDIUM finding (no emergency stop) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-036 | [N/A] | Can the program be frozen by Solana (freeze authority on mint)? Is freeze authority set? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-037 | [N/A] | Shares mint  who is the mint authority? Is it the fund PDA? Can anyone else mint shares? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-038 | [N/A] | Shares mint  is there a freeze authority? If yes, who controls it? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-039 | [N/A] | Can an attacker front-run an account creation to claim the PDA first? (Seed collision with attacker-controlled data) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-040 | [N/A] | Can an attacker create a position in a fund that doesn't accept their wallet? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-041 | [N/A] | Can an attacker block withdrawals by manipulating shared state? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-042 | [N/A] | Can an attacker force-close another user's accounts? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-043 | [N/A] | Can an attacker trigger instructions on behalf of other users by replaying old transactions? (Solana inherently prevents this via recent_blockhash, but check off-chain replay) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-044 | [N/A] | Rate limiting: are there any on-chain rate limits (cooldown periods, minimum intervals)? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-045 | [N/A] | Can an attacker spam init instructions to fill up PDA space or exhaust payer's SOL? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-046 | [N/A] | In multi-instruction transactions, can instruction N's authority context be exploited by instruction N+1? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-047 | [N/A] | After an account is closed in instruction N, can instruction N+1 in the same transaction access the closed account's stale data? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-048 | [N/A] | CPI called programs  can they callback into the calling program with elevated privileges? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-049 | [N/A] | Re-entrancy: does the program guard against re-entrant calls? (Solana's runtime prevents direct re-entrancy but CPI callbacks can simulate it) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AC-050 | [N/A] | If program uses invoke_signed, verify the seeds cannot be guessed/replicated by another program | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |

### Checklist 3: 03-program-arithmetic-safety.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| AR-001 | [N/A] | Every + operation on state-derived or user-supplied values uses checked_add with .ok_or(Error)? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-002 | [N/A] | Every - operation on state-derived or user-supplied values uses checked_sub with .ok_or(Error)? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-003 | [N/A] | Every * operation on state-derived or user-supplied values uses checked_mul with .ok_or(Error)? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-004 | [N/A] | Every / operation on state-derived or user-supplied values uses checked_div with .ok_or(Error)? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-005 | [N/A] | No bare arithmetic operators (+, -, *, /, %) are used on financial values (grep the entire program for these) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-006 | [N/A] | No saturating_add, saturating_sub, saturating_mul on financial paths  these silently cap instead of failing | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-007 | [N/A] | No wrapping_add, wrapping_sub, wrapping_mul anywhere  these silently wrap | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-008 | [N/A] | Constants-only arithmetic (e.g., 8 + 32 + 32) is acceptable without checked_*  verify all operands are truly constant | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-009 | [N/A] | Anchor's space calculation in #[account(init, space = ...)]  bare arithmetic is OK here since values are known at compile time | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-010 | [N/A] | For a * b / c patterns, intermediate result a * b is computed in u128 to prevent overflow | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-011 | [N/A] | For share calculation (deposit * total_shares) / total_assets  uses u128 intermediate | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-012 | [N/A] | For fee calculation (amount * fee_bps) / 10000  uses u128 intermediate if amount can be large | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-013 | [N/A] | For proportion calculation (amount * fraction) / total  uses u128 intermediate | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-014 | [N/A] | After u128 computation, downcast to u64 using as u64 only after verifying the result fits (or use u64::try_from()) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-015 | [N/A] | No as u64 truncation on u128 values without checking if value > u64::MAX | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-016 | [N/A] | No as u32 truncation on u64 values without bounds checking | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-017 | [N/A] | No as i64 cast on u64 values that could exceed i64::MAX (sign flip vulnerability) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-018 | [N/A] | Every division operation checks that divisor is not zero (either via guard or checked_div) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-019 | [N/A] | For share pricing price = total_assets / total_shares  guard for total_shares == 0 case | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-020 | [N/A] | For withdrawal proportion fraction = investor_shares / total_shares  guard for total_shares == 0 | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-021 | [N/A] | Division that can truncate to 0 when it shouldn't  is there a minimum output requirement? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-022 | [N/A] | Integer division rounding direction  verify it rounds in favor of the protocol (not the user) for share minting | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-023 | [N/A] | Integer division rounding direction  verify it rounds in favor of the user (not the protocol) for share redemption | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-024 | [N/A] | Dust amount attacks: can an attacker exploit rounding by making many small deposits/withdrawals to accumulate rounding errors? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-025 | [N/A] | First depositor attack: if total_shares == 0, can first depositor manipulate initial share price? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-026 | [N/A] | Share minting formula: shares = deposit_amount * total_shares / total_assets  verify correctness | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-027 | [N/A] | Share minting when total_shares == 0 OR total_assets == 0  uses 1:1 ratio (or documented alternative) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-028 | [N/A] | Share burning formula: asset_return = burn_shares * total_assets / total_shares  verify correctness | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-029 | [N/A] | Slippage protection on mint: require!(shares_minted >= min_shares_out)  is this enforced? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-030 | [N/A] | Slippage protection on burn: require!(assets_returned >= min_assets_out)  is this enforced? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-031 | [N/A] | Inflation attack: can someone donate tokens to the vault to dilute share value for new depositors? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-032 | [N/A] | Deflation attack: can someone withdraw in a way that makes remaining shares worth less? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-033 | [N/A] | Total shares supply matches sum of all investor positions (invariant check) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-034 | [N/A] | Shares mint supply matches fund.total_shares (invariant check) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-035 | [N/A] | Management fee formula is correct and uses checked math | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-036 | [N/A] | Performance fee formula is correct and uses checked math | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-037 | [N/A] | Platform fee (treasury) formula is correct and uses checked math | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-038 | [N/A] | Fee split: manager_fee + platform_fee + investor_return == total_amount  no funds lost or created | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-039 | [N/A] | Fee basis points: verify fee_bps <= 10000 (100%)  no fee exceeding 100% | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-040 | [N/A] | Fee basis points minimum: verify minimum platform fee is enforced | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-041 | [N/A] | Fee calculation order: fees extracted before or after share calculation? Verify consistency | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-042 | [N/A] | Compound fee attack: can fees be charged on fees? (fee on withdrawal that includes previous fees) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-043 | [N/A] | Zero-value edge case: what happens when fee calculation yields 0? Is 0-amount transfer safe? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-044 | [N/A] | NAV calculation includes all token positions held by the fund PDA | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-045 | [N/A] | NAV calculation uses correct token decimals for each position | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-046 | [N/A] | NAV calculation handles zero-balance positions correctly | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-047 | [N/A] | NAV cannot be artificially inflated by the manager (attestation must be honest or verifiable) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-048 | [N/A] | NAV cannot be artificially deflated to steal from new depositors | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-049 | [N/A] | NAV attestation PDA is validated (address re-derived, not just discriminator checked) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-050 | [N/A] | Stale NAV: is there a timeout after which NAV attestation is considered stale? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-051 | [N/A] | All lamport values are treated as u64  no truncation to smaller types | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-052 | [N/A] | Lamport transfers check that source has sufficient balance: source.lamports() >= amount + rent_exempt_minimum | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-053 | [N/A] | After lamport manipulation, verify rent exemption is maintained for non-closeable accounts | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-054 | [N/A] | No instruction can drain an account below rent-exempt minimum without closing it | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-055 | [N/A] | WSOL handling: wrapping and unwrapping account for correct lamport  token conversion | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-056 | [N/A] | What happens with MAX u64 values as input? Does every path handle it? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-057 | [N/A] | What happens with 0 as amount input? Every deposit/withdraw/transfer/fee path | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-058 | [N/A] | What happens with 1 lamport/token as input? Minimum viable amounts | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-059 | [N/A] | What happens when fund has exactly 1 share remaining? Edge case in proportional math | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-060 | [N/A] | What happens when fund has maximum number of investors all withdrawing simultaneously? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| AR-061 | [N/A] | Timestamp arithmetic (if used): Clock::get()?.unix_timestamp is i64  check for negative/overflow issues | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |

### Checklist 4: 04-program-cpi-pda.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| CPI-001 | [N/A] | Every CpiContext::new() first argument is a Pubkey (Anchor 1.0), NOT .to_account_info() (Anchor 0.x pattern) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-002 | [N/A] | Every CpiContext::new_with_signer() first argument is a Pubkey (Anchor 1.0) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-003 | [N/A] | Every CPI to SPL Token Program  the token_program account is validated as spl_token::ID or Program<'info, Token> | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-004 | [N/A] | Every CPI to System Program  the system_program account is validated as system_program::ID or Program<'info, System> | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-005 | [N/A] | Every CPI to Associated Token Program  validated as associated_token::ID or typed Program<'info, AssociatedToken> | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-006 | [N/A] | Every CPI to a DEX aggregator (Jupiter, etc.)  program ID is validated via require_keys_eq! against hardcoded known ID | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-007 | [N/A] | Every CPI to Metaplex  program ID validated against hardcoded metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-008 | [N/A] | No CPI uses an UncheckedAccount as the program to invoke  the program account MUST be validated | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-009 | [N/A] | If remaining_accounts are passed through to a CPI, the target program ID is still validated | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-010 | [N/A] | For invoke_signed (raw Solana CPI), the program_id in the Instruction is validated before invocation | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-011 | [N/A] | token::transfer CPI  from account is the expected source (vault or user account) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-012 | [N/A] | token::transfer CPI  to account is the expected destination (not attacker-controlled) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-013 | [N/A] | token::transfer CPI  authority is the correct PDA or signer | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-014 | [N/A] | token::transfer CPI  amount is calculated correctly and matches expected value | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-015 | [N/A] | token::mint_to CPI  mint is the fund's shares mint (not an attacker-supplied mint) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-016 | [N/A] | token::mint_to CPI  to is the investor's correct token account | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-017 | [N/A] | token::mint_to CPI  authority is the fund PDA (mint authority) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-018 | [N/A] | token::mint_to CPI  amount matches calculated shares (not attacker-controlled) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-019 | [N/A] | token::burn CPI  from is the investor's token account with their shares | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-020 | [N/A] | token::burn CPI  authority is the investor (they authorized the burn) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-021 | [N/A] | token::burn CPI  amount matches the intended burn amount | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-022 | [N/A] | token::close_account CPI  destination is constrained to known recipients (fund PDA, investor, or treasury) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-023 | [N/A] | token::close_account CPI  authority is the correct entity | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-024 | [N/A] | token::close_account CPI  the closed account is NOT the main vault (catastrophic if vault is closed) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-025 | [N/A] | system_program::transfer CPI  source and destination are validated | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-026 | [N/A] | token::approve CPI  delegate and amount are validated, not granting unlimited approval | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| CPI-027 | [N/A] | token::revoke CPI  actually revokes the correct delegation | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| EXT-001 | [N/A] | Jupiter swap CPI  the fund PDA is the authority (signed with invoke_signed) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| EXT-002 | [N/A] | Jupiter swap CPI  slippage is enforced (either by Jupiter's internal mechanism or by post-CPI balance check) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| EXT-003 | [N/A] | Jupiter swap CPI  returned token account belongs to the fund PDA | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| EXT-004 | [N/A] | Jupiter swap CPI  remaining_accounts are passed correctly | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| EXT-005 | [N/A] | After Jupiter CPI  verify fund balances changed as expected (post-condition check) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| EXT-006 | [N/A] | Jupiter program ID is validated against known address each time | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| EXT-007 | [N/A] | Metaplex CPI (if used)  metadata account derived correctly | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| EXT-008 | [N/A] | Metaplex CPI (if used)  program ID validated | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| EXT-009 | [N/A] | Protocol CPI (whitelisted programs)  program is in the whitelist before invocation | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| EXT-010 | [N/A] | Protocol CPI  whitelist is owned by the program and linked to the fund | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| EXT-011 | [N/A] | No CPI allows the called program to callback into this program with escalated privileges | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-001 | [N/A] | Every PDA is derived using all required seed components  no missing seeds that could cause collision | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-002 | [N/A] | Fund PDA seeds: [b"fund", manager.key(), name.as_bytes()]  verify all three present | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-003 | [N/A] | For each PDA in the program, list its seeds and verify all present in derivation | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-004 | [N/A] | Verify PDA seed order is consistent between init and all subsequent references | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-005 | [N/A] | Vault/treasury PDA seeds include parent account key  verify present | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-006 | [N/A] | Mint PDA seeds include parent account key  verify present | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-007 | [N/A] | Attestation/oracle PDA seeds include parent account key  verify present | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-008 | [N/A] | Access-control PDA seeds (whitelist, role, permission) include parent account key  verify present | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-009 | [N/A] | All custom PDAs above  verify seeds match in both derivation and usage (no mismatch between init and later references) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-010 | [N/A] | Bump seeds are stored on first derivation and reused  not re-derived each time (saves compute + prevents bump mismatch) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-011 | [N/A] | No PDA seed uses user-controlled variable-length data without length prefix (could cause seed collision) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-012 | [N/A] | Fund name in PDA seeds  is there a max length? Can two funds have names that collide after truncation? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-013 | [N/A] | PDA seeds do not include mutable state that could change (would orphan the PDA) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-014 | [N/A] | Every invoke_signed call uses the correct signer seeds for the PDA authority | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-015 | [N/A] | Signer seeds array matches the PDA derivation exactly (same order, same components) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-016 | [N/A] | Bump seed in invoke_signed matches the stored bump (not a different bump) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-017 | [N/A] | invoke_signed is used (not bare invoke) when PDA is the authority  invoke with PDA authority will fail silently or be exploitable | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-018 | [N/A] | No instruction uses invoke where it should use invoke_signed (missing PDA signing) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-019 | [N/A] | The instruction data passed to invoke_signed cannot be manipulated by the caller to change the operation | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PDA-020 | [N/A] | For Jupiter CPI, the instruction data is either fully constructed by the program or validated | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| RE-001 | [N/A] | State mutations happen BEFORE external CPIs (checks-effects-interactions pattern) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| RE-002 | [N/A] | If state is read after CPI, it's re-loaded (not using stale pre-CPI data) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| RE-003 | [N/A] | Account reload after CPI uses .reload() which re-validates owner (Anchor 1.0) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| RE-004 | [N/A] | No CPI grants approval to an external program that could re-enter | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| RE-005 | [N/A] | Flash loan resistance: could an attacker borrow tokens, deposit, inflate NAV, and withdraw in one transaction? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |

### Checklist 5: 05-program-state-machine.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| SM-001 | [N/A] | List every state enum in the program (e.g., status enums for withdrawals, funds, positions, etc.) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-002 | [N/A] | For each enum, list ALL variants | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-003 | [N/A] | For each enum variant, verify there is at least ONE instruction that transitions INTO that variant | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-004 | [N/A] | For each enum variant, verify there is at least ONE instruction that transitions OUT of that variant (unless it's a terminal state) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-005 | [N/A] | Identify dead variants  enum values that are never set by any instruction. Flag as LOW (dead code) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-006 | [N/A] | Dead variants cannot be set via manual data manipulation (Anchor discriminator prevents external writes) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-007 | [N/A] | Terminal states are clearly identified (e.g., "Completed" after withdrawal finalization) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-008 | [N/A] | Terminal state accounts are closed (freed/rent returned)  not left as zombie accounts | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-009 | [N/A] | Withdrawal initiation instruction  sets status to Initiated from no-state (account creation) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-010 | [N/A] | Withdrawal initiation  requires investor signer and position with sufficient shares | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-011 | [N/A] | Withdrawal swap/conversion instruction  is it restricted to Initiated status only? Or also allows later states? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-012 | [N/A] | If swap/conversion allows multiple statuses  is that intentional and safe? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-013 | [N/A] | Intermediate readiness instruction  transitions from Initiated to ReadyToFinalize (or equivalent). Does this instruction exist? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-014 | [N/A] | If readiness instruction is MISSING  flag as CRITICAL (broken withdrawal flow) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-015 | [N/A] | Withdrawal finalization  requires intermediate status (not Initiated) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-016 | [N/A] | Withdrawal finalization  closes the withdrawal account (returns rent to investor) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-017 | [N/A] | Withdrawal finalization  burns shares, transfers tokens/SOL to investor | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-018 | [N/A] | Withdrawal cancellation  only valid from Initiated status (not ReadyToFinalize) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-019 | [N/A] | Withdrawal cancellation  restores investor's shares / position correctly | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-020 | [N/A] | Withdrawal cancellation  closes the withdrawal account | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-021 | [N/A] | Can an investor have multiple active withdrawals simultaneously? If no, verify uniqueness enforcement | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-022 | [N/A] | Withdrawal timeout: is there a deadline after which a withdrawal can be cancelled/expired? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-023 | [N/A] | Can a withdrawal be stuck forever if admin/manager never advances it? (Griefing vector) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-024 | [N/A] | Partial withdrawal: can investor withdraw some shares and keep others? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-025 | [N/A] | initialize_fund  creates fund with all required fields initialized | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-026 | [N/A] | initialize_fund  sets manager, fee, name, vault, shares_mint correctly | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-027 | [N/A] | Fund cannot be re-initialized after creation (reinitialization protection) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-028 | [N/A] | Fund closure: is there an instruction to close a fund? If yes, what are the preconditions? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-029 | [N/A] | Fund closure: all investor positions must be settled before fund can close | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-030 | [N/A] | Fund closure: all pending withdrawals must be finalized or cancelled | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-031 | [N/A] | If no fund closure instruction exists  flag as INFO (funds live forever, rent locked) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-032 | [N/A] | Fund name uniqueness: can two funds by the same manager have the same name? (PDA collision) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-033 | [N/A] | Fund deposit lifecycle: deposit  position created/updated  shares minted | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-034 | [N/A] | Fund deposit: position.shares increases by correct amount after deposit | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-035 | [N/A] | Position creation: when is a position first created? On first deposit? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-036 | [N/A] | Position tracking: does position correctly track total_deposited, total_withdrawn, shares? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-037 | [N/A] | Position closure: when all shares are withdrawn, is the position account closed? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-038 | [N/A] | Position cannot go negative: shares field cannot underflow below 0 | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-039 | [N/A] | Position total_deposited and total_withdrawn are updated atomically with share changes | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-040 | [N/A] | Can a position exist with 0 shares? What happens if further operations are attempted on it? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-041 | [N/A] | Every state transition checks the CURRENT status before transitioning (pre-condition) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-042 | [N/A] | No transition allows skipping states (e.g., Initiated  Completed without ReadyToFinalize) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-043 | [N/A] | State transitions are atomic  no partial state where transition started but didn't complete | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-044 | [N/A] | If a transaction fails mid-execution, no account is left in an inconsistent state | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-045 | [N/A] | Replay protection: can the same state transition be triggered twice? (e.g., finalize called twice on same withdrawal) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-046 | [N/A] | After close, the PDA's seeds can be reused for a new account  is this safe? No stale associations? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-047 | [N/A] | Every financial state transition emits an event (emit! macro)  deposit, withdrawal, swap, fee | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-048 | [N/A] | Events contain all relevant data: amounts, parties, timestamps, account addresses | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-049 | [N/A] | Events cannot be spoofed (they're emitted by program execution, not user input) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-050 | [N/A] | Off-chain indexers rely on events  verify events are complete for accurate off-chain state reconstruction | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-051 | [N/A] | fund.total_shares == shares_mint.supply  this invariant holds after every instruction | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-052 | [N/A] | fund.total_shares == (all investor_position.shares)  verify no shares are lost or created | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-053 | [N/A] | Fund vault balance is consistent with total_assets tracking (if tracked on-chain) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-054 | [N/A] | After every deposit: fund.total_shares increased, fund.total_assets increased | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-055 | [N/A] | After every withdrawal: fund.total_shares decreased, fund.total_assets decreased | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| SM-056 | [N/A] | After every swap: fund.total_shares unchanged, token balances changed but NAV approximately same | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |

### Checklist 6: 06-program-economic-logic.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| ECON-001 | [N/A] | Can an attacker flash-borrow tokens, deposit into the fund, inflate the NAV, and withdraw in the same transaction? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-002 | [N/A] | Is there a deposit cooldown before withdrawal is allowed? (Prevents atomic depositwithdraw exploitation) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-003 | [N/A] | Is share minting delayed by at least one slot/block from deposit? (Prevents same-slot manipulation) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-004 | [N/A] | Can an attacker flash-borrow SOL, deposit, get shares, and use shares as collateral elsewhere in the same tx? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-005 | [N/A] | NAV attestation  can it be updated and exploited in the same transaction? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-006 | [N/A] | Jupiter swap instructions  do they enforce slippage limits? (User-configurable or hardcoded minimum?) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-007 | [N/A] | Can a validator/MEV searcher sandwich a fund's swap by front-running with a buy and back-running with a sell? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-008 | [N/A] | Manager's swap instruction  is the swap data (route, slippage) determined off-chain? Can it be manipulated? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-009 | [N/A] | Deposit instruction  can it be sandwiched? (attacker deposits before, inflates NAV, depositor gets fewer shares) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-010 | [N/A] | Withdrawal instruction  can it be sandwiched? (attacker manipulates pool prices to reduce withdrawal value) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-011 | [N/A] | Is there a minimum deposit amount to prevent dust attacks that exploit per-transaction costs? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-012 | [N/A] | Is there a minimum withdrawal amount similarly enforced? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-013 | [N/A] | When fund has 0 shares and 0 assets  what ratio does the first deposit use? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-014 | [N/A] | Can the first depositor deposit 1 unit, then donate a large amount to the vault, making the second depositor's shares worth nearly nothing? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-015 | [N/A] | Is there a minimum first deposit requirement to prevent the first depositor attack? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-016 | [N/A] | Is there a "virtual shares" or "dead shares" mechanism (mint some minimal shares to address 0) to prevent first-depositor manipulation? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-017 | [N/A] | Share price at creation  is it 1:1 with the deposit? Verify initialization logic | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-018 | [N/A] | Who attests the NAV? Manager? Oracle? Backend? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-019 | [N/A] | If manager attests NAV  manager can inflate NAV before new deposits (dilution vectors) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-020 | [N/A] | If manager attests NAV  manager can deflate NAV before withdrawals (steal from investors) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-021 | [N/A] | Is there a maximum NAV change per attestation? (Rate limiting on NAV changes) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-022 | [N/A] | Is there a verification mechanism for NAV accuracy? (On-chain oracle, multiple attestors, etc.) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-023 | [N/A] | NAV floor: can NAV be set to 0? What happens to share pricing? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-024 | [N/A] | NAV ceiling: can NAV be set to u64::MAX? Integer overflow in downstream calculations? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-025 | [N/A] | Stale NAV: deposits/withdrawals using outdated NAV  is there a freshness requirement? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-026 | [N/A] | Can the manager set fees to extract more than documented? Verify on-chain max fee enforcement | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-027 | [N/A] | Can the manager change fees after deposits are made? (Retroactive fee change) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-028 | [N/A] | Is there a timelock on fee changes? (Allow investors to withdraw before new fees take effect) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-029 | [N/A] | Can the manager extract fees by making wash trades (trade to themselves, charge fees on volume)? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-030 | [N/A] | Management fee accrual  is it time-proportional or charged on operations? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-031 | [N/A] | Performance fee  is the high-water mark tracked to prevent double-charging on recovery? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-032 | [N/A] | Fee extraction order  are fees deducted before or after the investor's share calculation? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-033 | [N/A] | Can fees be extracted from fund assets without going through the fee instruction path? (Direct transfer CPI) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-034 | [N/A] | Can the manager swap all fund assets to a worthless token? (Protocol risk, not necessarily a bug) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-035 | [N/A] | Can the manager send fund tokens to their personal wallet via pda_token_transfer? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-036 | [N/A] | pda_token_transfer  are both source and destination constrained to be fund-owned accounts? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-037 | [N/A] | pda_lamports_transfer  are destinations constrained? Can manager drain SOL? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-038 | [N/A] | pda_token_approve  can manager approve a delegate on fund tokens? What's the limit? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-039 | [N/A] | token_swap_vault  can manager extract value via unfavorable swap routes? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-040 | [N/A] | Protocol CPI  can manager CPI into a malicious program to drain assets? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-041 | [N/A] | Is the whitelist for protocol CPI controlled by the same manager? (Fox guarding the henhouse) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-042 | [N/A] | Can manager add their own program to the whitelist and then drain via CPI? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-043 | [N/A] | Is there investor-side protection against manager misbehavior? (Timelock, multi-sig, withdrawal guarantee) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-044 | [N/A] | Token-2022 transfer hook: can a malicious token with a transfer hook exploit the fund? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-045 | [N/A] | Token with fee-on-transfer: does the program correctly handle tokens where transfer amount != received amount? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-046 | [N/A] | Rebasing tokens: does the program handle tokens whose balance changes without transfers? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-047 | [N/A] | Tokens with freeze authority: can someone freeze fund's token accounts? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-048 | [N/A] | Tokens with mint authority: can someone inflate token supply after fund buys them? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-049 | [N/A] | Non-standard decimal tokens (e.g., 0 decimals, 18 decimals): does the program handle all decimal ranges? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-050 | [N/A] | WSOL wrapping/unwrapping: correct handling of native SOL  wrapped SOL transitions | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-051 | [N/A] | Can an attacker make transactions too expensive for legitimate users? (Account bloat, compute unit exhaustion) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-052 | [N/A] | Can an attacker create many positions or withdrawals to make batch operations fail (out of compute)? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-053 | [N/A] | pay_fund_investors with many remaining_accounts  does it exhaust compute budget? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-054 | [N/A] | Can an attacker spam small deposits to create many positions and bloat state? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-055 | [N/A] | Large Vec or array in state  can it grow unbounded and exceed account size limit? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-056 | [N/A] | Can an attacker lock funds by creating a state that prevents legitimate operations? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-057 | [N/A] | If program relies on price oracles  which oracle? Pyth, Switchboard, Chainlink? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-058 | [N/A] | Oracle price staleness check  is there a max age for oracle prices? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-059 | [N/A] | Oracle confidence interval  are wide-confidence prices rejected? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-060 | [N/A] | Can oracle be manipulated by the same party who benefits from the manipulation? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-061 | [N/A] | Multi-oracle: does the program use fallback oracles if primary is stale? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| ECON-062 | [N/A] | If no oracle is used (manager-attested NAV)  document the trust assumption and flag | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |

### Checklist 7: 07-program-opsec-governance.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| OPS-001 | [N/A] | What is the current upgrade authority of the deployed program? (run solana program show <PROGRAM_ID>) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-002 | [N/A] | Is the upgrade authority a multisig (e.g., Squads v3/v4)? If it's a single wallet  flag as HIGH | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-003 | [N/A] | How many signers are required on the multisig? Verify threshold (e.g., 2/3, 3/5) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-004 | [N/A] | Who are the individual signers on the multisig? Are they different entities? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-005 | [N/A] | Are the multisig signers on hardware wallets (Ledger, etc.) or hot wallets? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-006 | [N/A] | Is there a timelock on program upgrades? How many hours/days? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-007 | [N/A] | If there is a timelock  is it enforced on-chain or just a team policy? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-008 | [N/A] | Recommended minimum timelock: 24 hours for DeFi programs, 72 hours for critical infrastructure | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-009 | [N/A] | Can the upgrade authority be changed? Who can change it? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-010 | [N/A] | Is the program set to non-upgradeable (immutable)? If not, should it be? Document reasoning | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-011 | [N/A] | If program is upgradeable  can a malicious upgrade drain all funds? (Yes, by definition  hence multisig + timelock) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-012 | [N/A] | Is there a process for emergency upgrades that bypass the timelock? If yes, what are the safeguards? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-013 | [N/A] | Search for hidden admin instructions  any instruction that accepts a hardcoded admin pubkey (not visible in docs/IDL) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-014 | [N/A] | Search for "god mode" accounts  any account that can bypass all access control checks | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-015 | [N/A] | Search for conditional logic based on specific pubkeys: if account.key() == Pubkey::new_from_array([...]) hidden checks | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-016 | [N/A] | Search for unused instruction handlers that could be invoked  dead code that's still callable | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-017 | [N/A] | Verify IDL matches the actual program binary  no undisclosed instructions | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-018 | [N/A] | Check for instructions that can modify the Treasury pubkey to redirect fees | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-019 | [N/A] | Check for instructions that can modify the Jupiter/DEX program ID to redirect swaps | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-020 | [N/A] | Check for instructions that can change fund manager without investor consent | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-021 | [N/A] | Check for instructions that can mint shares without deposit (share dilution) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-022 | [N/A] | Check for instructions that can burn shares without withdrawal (theft) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-023 | [N/A] | Search for unsafe blocks in Rust code  any usage must be documented and justified | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-024 | [N/A] | Search for raw pointer manipulation (*const, *mut)  should not exist in Anchor programs | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-025 | [N/A] | Check declare_id! matches between code and Anchor.toml  mismatch could mean wrong program | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-026 | [N/A] | Verify program binary matches published source code (verifiable builds) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-027 | [N/A] | Deploy keypair  is it on a hardware wallet for mainnet? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-028 | [N/A] | Deploy keypair  is it stored securely (not in repo, not on dev machine in plaintext)? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-029 | [N/A] | Manager wallets  are they on hardware wallets or multisig for mainnet? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-030 | [N/A] | Backend server wallet (if exists)  is it the minimum-privilege wallet? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-031 | [N/A] | Backend server wallet  does it hold significant SOL/tokens? (Should only hold gas) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-032 | [N/A] | API keys (Helius, Jupiter, etc.)  are they rotated regularly? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-033 | [N/A] | API keys  are they scoped to minimum required permissions? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-034 | [N/A] | RPC endpoint  is it a dedicated RPC (Helius/Triton) not the public endpoint? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-035 | [N/A] | RPC endpoint  is the API key exposed in frontend code? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-036 | [N/A] | Has any key ever been committed to git? Check git log --all --oneline -S "secret_string" patterns | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-037 | [N/A] | Is a multisig used for on-chain operations? Which platform? (Squads, Goki, Marinade, custom) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-038 | [N/A] | Multisig threshold  is it > 50% of total signers? (e.g., 2/3 minimum) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-039 | [N/A] | Multisig  does any single signer have disproportionate power? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-040 | [N/A] | Multisig  are there backup signers in case one is compromised or unavailable? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-041 | [N/A] | Multisig  can a single compromised signer change the threshold to 1/N? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-042 | [N/A] | Multisig  is there a proposal expiry? Can old proposals be executed weeks later? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-043 | [N/A] | Multisig  are executed transactions logged and auditable? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-044 | [N/A] | Is there a documented incident response plan? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-045 | [N/A] | Can the program be paused in an emergency? By whom? How quickly? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-046 | [N/A] | Is there a bug bounty program? (Immunefi, HackerOne, or self-hosted) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-047 | [N/A] | Is there a security contact (security@domain.com, SECURITY.md in repo)? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-048 | [N/A] | Are there monitoring alerts for large value movements from fund PDAs? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-049 | [N/A] | Are there monitoring alerts for program upgrade transactions? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-050 | [N/A] | Are there monitoring alerts for unusual transaction patterns (many withdrawals, large swaps)? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-051 | [N/A] | Is there a war room process? Who needs to be contacted and in what order? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-052 | [N/A] | Post-incident: is there a process for post-mortem analysis? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-053 | [N/A] | List ALL actions that are time-locked and their durations | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-054 | [N/A] | Program upgrades  timelock duration: _____ hours/days | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-055 | [N/A] | Fee changes  timelock duration: _____ hours/days (or "none"  flag if none) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-056 | [N/A] | Manager changes  timelock duration: _____ hours/days (or "none") | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-057 | [N/A] | Whitelist changes  timelock duration: _____ hours/days (or "none") | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-058 | [N/A] | Treasury address changes  timelock duration: _____ hours/days (should be "immutable") | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-059 | [N/A] | Emergency bypass for timelock  what triggers it? How many signers? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-060 | [N/A] | Transaction cancellation  can a time-locked transaction be cancelled before execution? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-061 | [N/A] | Users notified of pending time-locked changes? (On-chain event, frontend alert, Discord) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-062 | [N/A] | Dev, staging, and production environments use completely separate keys | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-063 | [N/A] | No developer has production deploy access from their personal machine | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-064 | [N/A] | CI/CD pipeline  does it auto-deploy? If yes, what are the safeguards? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-065 | [N/A] | Server access  SSH keys rotated, 2FA enabled, access logging | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-066 | [N/A] | Database access  separate credentials per environment, no shared passwords | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-067 | [N/A] | Wallet private keys  never in CI/CD environment variables in plaintext | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-068 | [N/A] | Secret manager used? (AWS Secrets Manager, Vault, doppler, etc.) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-069 | [N/A] | Is the program source code open source? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-070 | [N/A] | Does the published source match the deployed binary? (Verifiable builds via anchor verify) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-071 | [N/A] | Can the audit check be reproduced? (anchor build produces same binary) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-072 | [N/A] | Is the git history clean? (No force-pushes that remove commit history) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-073 | [N/A] | Are there branch protection rules? (No direct push to main, required reviews) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-074 | [N/A] | Is the CI/CD pipeline itself secured? (No PR can modify CI to skip checks) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| OPS-075 | [N/A] | Dependencies are version-pinned (no ^ or ~ in Cargo.toml for critical deps) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |

### Checklist 8: 08-typescript-safety.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| TS-001 | [N/A] | grep -rn ": any" --include="*.ts" --include="*.tsx"  ZERO results expected | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-002 | [N/A] | grep -rn "as any" --include="*.ts" --include="*.tsx"  ZERO results expected | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-003 | [N/A] | grep -rn "<any>" --include="*.ts" --include="*.tsx"  ZERO results expected | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-004 | [N/A] | grep -rn "Record<string, any>" --include="*.ts" --include="*.tsx"  ZERO results expected | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-005 | [N/A] | grep -rn "Promise<any>" --include="*.ts" --include="*.tsx"  ZERO results expected | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-006 | [N/A] | grep -rn "Array<any>" --include="*.ts" --include="*.tsx"  ZERO results expected | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-007 | [N/A] | grep -rn "catch.*: any" --include="*.ts" --include="*.tsx"  ZERO results expected | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-008 | [N/A] | grep -rn "Function" --include="*.ts" --include="*.tsx"  avoid Function type (implicit any) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-009 | [N/A] | grep -rn "Object" --include="*.ts" --include="*.tsx"  avoid bare Object type | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-010 | [N/A] | If any any exists  is there a documented justification with // eslint-disable-next-line? Still flag it | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-011 | [N/A] | All catch blocks use catch (e: unknown)  never catch (e: any) or catch (e) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-012 | [N/A] | After catch (e: unknown), type is narrowed: if (e instanceof Error) before accessing .message | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-013 | [N/A] | No empty catch blocks: catch (e) { } or catch (e) { /* ignore */ }  flag all | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-014 | [N/A] | No catch that silently swallows errors without logging | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-015 | [N/A] | Errors are logged with context (which function, what input caused it, timestamp) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-016 | [N/A] | No console.log for error handling in production  use structured logging | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-017 | [N/A] | Thrown errors use custom error classes or descriptive messages (not bare throw new Error("error")) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-018 | [N/A] | Async functions: all promises are awaited or explicitly handled with .catch()  no floating promises | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-019 | [N/A] | No Promise<void> without error handling (unhandled rejection) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-020 | [N/A] | Process-level unhandled rejection handler: process.on('unhandledRejection', ...) in backend | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-021 | [N/A] | All Anchor imports use @anchor-lang/core  NOT @coral-xyz/anchor (discontinued) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-022 | [N/A] | No require() calls  use ES module import syntax | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-023 | [N/A] | No dynamic imports of user-controlled paths  import(userInput) is code injection | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-024 | [N/A] | IDL types imported from correct generated location (target/types/) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-025 | [N/A] | No circular imports  check with madge --circular or similar tool | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-026 | [N/A] | Unused imports are removed (no dead code) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-027 | [N/A] | tsconfig.json has strict: true enabled | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-028 | [N/A] | tsconfig.json has noImplicitAny: true | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-029 | [N/A] | tsconfig.json has strictNullChecks: true | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-030 | [N/A] | TypeScript version is current and supported | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-031 | [N/A] | All pubkey strings are validated with new PublicKey(str) in try-catch before use | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-032 | [N/A] | PublicKey comparisons use .equals() not == or === | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-033 | [N/A] | All lamport values use bigint or BN  not plain number (precision loss above 2^53) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-034 | [N/A] | PDA derivation uses PublicKey.findProgramAddressSync()  never hardcoded bumps | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-035 | [N/A] | ATA derivation uses getAssociatedTokenAddressSync()  never manual derivation | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-036 | [N/A] | Transaction builders properly set feePayer and recentBlockhash | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-037 | [N/A] | Transaction simulation before sending  connection.simulateTransaction() used | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-038 | [N/A] | BN arithmetic uses the correct methods (.add(), .sub(), .mul(), .div())  not JS arithmetic on BN objects | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-039 | [N/A] | keypair handling  no private keys in source code or hardcoded | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-040 | [N/A] | Connection object uses committed/finalized commitment for financial reads | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-041 | [N/A] | Every API endpoint has a zod schema for request body | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-042 | [N/A] | Zod schemas enforce types, not just presence (.string().min(1) not just .string()) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-043 | [N/A] | Zod schemas for pubkeys use .refine() to validate as a real base58 PublicKey | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-044 | [N/A] | Zod schemas for amounts use .number().positive() or .bigint() | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-045 | [N/A] | Zod schemas reject unexpected fields (.strict() mode or explicit schema) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-046 | [N/A] | Zod parse errors return 400 with descriptive error (not internal message) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-047 | [N/A] | No req.body read without going through zod parse first | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-048 | [N/A] | No req.query or req.params used without validation | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-049 | [N/A] | JSON responses from external APIs are typed with interfaces (not as any) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-050 | [N/A] | JSON parsing uses try-catch: try { JSON.parse(text) } not bare JSON.parse() | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-051 | [N/A] | Borsh deserialization uses generated types from Anchor IDL | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-052 | [N/A] | Base58/Base64 encoding uses well-known libraries (bs58, Buffer.from) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-053 | [N/A] | No eval() or new Function() anywhere in the codebase | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-054 | [N/A] | No template literal injection in SQL/MongoDB queries | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-055 | [N/A] | TypeScript satisfies keyword used where appropriate for compile-time checks | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-056 | [N/A] | Third-party libs without types have .d.ts declaration files (not any escape hatch) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-057 | [N/A] | Custom .d.ts files are in a types/ directory and referenced in tsconfig.json | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-058 | [N/A] | No @ts-ignore or @ts-nocheck comments  flag every occurrence | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-059 | [N/A] | No @ts-expect-error without a clearly documented reason on the same line | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| TS-060 | [N/A] | Interfaces/types for all MongoDB document shapes are defined and used consistently | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |

### Checklist 9: 09-backend-security.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| BE-001 | [N/A] | Every POST/PUT/DELETE endpoint verifies wallet ownership via signature  not just trusting walletAddress from body | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-002 | [N/A] | Signature verification headers present: x-wallet, x-signature, x-timestamp | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-003 | [N/A] | Signature message format: ${method}:${path}:${timestamp}  consistent across all endpoints | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-004 | [N/A] | Verification library: tweetnacl or @noble/ed25519  correct usage of sign.detached.verify() | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-005 | [N/A] | Replay protection: timestamp checked  reject if > 5 minutes old | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-006 | [N/A] | Timestamp is compared against server time, not client-supplied time | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-007 | [N/A] | Nonce or idempotency key used for critical mutations (prevent duplicate submissions) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-008 | [N/A] | Admin routes have ADDITIONAL auth beyond wallet signature (IP allowlist, admin wallet list) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-009 | [N/A] | No endpoint trusts req.body.walletAddress without signature verification for identity | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-010 | [N/A] | Auth middleware is applied to ALL protected routes  no route accidentally unprotected | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-011 | [N/A] | Every request body passes through a zod schema before processing | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-012 | [N/A] | MongoDB queries never use raw user input in .find()  validate format first | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-013 | [N/A] | MongoDB: reject objects/arrays where strings are expected (NoSQL injection: { "$gt": "" } in string fields) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-014 | [N/A] | MongoDB: use $eq explicitly instead of bare value matching for user-supplied fields | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-015 | [N/A] | No eval(), Function(), or dynamic code execution with user input | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-016 | [N/A] | No path traversal: file paths from user input are sanitized (no ../) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-017 | [N/A] | No command injection: no child_process.exec() with user input | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-018 | [N/A] | No SSRF: no HTTP requests to user-supplied URLs without allowlist | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-019 | [N/A] | URL parameters validated  no open redirect via unvalidated redirect URLs | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-020 | [N/A] | Content-Type header validated  only accept application/json for JSON endpoints | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-021 | [N/A] | Trade records: transaction signature is verified as a real confirmed transaction via connection.getTransaction() | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-022 | [N/A] | Trade verification: check that the transaction actually does what it claims (correct program, correct accounts) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-023 | [N/A] | Withdrawal records: verify the investor actually signed the withdrawal transaction | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-024 | [N/A] | Deposit records: verify the deposit transaction signature on-chain before recording in database | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-025 | [N/A] | Bridge deposits (if applicable): verify EVM transaction receipt via RPC before recording | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-026 | [N/A] | No trust of off-chain data without on-chain verification for financial records | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-027 | [N/A] | Transaction confirmation: use confirmed or finalized commitment  not processed | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-028 | [N/A] | Handle transaction verification failures gracefully  don't record unverified transactions | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-029 | [N/A] | Rate limiting is enabled in ALL environments (not just production) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-030 | [N/A] | Global rate limit exists (e.g., 100 req/min per IP) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-031 | [N/A] | Per-endpoint rate limits for financial endpoints: swap, withdraw, trade (5-10 req/hour) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-032 | [N/A] | Per-wallet rate limits in addition to per-IP | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-033 | [N/A] | Rate limit headers returned (X-RateLimit-Remaining, Retry-After) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-034 | [N/A] | Rate limiting cannot be bypassed via proxy/spoofed headers (X-Forwarded-For) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-035 | [N/A] | Rate limit store: in-memory works for single instance, Redis for multi-instance | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-036 | [N/A] | Custom error classes used: AppError, AuthError, ValidationError (not bare Error) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-037 | [N/A] | No stack traces exposed in production responses | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-038 | [N/A] | Error responses use standard format: { error: string, code?: string } | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-039 | [N/A] | Status codes are correct: 400 validation, 401 auth, 403 forbidden, 404 not found, 429 rate limit, 500 internal | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-040 | [N/A] | 500 errors are logged with full context (wallet, endpoint, timestamp, stack trace) but NOT returned to client | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-041 | [N/A] | No catch (e) { } empty catch blocks  flag every occurrence | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-042 | [N/A] | Global error handler (app.use((err, req, res, next) => ...)) catches all unhandled errors | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-043 | [N/A] | Async route handlers wrapped with error-catching middleware (or use express-async-errors) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-044 | [N/A] | Database connection errors handled gracefully  don't crash the server | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-045 | [N/A] | Helmet middleware enabled with appropriate CSP | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-046 | [N/A] | HSTS header: Strict-Transport-Security: max-age=31536000; includeSubDomains | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-047 | [N/A] | X-Frame-Options: DENY or SAMEORIGIN | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-048 | [N/A] | X-Content-Type-Options: nosniff | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-049 | [N/A] | Content-Security-Policy: restrictive, no unsafe-eval or unsafe-inline unless necessary | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-050 | [N/A] | Referrer-Policy: strict-origin-when-cross-origin or stricter | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-051 | [N/A] | CORS does NOT use origin: true (allows any origin) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-052 | [N/A] | CORS does NOT use origin: '*' (allows any origin) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-053 | [N/A] | CORS uses an explicit allowlist of origins | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-054 | [N/A] | CORS credentials: true only with specific origins (not wildcard) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-055 | [N/A] | CORS methods restricted to necessary HTTP methods | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-056 | [N/A] | CORS allowedHeaders restricted to necessary headers | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-057 | [N/A] | Database connection string does NOT contain credentials in code (uses env var) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-058 | [N/A] | Database uses authentication (not anonymous access) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-059 | [N/A] | Database user has minimum required permissions (not admin) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-060 | [N/A] | Database is not publicly accessible (firewall/security group) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-061 | [N/A] | Sensitive data is not logged in debug/info level | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-062 | [N/A] | Database indexes exist for frequently queried fields (performance + DoS prevention) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-063 | [N/A] | No raw string concatenation in MongoDB queries  use parameterized queries | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-064 | [N/A] | Document size limits enforced (prevent stored DoS via huge documents) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-065 | [N/A] | All required env vars validated at startup  fail fast if missing | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-066 | [N/A] | No default values for secrets (no process.env.SECRET \|\| "default") | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-067 | [N/A] | .env file is in .gitignore | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-068 | [N/A] | No secrets in package.json, tsconfig.json, or any config file | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-069 | [N/A] | Node environment is set correctly: NODE_ENV=production in production | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-070 | [N/A] | Debug endpoints disabled in production (/debug, /test, /dev) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-071 | [N/A] | Structured logging (JSON format) for machine-parsable logs | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-072 | [N/A] | Log rotation configured (don't fill disk) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-073 | [N/A] | Sensitive data NOT logged: private keys, passwords, full request bodies with secrets | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-074 | [N/A] | Request logging includes: method, path, wallet (if authed), status code, response time | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-075 | [N/A] | Failed auth attempts logged with IP and wallet address | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-076 | [N/A] | Anomaly detection: alerts on >X failed auth attempts from same IP/wallet | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-077 | [N/A] | Every endpoint returning user-specific data verifies the authenticated user owns that resource (no IDOR) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-078 | [N/A] | Resource IDs in URLs/params cannot be enumerated to access other users' data (test with another user's ID) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-079 | [N/A] | Request body fields are explicitly picked before DB write  never db.update(req.body) or spread ...body | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-080 | [N/A] | No mass assignment: sending { isAdmin: true } or { role: "admin" } in body has no effect | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-081 | [N/A] | API responses don't leak fields from other users (verify query filters include auth user constraint) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-082 | [N/A] | If using Supabase: RLS (Row Level Security) is ENABLED on every single table  ALTER TABLE ... ENABLE ROW LEVEL SECURITY | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-083 | [N/A] | RLS policies use auth.uid() = user_id (not just role check authenticated)  user can only see own rows | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-084 | [N/A] | RLS policies exist for ALL operations: SELECT, INSERT, UPDATE, DELETE  not just SELECT | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-085 | [N/A] | service_role / admin SDK key is NEVER in client-side code or NEXT_PUBLIC_ env vars | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-086 | [N/A] | Supabase Storage bucket policies restrict upload MIME types (no .html, .svg, .js unless intentional) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-087 | [N/A] | Database functions marked security definer are audited  they bypass RLS | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-088 | [N/A] | If using Firebase: Firestore/RTDB security rules exist and are not allow read, write: if true | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-089 | [N/A] | Firebase Storage rules validate file type and size  not open to all authenticated users | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-090 | [N/A] | BaaS anon key (public) can only perform operations explicitly allowed by RLS/rules  test with curl | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-091 | [N/A] | No ReDoS  user-controlled strings not used in regex patterns, or safe regex library used with length limits | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-092 | [N/A] | GraphQL: introspection disabled in production; query depth and complexity limits enforced | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-093 | [N/A] | WebSocket connections require authentication on connect; unauthenticated sockets rejected immediately | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-094 | [N/A] | Webhook endpoints validate cryptographic signatures (e.g., Stripe constructEvent(), GitHub HMAC) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-095 | [N/A] | Body parser has explicit size limits: express.json({ limit: '1mb' })  no unbounded payload acceptance | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-096 | [N/A] | No XML parsing of user input, or if needed, external entities disabled (XXE prevention: noent: false, dtd: false) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-097 | [N/A] | HTTP response headers don't reflect user input (header injection / response splitting prevention) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-098 | [N/A] | Session tokens regenerated after authentication (session fixation prevention) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-099 | [N/A] | Login/signup responses don't reveal whether an account exists (consistent timing and messages for enumeration prevention) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| BE-100 | [N/A] | No JSON.parse on user input used to construct objects with __proto__ or constructor (prototype pollution via deserialization) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |

### Checklist 10: 10-frontend-security.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| FE-001 | [N/A] | No use of dangerouslySetInnerHTML  flag every occurrence | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-002 | [N/A] | If dangerouslySetInnerHTML is used  is the input sanitized with DOMPurify or equivalent? | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-003 | [N/A] | User-generated content (names, descriptions) is rendered as text, not HTML | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-004 | [N/A] | No document.write() or document.writeln() anywhere | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-005 | [N/A] | No inline event handlers in JSX (onClick={new Function(userInput)}) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-006 | [N/A] | URL parameters are not rendered directly into the DOM without sanitization | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-007 | [N/A] | target="_blank" links include rel="noopener noreferrer" | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-008 | [N/A] | No template literal injection in URL construction: ${userInput} in URLs is validated | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-009 | [N/A] | NEXT_PUBLIC_ env vars  list all and verify NONE contain secrets | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-010 | [N/A] | No API keys in client-side code (RPC URLs with API keys, Jupiter API key, etc.) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-011 | [N/A] | Sensitive API calls proxied through backend  not called directly from browser | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-012 | [N/A] | No private keys or mnemonics in frontend code (including test files) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-013 | [N/A] | Wallet adapter handles private keys  no custom key handling in frontend | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-014 | [N/A] | No hardcoded tokens, passwords, or secrets in source maps | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-015 | [N/A] | Source maps disabled in production build (or only accessible to team) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-016 | [N/A] | .env.local is in .gitignore | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-017 | [N/A] | All API routes validate wallet signatures server-side (not just client-side) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-018 | [N/A] | API route body parsing in try-catch: try { body = await req.json() } catch { return 400 } | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-019 | [N/A] | Required fields validated before proxying to backend | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-020 | [N/A] | Proxy responses: text() then try { JSON.parse(text) }  never bare .json() | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-021 | [N/A] | Error status codes: 400 validation, 401 auth, 502 backend proxy failure (NOT 500) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-022 | [N/A] | No internal error messages leaked to client | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-023 | [N/A] | CORS headers set in middleware.ts for API routes | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-024 | [N/A] | Rate limiting on API routes (at minimum, forwarded from backend) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-025 | [N/A] | No sensitive data stored in localStorage (private keys, tokens, session data) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-026 | [N/A] | No sensitive data stored in sessionStorage without encryption | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-027 | [N/A] | Cookies (if used): HttpOnly, Secure, SameSite=Strict flags | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-028 | [N/A] | No logging of sensitive data with console.log in production | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-029 | [N/A] | All console.log removed from production code (or gated behind NODE_ENV) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-030 | [N/A] | No sensitive data in React state that persists after component unmount | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-031 | [N/A] | Browser history: no sensitive data in URL parameters (e.g., ?key=secret) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-032 | [N/A] | Transactions are built on the client and signed by the user's wallet  server never holds private keys | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-033 | [N/A] | Transaction simulation shown to user before signing (or at minimum, details displayed) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-034 | [N/A] | Transaction confirmation waited for before showing success (finalized or confirmed commitment) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-035 | [N/A] | Transaction failure handled gracefully  user-friendly error message | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-036 | [N/A] | No auto-signing of transactions without user interaction | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-037 | [N/A] | Wallet disconnect properly clears all session state | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-038 | [N/A] | Multiple wallet support doesn't leak state between wallets | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-039 | [N/A] | Transaction builders validate all inputs before building instruction | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-040 | [N/A] | No race conditions in transaction submission (double-click protection) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-041 | [N/A] | All images use next/image  no raw <img> tags | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-042 | [N/A] | Videos: preload="none", poster attribute, explicit dimensions | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-043 | [N/A] | Heavy components lazy-loaded: dynamic(() => import('./X'), { ssr: false }) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-044 | [N/A] | loading.tsx and error.tsx in every route segment | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-045 | [N/A] | <Suspense> boundaries around data-fetching components | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-046 | [N/A] | Memoization used where appropriate: useMemo, useCallback with stable deps | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-047 | [N/A] | Max 5 useState per component  beyond that, use useReducer | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-048 | [N/A] | Error Boundaries catch component crashes gracefully | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-049 | [N/A] | No infinite re-render loops (check useEffect deps arrays) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-050 | [N/A] | Bundle size: no unnecessarily large packages imported (lodash full import, etc.) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-051 | [N/A] | All interactive elements have aria-label | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-052 | [N/A] | Semantic HTML used: <section>, <nav>, <article>, <main>, <header>, <footer> | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-053 | [N/A] | Modals trap focus and support Escape key | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-054 | [N/A] | Text contrast passes WCAG AA (no text-white/30 on dark for readable text) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-055 | [N/A] | Form inputs have associated <label> elements | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-056 | [N/A] | Tab navigation works correctly through all interactive elements | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-057 | [N/A] | No third-party scripts loaded from untrusted CDNs without SRI (Subresource Integrity) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-058 | [N/A] | Analytics scripts (if present) don't capture sensitive data | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-059 | [N/A] | No postMessage handlers without origin validation | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-060 | [N/A] | iframes (if present) use sandbox attribute | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-061 | [N/A] | Web Workers (if used) don't process user-controlled code | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-062 | [N/A] | Service Workers (if used) have proper scope and don't intercept unintended requests | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-063 | [N/A] | SVG files from user input are sanitized  <script>, onload, onerror, <foreignObject>, javascript: URIs stripped | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-064 | [N/A] | User-uploaded images: MIME type validated server-side (not just client extension  attackers rename .svg to .png) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-065 | [N/A] | <img src> rejects data:image/svg+xml URIs from user input (inline SVG = XSS vector) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-066 | [N/A] | Content-Security-Policy: no unsafe-inline in script-src (prevents inline script execution from SVG) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-067 | [N/A] | User-uploaded files served from a separate domain/CDN (not same-origin  prevents cookie access) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-068 | [N/A] | File uploads have server-side size limits and type allowlists (not just frontend validation) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-069 | [N/A] | No user-controlled HTML/SVG rendered in <iframe srcdoc> without sandbox | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-070 | [N/A] | Clickjacking protection: CSP frame-ancestors 'self' AND X-Frame-Options set server-side | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-071 | [N/A] | window.addEventListener('message', ...) handlers validate event.origin against allowlist before processing data | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-072 | [N/A] | OAuth/social login flows include state parameter and validate it on callback (CSRF via OAuth prevention) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-073 | [N/A] | Wallet/crypto addresses displayed on page are not vulnerable to clipboard hijacking  copy button copies from DOM, not from hidden/injected element | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-074 | [N/A] | No sensitive tokens, session IDs, or secrets in URL query parameters (visible in referrer headers, browser history, server logs) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-075 | [N/A] | CSS does not accept/interpolate user input  no style={{ background: userInput }} without sanitization (CSS exfiltration prevention) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| FE-076 | [N/A] | Client-side route guards (e.g., if (!user) redirect('/login')) are backed by server-side auth checks on every API call  never trust client-only auth | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |

### Checklist 11: 11-supply-chain.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| SC-001 | [PASS] | axios@1.14.1 is NOT in any package.json or package-lock.json  CRITICAL if found | Neither prohibited axios version appears in package files. |
| SC-002 | [PASS] | axios@0.30.4 is NOT in any package.json or package-lock.json  CRITICAL if found | Neither prohibited axios version appears in package files. |
| SC-003 | [PASS] | Run npm audit  zero critical or high vulnerabilities | npm audit returned zero vulnerabilities on 2026-06-21. |
| SC-004 | [N/A] | Run cargo audit (if installed)  zero advisories | No Rust/Cargo package is in first-party scope. |
| SC-005 | [PASS] | Check for known compromised packages in the npm ecosystem (event-stream, ua-parser-js, etc.) | Direct npm dependencies are lint-staged and simple-git-hooks; npm audit is clean. |
| SC-006 | [PASS] | No packages with known typosquatting risk (e.g., crossenv vs cross-env) | No suspicious or typo-like direct package names found. |
| SC-007 | [PARTIAL] | For EACH direct dependency in package.json, verify the installed version was published > 14 days ago | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-008 | [PARTIAL] | Run npm info <pkg> time for any recently updated packages | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-009 | [PARTIAL] | If any dependency version is < 14 days old  flag and pin to older safe version | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-010 | [N/A] | Same quarantine check for Cargo.toml dependencies (check crates.io publish dates) | Rust/Cargo/Anchor-specific dependency check; no first-party Rust package. |
| SC-011 | [PASS] | Lock files (package-lock.json, Cargo.lock) are committed to git | package-lock.json and foundry.lock are committed; submodules are pinned gitlinks. |
| SC-012 | [PARTIAL] | Lock file integrity: npm ci produces same results as committed lock file | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-013 | [PARTIAL] | Critical dependencies in package.json use exact versions (no ^ or ~)  check: | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-014 | [N/A] | Cargo.toml dependencies  verify versions are pinned for: | Rust/Cargo/Anchor-specific dependency check; no first-party Rust package. |
| SC-015 | [PASS] | No * version ranges in any dependency | No wildcard dependency range is present. |
| SC-016 | [PARTIAL] | Dev dependencies can use ranges  but production dependencies should be pinned | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-017 | [PASS] | Total number of direct dependencies: _____ (document  fewer is better) | Two direct npm development dependencies; Solidity dependencies are pinned submodules/remappings. |
| SC-018 | [PARTIAL] | Any deprecated packages? Run npm outdated | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-019 | [PARTIAL] | Any packages with no recent maintenance (>1 year without update)? | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-020 | [PARTIAL] | Any packages with very few downloads (<1000/week)? Higher supply chain risk | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-021 | [PARTIAL] | Any packages with recent ownership transfer? Check npm page for maintainer changes | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-022 | [PASS] | Package @coral-xyz/anchor is NOT installed (discontinued  use @anchor-lang/core) | The discontinued Anchor package is absent. |
| SC-023 | [PARTIAL] | No duplicate packages (same functionality from different packages) | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-024 | [PARTIAL] | Postinstall scripts  any package runs scripts on install? (npm ls --json then check scripts) | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-025 | [PASS] | .npmrc does not contain auth tokens | No .npmrc containing credentials exists. |
| SC-026 | [PASS] | package.json has no preinstall/postinstall scripts that execute arbitrary code | Package scripts contain only simple-git-hooks preparation; no arbitrary install hook. |
| SC-027 | [PARTIAL] | Build process is deterministic  same source produces same output | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-028 | [PASS] | Build artifacts are not committed to git (except intentional like IDL) | Foundry out/cache artifacts are ignored and not tracked. |
| SC-029 | [PARTIAL] | No --ignore-scripts flag needed (all packages are safe to run install scripts) | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-030 | [PARTIAL] | CI/CD npm install uses npm ci (not npm install) for reproducibility | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-031 | [N/A] | Borsh version  let Anchor manage it (no manual pin that conflicts) | Rust/Cargo/Anchor-specific dependency check; no first-party Rust package. |
| SC-032 | [N/A] | solana-program version matches the target Solana runtime version | Rust/Cargo/Anchor-specific dependency check; no first-party Rust package. |
| SC-033 | [N/A] | No git = "..." dependencies pointing to non-official repositories | Rust/Cargo/Anchor-specific dependency check; no first-party Rust package. |
| SC-034 | [N/A] | No path = "..." dependencies pointing outside the repository | Rust/Cargo/Anchor-specific dependency check; no first-party Rust package. |
| SC-035 | [N/A] | Cargo.lock is committed and used for builds | Rust/Cargo/Anchor-specific dependency check; no first-party Rust package. |
| SC-036 | [N/A] | Feature flags reviewed  no unexpected features enabled | Rust/Cargo/Anchor-specific dependency check; no first-party Rust package. |
| SC-037 | [N/A] | No [patch] section in Cargo.toml that overrides official crates | Rust/Cargo/Anchor-specific dependency check; no first-party Rust package. |
| SC-038 | [N/A] | Build with --release for production  verify optimization level | Rust/Cargo/Anchor-specific dependency check; no first-party Rust package. |
| SC-039 | [PARTIAL] | Run npm ls --all  review tree for unexpected packages | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-040 | [PARTIAL] | Any transitive dependency that is in the compromised list? | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-041 | [PARTIAL] | Any transitive dependency pulling in native binary modules? (Higher risk) | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-042 | [PARTIAL] | Dependency resolution conflicts  any forced resolutions/overrides? | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |
| SC-043 | [PARTIAL] | package-lock.json reviewed for unexpected URLs or registries | Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification. |

### Checklist 12: 12-secrets-opsec.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| SEC-001 | [PASS] | grep -rn "private" --include="*.ts" --include="*.tsx" --include="*.json"  no private keys in source | Source scan found no private key material; matches were documentation text only. |
| SEC-002 | [PASS] | grep -rn "secret" --include="*.ts" --include="*.json" --include="*.env*"  check all matches | Secret-keyword scan found no credential values in production source. |
| SEC-003 | [PASS] | grep -rn "mnemonic\\|seed phrase" --include="*.ts"  zero results | No mnemonic or seed phrase value found. |
| SEC-004 | [PARTIAL] | grep -rn "password" --include="*.ts" --include="*.json"  only refs to env vars | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-005 | [PARTIAL] | No base58-encoded private keys in any file (44-character strings starting with specific patterns) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-006 | [PASS] | No JSON keypair files committed (.json files with 64-element integer arrays) | No keypair array file is tracked. |
| SEC-007 | [PARTIAL] | No Solana keypair files in repo (check for id.json, *-keypair.json, *-delegate.json) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-008 | [PASS] | No .env files committed to git  check git log --all --name-only \| grep -i ".env" | No populated .env file is tracked or found in history; only templates exist. |
| SEC-009 | [PASS] | No API keys hardcoded  check for patterns like sk-, api_, key_, long hex/base64 strings | No production API key or private key value found. |
| SEC-010 | [PARTIAL] | No RPC URLs with API keys hardcoded (check for rpc.helius.xyz, rpc.ankr.com with keys in URL) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-011 | [PARTIAL] | All secrets loaded from process.env.VARIABLE_NAME | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-012 | [PARTIAL] | Startup validation: all required env vars checked at application boot  fails fast if missing | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-013 | [PARTIAL] | No default fallback values for secrets: process.env.SECRET \|\| "default" is FORBIDDEN | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-014 | [PARTIAL] | NEXT_PUBLIC_ prefix  list all: verify NONE are secrets (these are exposed to browser) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-015 | [PARTIAL] | Backend .env variables NOT prefixed with NEXT_PUBLIC_ | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-016 | [PASS] | .env.example or .env.template exists with variable names but NO actual values | .env.example and .env.sample exist; the latter labels the public Anvil localnet key. |
| SEC-017 | [PARTIAL] | Different env vars for dev/staging/production  verify no cross-contamination | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-018 | [FAIL-3] | .gitignore includes: .env, .env.*, *.pem, *-keypair.json, *-delegate.json, id.json | .gitignore ignores .env but omits defense-in-depth patterns such as .env.*, *.pem, and keypair files. |
| SEC-019 | [PARTIAL] | .gitignore includes: node_modules/, target/, .anchor/, test-ledger/ | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-020 | [PASS] | Run git log --all --diff-filter=A --name-only  check if secrets were EVER committed (even if now deleted) | Git history filename scan found only .env templates, not secret-bearing files. |
| SEC-021 | [PARTIAL] | If any secret was ever committed  it MUST be rotated (deleting from git history is not sufficient) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-022 | [PARTIAL] | Pre-commit hooks: is there a secret detection hook? (gitleaks, detect-secrets, etc.) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-023 | [PARTIAL] | No .env in any branch (check all branches, not just current) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-024 | [PARTIAL] | Commit messages don't contain secrets or API keys | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-025 | [PARTIAL] | Solana RPC URL uses dedicated provider (Helius, Triton, QuickNode)  not api.mainnet-beta.solana.com | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-026 | [PARTIAL] | RPC API key is in backend .env  not exposed in frontend | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-027 | [PARTIAL] | If RPC is needed in frontend  proxied through backend API route | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-028 | [PARTIAL] | Jupiter API key (x-api-key header)  stored in backend env var, not frontend | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-029 | [PARTIAL] | MongoDB connection string  in env var, not in code | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-030 | [PARTIAL] | Any third-party API keys  all in env vars with startup validation | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-031 | [PARTIAL] | API keys are scoped to minimum required permissions (e.g., read-only where possible) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-032 | [PARTIAL] | API key rotation schedule documented (quarterly minimum) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-033 | [PARTIAL] | Program deploy keypair  NOT stored on dev machine for mainnet | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-034 | [PARTIAL] | Program deploy keypair  on hardware wallet (Ledger) or multisig for mainnet | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-035 | [PARTIAL] | Program authority keypair  separate from deploy keypair (defense-in-depth) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-036 | [PARTIAL] | Backend service wallet  holds minimum SOL (only for gas), no other tokens | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-037 | [PARTIAL] | Backend service wallet  private key in env var, not in file | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-038 | [PARTIAL] | Manager wallets  hardware wallet recommended for production | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-039 | [PARTIAL] | Treasury wallet  multisig or hardware wallet | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-040 | [PARTIAL] | Test wallets  separate from production, devnet only | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-041 | [PARTIAL] | Server SSH keys  key-based auth, password auth disabled | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-042 | [PARTIAL] | Server access  2FA enabled for all admin accounts | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-043 | [PARTIAL] | Database credentials  unique per service, not shared | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-044 | [PARTIAL] | TLS certificates  valid and auto-renewed (Let's Encrypt or provider-managed) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-045 | [PARTIAL] | Secrets manager used (AWS SSM, Vault, Doppler) or env vars in hosting platform (Render, Vercel) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-046 | [PARTIAL] | No secrets in CI/CD logs  build processes don't echo env vars | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-047 | [PARTIAL] | Docker images (if used)  no secrets baked into image layers | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-048 | [PARTIAL] | Process exists for emergency key rotation | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-049 | [PARTIAL] | If a key is suspected compromised  documented steps for rotation | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-050 | [PARTIAL] | After key rotation  all services updated atomically (no partial deployment with mixed keys) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-051 | [PARTIAL] | Revoked/rotated keys are actually deactivated (not just removed from source but still valid) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |
| SEC-052 | [PARTIAL] | Key rotation doesn't break dependent services (graceful transition) | Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed. |

### Checklist 13: 13-deployment-infrastructure.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| DEP-001 | [N/A] | Program built with anchor build  not cargo build-sbf directly (ensures Anchor IDL generation) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-002 | [N/A] | Verifiable build: anchor build --verifiable or Docker-based verifiable build | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-003 | [N/A] | Build produces deterministic output  same source  same binary hash | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-004 | [N/A] | Program ID in declare_id!() matches Anchor.toml and deployed program | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-005 | [N/A] | anchor build --ignore-keys NOT used for production builds | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-006 | [N/A] | Legacy IDL accounts (if upgrading from Anchor 0.x) closed before deploying v1.0 | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-007 | [N/A] | Deploy command: solana program deploy with appropriate options (not anchor deploy directly for mainnet) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-008 | [N/A] | Deploy uses dedicated RPC (Helius)  not public mainnet-beta | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-009 | [N/A] | Deploy keypair is the correct one (verified before execution) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-010 | [N/A] | Deploy buffer account  funded with sufficient SOL for the binary size | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-011 | [N/A] | Post-deploy verification: anchor verify or manual binary comparison | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-012 | [N/A] | IDL published: anchor idl init/upgrade  IDL matches deployed program | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-013 | [PARTIAL] | Pre-upgrade checklist executed (all test suites pass, audit findings addressed) | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-014 | [PARTIAL] | Upgrade tested on devnet before mainnet | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-015 | [PARTIAL] | Account data migration plan if struct layouts changed | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-016 | [PARTIAL] | Account migration tested  existing accounts can be deserialized by new program | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-017 | [PARTIAL] | Anchor Migration<'info, From, To> account type used for struct changes | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-018 | [PARTIAL] | Rollback plan documented  what to do if upgrade fails | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-019 | [PASS] | Multisig approval required for upgrade transaction | DeployInvestment transfers Dictionary ownership to the configured Safe multisig. |
| DEP-020 | [PARTIAL] | Timelock period observed before upgrade execution | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-021 | [PARTIAL] | Users notified of upcoming upgrade (changelog, Discord, frontend banner) | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-022 | [N/A] | Backend deployed via CI/CD (not manual ssh && git pull) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-023 | [N/A] | Health check endpoint exists and is monitored | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-024 | [N/A] | Zero-downtime deployment (rolling update or blue-green) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-025 | [N/A] | Environment variables set in hosting platform (Render, Railway, etc.)  not in repo | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-026 | [N/A] | Auto-scaling configured (if traffic warrants) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-027 | [N/A] | Process manager configured (PM2, systemd, or platform-native) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-028 | [N/A] | Graceful shutdown: server closes connections on SIGTERM | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-029 | [N/A] | Database migrations run automatically or as part of deploy pipeline | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-030 | [N/A] | Deployment logs retained for incident investigation | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-031 | [N/A] | Frontend deployed via CI/CD (Vercel, Netlify, or similar) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-032 | [N/A] | Build environment variables set correctly (NEXT_PUBLIC_ vars) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-033 | [N/A] | Production build: next build succeeds without errors | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-034 | [N/A] | No eslint-disable/ts-ignore that masks build errors | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-035 | [N/A] | Source maps configuration: disabled or server-only in production | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-036 | [N/A] | Static assets cached with proper Cache-Control headers | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-037 | [N/A] | Custom domain with valid TLS certificate | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-038 | [N/A] | Redirect HTTP  HTTPS enforced | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-039 | [PARTIAL] | Uptime monitoring: backend health check polled every 1-5 minutes | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-040 | [PARTIAL] | Error rate monitoring: alerts when error rate exceeds threshold | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-041 | [PARTIAL] | Response time monitoring: alerts when latency exceeds threshold | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-042 | [PARTIAL] | On-chain monitoring: alerts for large value movements from fund PDAs | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-043 | [PARTIAL] | On-chain monitoring: alerts for program upgrade authority changes | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-044 | [PARTIAL] | On-chain monitoring: alerts when program is upgraded | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-045 | [N/A] | Database monitoring: connection pool, query latency, disk usage | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-046 | [N/A] | Log aggregation: centralized logging (Datadog, Grafana, CloudWatch, or similar) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-047 | [N/A] | Alert channels: PagerDuty/Slack/Discord for critical alerts | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-048 | [N/A] | Database backups: automated, regular (daily minimum) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-049 | [N/A] | Backup restoration tested (not just backup creation) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-050 | [N/A] | On-chain state: recovery plan if backend database loses sync with on-chain state | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-051 | [N/A] | RPG failover: secondary RPC endpoint configured | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-052 | [N/A] | Region failover: can the backend be deployed to a different region? | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-053 | [N/A] | Contact list: emergency contacts for RPC provider, hosting provider, team members | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-054 | [N/A] | DNS: DNSSEC enabled if available | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-055 | [N/A] | DNS: CAA records restrict which CAs can issue certificates | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-056 | [N/A] | No dangling DNS records pointing to deprovisioned infrastructure (subdomain takeover) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-057 | [N/A] | CDN (if used): proper cache invalidation on deploys | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-058 | [N/A] | DDoS protection: hosting platform or Cloudflare | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-059 | [N/A] | API endpoints not directly exposed (behind reverse proxy or API gateway) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-060 | [FAIL-5] | Automated tests run in CI before deploy (all 8 test suites, 258 tests) | .github/workflows/test.yml is workflow_dispatch-only, so tests are not enforced on pull requests or pushes. |
| DEP-061 | [N/A] | Test environment uses devnet/localnet  NEVER mainnet | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-062 | [N/A] | Test wallets are funded from devnet faucet, not from mainnet wallets | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-063 | [N/A] | Integration tests cover all critical paths (deposit, withdraw, swap, fee) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-064 | [N/A] | Security tests: fuzzing or property-based testing for program instructions | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-065 | [N/A] | Anchor test suite passes with anchor test before every deploy | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-066 | [PARTIAL] | Test coverage tracked  critical paths have >80% coverage | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-067 | [FAIL-4] | CI/CD uses pinned action versions with SHA (actions/checkout@<sha>)  not floating tags (@main, @latest) | GitHub Actions use mutable tags actions/checkout@v4 and foundry-toolchain@v1, not commit SHAs. |
| DEP-068 | [PASS] | CI/CD secrets not accessible in builds triggered by pull requests from forks | The workflow has no pull-request trigger and declares no secret-bearing steps. |
| DEP-069 | [PASS] | GitHub Actions don't execute attacker-controlled strings: no ${{ github.event.issue.title }} in run: blocks (script injection) | No attacker-controlled GitHub event string is interpolated into run blocks. |
| DEP-070 | [PARTIAL] | Third-party CI actions/plugins audited before use  prefer official or verified publishers | Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available. |
| DEP-071 | [PASS] | CI pipeline logs don't print secrets (check for echo $SECRET or debug output) | No workflow step echoes secrets. |
| DEP-072 | [N/A] | Cloud storage buckets (S3, GCS, Azure Blob) are NOT publicly readable or writable  verify with aws s3 ls or equivalent | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-073 | [N/A] | .git directory not accessible in production web server (test: curl https://domain/.git/HEAD) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-074 | [N/A] | Backup files (.bak, .sql, .dump, .old, .swp) not accessible via web server | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-075 | [N/A] | Docker containers run as non-root user with minimal capabilities and read-only filesystem where possible | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-076 | [N/A] | Default credentials changed on ALL services before production deployment (databases, admin panels, queues, caches) | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |
| DEP-077 | [N/A] | Subdomain DNS records point to active services  dangling CNAMEs removed to prevent subdomain takeover | Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository. |

### Checklist 14: 14-python-safety.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| PY-001 | [N/A] | No use of eval() or exec() on user-controlled input | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-002 | [N/A] | No use of os.system() or subprocess.call(shell=True) with user input  use subprocess.run() with shell=False and argument list | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-003 | [N/A] | No string formatting/f-strings used to build SQL queries  use parameterized queries or ORM | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-004 | [N/A] | No pickle.loads() or pickle.load() on untrusted data (arbitrary code execution) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-005 | [N/A] | No yaml.load() without Loader=yaml.SafeLoader (code execution via YAML) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-006 | [N/A] | No marshal.loads() on untrusted data | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-007 | [N/A] | No __import__() with user-controlled module names | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-008 | [N/A] | ast.literal_eval() used instead of eval() when parsing literal data | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-009 | [N/A] | Template engines (Jinja2, Django) have auto-escaping enabled  no \|safe or mark_safe() on user input | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-010 | [N/A] | Regular expressions do not use untrusted input without re.escape() (ReDoS risk) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-011 | [N/A] | No xml.etree.ElementTree or xml.dom.minidom on untrusted XML  use defusedxml (XXE attacks) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-012 | [N/A] | JSON parsing uses json.loads()  never eval() for JSON | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-013 | [N/A] | Passwords hashed with bcrypt, argon2, or scrypt  never MD5/SHA1/SHA256 alone | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-014 | [N/A] | Password comparison uses constant-time hmac.compare_digest()  never == | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-015 | [N/A] | JWT tokens validated with correct algorithm  no algorithms=["none"] | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-016 | [N/A] | JWT secret key not hardcoded  loaded from environment | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-017 | [N/A] | Session tokens have expiration, rotation, and secure cookie flags | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-018 | [N/A] | API endpoints have authentication middleware  no unauthenticated mutation endpoints | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-019 | [N/A] | Role-based access control checks on every protected endpoint | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-020 | [N/A] | No @login_required or equivalent missing on admin/mutation views | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-021 | [N/A] | OAuth/OIDC state parameter validated to prevent CSRF | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-022 | [N/A] | Rate limiting configured on authentication endpoints | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-023 | [N/A] | Django DEBUG = False in production | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-024 | [N/A] | Django SECRET_KEY loaded from env  not in settings.py | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-025 | [N/A] | Django ALLOWED_HOSTS configured  not ['*'] | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-026 | [N/A] | CSRF protection enabled (Django middleware, Flask-WTF, etc.) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-027 | [N/A] | CORS configured with specific origins  not allow_all_origins = True | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-028 | [N/A] | Security headers set (X-Content-Type-Options, X-Frame-Options, HSTS) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-029 | [N/A] | File uploads validated: type, size, filename sanitized, stored outside webroot | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-030 | [N/A] | Static files served by reverse proxy (nginx) in production  not by Python | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-031 | [N/A] | Error pages do not expose stack traces or internal paths in production | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-032 | [N/A] | Logging does not include sensitive data (passwords, tokens, PII) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-033 | [N/A] | FastAPI docs_url and redoc_url disabled or auth-protected in production | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-034 | [N/A] | All database queries use parameterized queries or ORM  no string concatenation | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-035 | [N/A] | Django extra(), raw(), RawSQL() calls reviewed for SQL injection | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-036 | [N/A] | SQLAlchemy text() calls use bound parameters  no f-strings | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-037 | [N/A] | MongoDB (PyMongo) queries validate input types  no $where with user input | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-038 | [N/A] | Database connection strings loaded from env  not hardcoded | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-039 | [N/A] | Database migrations reviewed for data loss operations (drop column, drop table) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-040 | [N/A] | ORM queries checked for N+1 query patterns (select_related/prefetch_related) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-041 | [N/A] | No hardcoded API keys, passwords, or secrets in source code | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-042 | [N/A] | Secrets loaded from env vars or secret manager  validated at startup | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-043 | [N/A] | Cryptographic operations use cryptography library  not pycrypto (unmaintained) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-044 | [N/A] | Random values for security use secrets module  not random (predictable PRNG) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-045 | [N/A] | No hashlib.md5() or hashlib.sha1() for security purposes (passwords, tokens) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-046 | [N/A] | TLS certificate verification enabled  no verify=False in requests calls | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-047 | [N/A] | Private keys never logged, never in error messages, never in API responses | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-048 | [N/A] | .env files in .gitignore  never committed | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-049 | [N/A] | requirements.txt or pyproject.toml pins exact versions (not >= or ~= for critical deps) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-050 | [N/A] | No packages with known CVEs  run pip audit or safety check | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-051 | [N/A] | Virtual environment used  no system-wide pip install | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-052 | [N/A] | No pip install with --trusted-host or --index-url pointing to untrusted registries | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-053 | [N/A] | __init__.py files do not execute code with side effects on import | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-054 | [N/A] | No wildcard imports (from module import *)  pollutes namespace, hides dependencies | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-055 | [N/A] | Dependencies scanned with pip audit  no known vulnerabilities | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-056 | [N/A] | 14-day quarantine rule applied to new package versions (same as npm) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-057 | [N/A] | No bare except: or except Exception: that silently swallows errors | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-058 | [N/A] | Exception handlers log the error  no empty except: pass | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-059 | [N/A] | Type hints used throughout codebase  mypy or pyright configured | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-060 | [N/A] | No typing.Any used where specific types are possible | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-061 | [N/A] | API response schemas validated (Pydantic models for FastAPI, serializers for Django REST) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-062 | [N/A] | Assertion statements (assert) not used for input validation  use explicit checks (assert stripped in -O mode) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-063 | [N/A] | finally blocks used for resource cleanup  no leaked file handles, DB connections | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-064 | [N/A] | No sys.exit() in library code  only in CLI entry points | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-065 | [N/A] | File paths constructed with pathlib.Path  no string concatenation | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-066 | [N/A] | User-supplied filenames sanitized  no path traversal (../../../etc/passwd) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-067 | [N/A] | os.path.join() or Path() used  never concatenation with / | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-068 | [N/A] | Temporary files created with tempfile module  not predictable names in /tmp | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-069 | [N/A] | File permissions set explicitly  no world-readable sensitive files | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-070 | [N/A] | Uploaded files validated server-side (not just client MIME type) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-071 | [N/A] | Shared mutable state protected with locks in threaded code | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-072 | [N/A] | asyncio tasks have proper exception handling  no unhandled task exceptions | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-073 | [N/A] | Database connections properly managed in async context (async connection pool) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-074 | [N/A] | No blocking I/O calls inside async def functions  use run_in_executor | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-075 | [N/A] | Race conditions analyzed for financial operations (double-spend, double-process) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-076 | [N/A] | Private keys loaded from env or hardware wallet  never hardcoded or in repo | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-077 | [N/A] | Transaction simulation before send  simulate_transaction() called first | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-078 | [N/A] | RPC endpoint loaded from env  no hardcoded mainnet URLs | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-079 | [N/A] | Account data validated after deserialization  check discriminator, owner | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-080 | [N/A] | Keypair files excluded from version control (.gitignore) | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-081 | [N/A] | solders or solana-py used  check for known version vulnerabilities | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |
| PY-082 | [N/A] | Anchor IDL parsed correctly  validate instruction names and account counts | Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM. |

### Checklist 15: 15-general-language-safety.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| GL-001 | [FAIL-5] | All external input (HTTP, CLI, file, env) is validated before use  type, length, range, format | RegisterProduct validates raw timestamps but maturity is checked against a midnight-normalized distribution date; PoC passes. |
| GL-002 | [N/A] | No user input directly interpolated into SQL queries  parameterized queries only | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-003 | [N/A] | No user input directly interpolated into shell commands  use argument lists, not string concatenation | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-004 | [N/A] | No user input in eval(), exec(), Function(), or language-equivalent dynamic code execution | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-005 | [N/A] | No user input in template rendering without escaping (server-side template injection) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-006 | [N/A] | No user input in file paths without sanitization (path traversal) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-007 | [N/A] | No user input in redirect URLs without whitelist validation (open redirect) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-008 | [N/A] | No user input in XML parsers without disabling external entities (XXE) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-009 | [N/A] | No user input in regular expressions without escaping (ReDoS) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-010 | [N/A] | No deserialization of untrusted data without validation (Java ObjectInputStream, PHP unserialize, Python pickle, Ruby Marshal) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-011 | [N/A] | HTTP request bodies validated against a schema before processing | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-012 | [N/A] | Content-Type header validated on incoming requests | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-013 | [PASS] | Every mutation endpoint requires authentication | Privileged EVM mutations use Safe/admin/minter checks; user flows bind authority to msg.sender/current NFT owner. |
| GL-014 | [FAIL-6] | Every authenticated endpoint checks authorization (not just "is logged in" but "is allowed to do X") | Duplicate initial minters survive one successful deleteMinter call and remain authorized; executable PoC passes. |
| GL-015 | [N/A] | Password storage uses bcrypt, argon2, or scrypt with sufficient work factor | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-016 | [N/A] | Session tokens are unpredictable, rotated on privilege change, invalidated on logout | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-017 | [N/A] | CSRF protection enabled on state-changing operations | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-018 | [N/A] | Rate limiting on login/registration/password-reset endpoints | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-019 | [N/A] | JWT tokens have expiration, issuer validation, and algorithm pinning (alg: none rejected) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-020 | [N/A] | API keys loaded from environment  never committed to source code | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-021 | [N/A] | Multi-factor authentication available for admin/sensitive operations | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-022 | [N/A] | Account enumeration prevented (same response for valid/invalid usernames) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-023 | [N/A] | No MD5 or SHA1 for security-critical hashing (passwords, MACs, signatures) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-024 | [N/A] | Symmetric encryption uses AES-256-GCM or ChaCha20-Poly1305  not ECB, not CBC without HMAC | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-025 | [N/A] | Random values for security use CSPRNG  not Math.random(), rand(), or predictable sources | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-026 | [N/A] | Constant-time comparison for secrets and tokens  no early-exit string comparison | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-027 | [N/A] | TLS 1.2+ enforced  no fallback to SSL/TLS 1.0/1.1 | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-028 | [N/A] | Certificate validation enabled  no InsecureSkipVerify, verify=False, NODE_TLS_REJECT_UNAUTHORIZED=0 | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-029 | [N/A] | Private keys never logged, never in error messages, never in API responses | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-030 | [N/A] | Key derivation for passwords uses PBKDF2 (10k+ iterations), bcrypt, argon2  not raw hash | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-031 | [N/A] | No stack traces exposed to end users in production | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-032 | [N/A] | No sensitive data in log messages (passwords, tokens, PII, private keys) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-033 | [PASS] | No empty catch/except blocks that silently swallow errors | Solidity failures use explicit custom errors or propagate reverts; no swallowed exceptions. |
| GL-034 | [N/A] | Errors return appropriate HTTP status codes  not always 200 or always 500 | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-035 | [N/A] | Unhandled exceptions have a global handler that logs and returns safe error | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-036 | [PASS] | Panic/abort behavior understood  does it crash the whole process? | EVM reverts atomically; value-moving paths use checked Solidity 0.8 arithmetic and nonReentrant guards. |
| GL-037 | [N/A] | Structured logging used  not string concatenation with secrets | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-038 | [N/A] | Log injection prevented  newlines and control chars stripped from user data in logs | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-039 | [N/A] | [C/C++] No buffer overflows  bounds checking on all array/buffer access | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-040 | [N/A] | [C/C++] No use-after-free  ownership/lifetime tracking | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-041 | [N/A] | [C/C++] No format string vulnerabilities  printf(user_input) without format spec | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-042 | [N/A] | [Go] No goroutine leaks  all goroutines have exit conditions | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-043 | [N/A] | [Go] No race conditions  go vet -race clean | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-044 | [N/A] | [Java] No resource leaks  try-with-resources for closeable resources | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-045 | [N/A] | [Ruby/PHP] No memory leaks in long-running processes | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-046 | [N/A] | [All] File handles, DB connections, network sockets closed after use | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-047 | [N/A] | [All] Timeouts configured for all external calls (HTTP, DB, RPC) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-048 | [N/A] | [All] Request/response size limits enforced  no unbounded allocation from user input | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-049 | [PASS] | Financial operations are atomic  no TOCTOU (time-of-check-time-of-use) bugs | Financial state updates are transaction-atomic and value-moving public paths use shared ReentrancyGuard storage. |
| GL-050 | [N/A] | Database operations use transactions for multi-step updates | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-051 | [N/A] | Shared mutable state protected by locks/mutexes/channels | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-052 | [N/A] | No deadlocks from nested lock acquisition (consistent lock ordering) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-053 | [N/A] | Optimistic concurrency (version fields) used where appropriate | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-054 | [N/A] | Rate limiters work correctly under concurrent requests (atomic counters) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-055 | [N/A] | CORS allows only specific trusted origins  not * | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-056 | [N/A] | Security headers set: CSP, X-Content-Type-Options, X-Frame-Options, HSTS, Referrer-Policy | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-057 | [N/A] | HTTP  HTTPS redirect in production | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-058 | [N/A] | Response does not leak server version (X-Powered-By, Server header) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-059 | [N/A] | GraphQL: depth/complexity limits set if applicable | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-060 | [N/A] | WebSocket connections authenticated and rate-limited | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-061 | [N/A] | Outbound HTTP requests validate response (don't trust external API blindly) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-062 | [N/A] | DNS rebinding protection if applicable (validate Host header) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-063 | [N/A] | Debug mode disabled in production | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-064 | [N/A] | Default credentials changed (database, admin panels, third-party tools) | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-065 | [N/A] | Unnecessary ports/services disabled | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-066 | [PASS] | Dependency versions pinned  lockfile committed | npm and Foundry locks plus pinned git submodule commits are committed. |
| GL-067 | [N/A] | No sudo or root privileges unless required | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-068 | [N/A] | Docker images use non-root user, minimal base image, no secrets in layers | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-069 | [N/A] | Environment variables validated at startup  fail fast if critical ones missing | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-070 | [N/A] | Health check endpoint does not expose sensitive internal state | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-071 | [N/A] | err return values always checked  no _, _ = someFunc() | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-072 | [N/A] | No unsafe package usage without justification | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-073 | [N/A] | context.Context used for cancellation/timeouts on all I/O | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-074 | [N/A] | defer used for cleanup  not relying on manual close calls | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-075 | [N/A] | No Runtime.exec() with string concatenation  use ProcessBuilder with arg list | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-076 | [N/A] | Deserialization restricted  ObjectInputFilter configured or avoided entirely | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-077 | [N/A] | Spring Security configured  default deny, explicit allow | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-078 | [N/A] | No @CrossOrigin("*") on controllers | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-079 | [N/A] | Rails strong_parameters used  no params.permit! | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-080 | [N/A] | No send() with user input  public_send() at minimum | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-081 | [N/A] | Brakeman scan clean | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-082 | [N/A] | Gems version-pinned in Gemfile.lock | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-083 | [N/A] | No include($user_input)  file inclusion vulnerability | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-084 | [N/A] | display_errors = Off in production | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-085 | [N/A] | PDO with prepared statements  no mysql_query() or string concatenation | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-086 | [N/A] | htmlspecialchars() used on all output  XSS prevention | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-087 | [N/A] | No prototype pollution  user input not used as dynamic property key (obj[userKey] = value) without __proto__/constructor check | Web/server/native-language pattern is not used by the Solidity contract scope. |
| GL-088 | [N/A] | No user-controlled values in HTTP response headers  strip newlines and control characters (header injection / response splitting) | Web/server/native-language pattern is not used by the Solidity contract scope. |

### Checklist 16: 16-formal-verification-testing.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| FV-001 | [PASS] | Critical state invariants are documented (e.g. "total shares == sum of all investor shares") | x-ray/invariants.md documents product, pool, escrow, cursor, and entitlement invariants. |
| FV-002 | [PARTIAL] | Invariant properties are encoded as assertions or property-based tests | Many regressions and fuzz-style tests exist, but no stateful Foundry invariant harness encodes the full conservation model. |
| FV-003 | [PARTIAL] | Every arithmetic identity the protocol relies on has a proof or exhaustive test | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-004 | [PARTIAL] | State transition properties are specified: from every valid state, only valid transitions can occur | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-005 | [PARTIAL] | No reachable state violates documented invariants (tested via model checking or fuzzing) | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-006 | [PARTIAL] | Token conservation property verified: tokens in == tokens out across all instruction paths | Accounting paths and regressions were reviewed, but token conservation is not encoded as one stateful property. |
| FV-007 | [PARTIAL] | Authority properties verified: only authorized signers can reach privileged instructions | Negative authorization tests exist; no formal authority property checker is present. |
| FV-008 | [PARTIAL] | Liveness properties checked: every initiated process can reach completion (no deadlocks) | Lifecycle scenario tests exist; no model-checking or stateful liveness proof is present. |
| FV-009 | [PARTIAL] | Formal specs (if any) are kept in sync with code  spec drift is tracked | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-010 | [PARTIAL] | Mathematical proofs are machine-checked (Coq, Lean, SMT solver) when claiming "proven" | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-011 | [PARTIAL] | Custom formal verification properties are documented alongside the code they verify | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-012 | [PARTIAL] | Verification results are included in audit reports with pass/fail status | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-013 | [FAIL-5] | At least one static analysis tool runs in CI (e.g. Clippy, ESLint security rules, Semgrep, Slither) | No Slither, Semgrep, or equivalent Solidity SAST runs in CI. |
| FV-014 | [PARTIAL] | Static analysis findings are triaged  no unreviewed suppressions | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-015 | [PARTIAL] | Custom lint rules enforce project conventions (e.g. no any, no unwrap in production) | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-016 | [PARTIAL] | Compiler/linter warnings are treated as errors in CI  zero-warning policy | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-017 | [PARTIAL] | Security-focused rulesets are enabled (e.g. clippy::pedantic, eslint-plugin-security) | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-018 | [PARTIAL] | Dead code detection is enforced  unused functions/imports are flagged | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-019 | [FAIL-5] | Dependency vulnerability scanning runs in CI (e.g. cargo audit, npm audit, safety) | Dependency vulnerability scanning does not run in CI, although local npm audit was clean. |
| FV-020 | [FAIL-5] | SAST (Static Application Security Testing) covers all production languages in the repo | No automated SAST covers production Solidity in CI. |
| FV-021 | [PARTIAL] | No static analysis suppression comments without a justification comment | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-022 | [PARTIAL] | Static analysis config files are version-controlled and reviewed on change | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-023 | [PARTIAL] | Fuzz testing is implemented for all parsing/deserialization functions | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-024 | [PARTIAL] | On-chain instruction handlers have fuzz targets covering malicious inputs | Stateless Foundry fuzz tests exist, but no stateful malicious-sequence fuzz target covers all entry points. |
| FV-025 | [PARTIAL] | Fuzz corpus is persisted and grows over time (not regenerated from scratch each run) | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-026 | [PARTIAL] | Fuzz campaigns have run for meaningful duration (not just quick smoke tests) | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-027 | [PARTIAL] | Crashes found by fuzzing are triaged, fixed, and regression tests added | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-028 | [PARTIAL] | Differential fuzzing is used where two implementations should agree (e.g. old vs new version) | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-029 | [PASS] | Fuzz testing covers arithmetic edge cases: MAX, MIN, 0, 1, near-overflow values | Yield and lifecycle fuzz tests exercise zero, minimum, maximum, and near-boundary values. |
| FV-030 | [PARTIAL] | API endpoints are fuzzed with malformed/oversized/unexpected payloads | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-031 | [PARTIAL] | Serialization round-trip fuzz: encode  decode  re-encode produces identical bytes | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-032 | [PARTIAL] | Fuzz testing infrastructure is documented and reproducible | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-033 | [FAIL-4] | Test coverage is measured and reported (line coverage, branch coverage) | Coverage cannot compile: normal mode is stack-too-deep and --ir-minimum hits a Yul stack exception. |
| FV-034 | [PARTIAL] | Critical paths (fund creation, deposit, withdrawal, swap) have  90% branch coverage | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-035 | [PARTIAL] | Unit tests exist for every public function/instruction | Broad unit coverage exists, but coverage tooling cannot prove every public selector is exercised. |
| FV-036 | [PASS] | Integration tests cover multi-step workflows (e.g. create  deposit  swap  withdraw) | Multi-step scenario tests cover registration, investment, distributions, maturity, and claims. |
| FV-037 | [PASS] | Edge case tests: zero amounts, max amounts, empty collections, boundary values | Zero-yield, month-end, leap-year, batching, empty-product, and escrow boundary tests exist. |
| FV-038 | [PASS] | Negative tests: unauthorized callers, invalid states, rejected transactions | Unauthorized caller and invalid-state negative tests are present across privileged and user flows. |
| FV-039 | [PASS] | Regression tests exist for every previously-found bug | docs/audit/fix findings have matching regression tests under test/fix for material remediations. |
| FV-040 | [FAIL-6] | Tests run in CI on every PR  no merge without green tests | CI tests are manual-only and therefore do not gate pull requests or protected-branch changes. |
| FV-041 | [PARTIAL] | Test environment mirrors production config (same runtime version, same flags) | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-042 | [PARTIAL] | Flaky tests are tracked and fixed  no tests in permanent skip/ignore state without justification | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-043 | [PARTIAL] | Mutation testing has been run at least once to validate test suite effectiveness | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-044 | [PARTIAL] | Performance/load tests exist for critical endpoints to prevent DoS via expensive operations | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-045 | [PASS] | Tests do not use hardcoded secrets, private keys, or real credentials | Tests use mocks and the documented public Anvil localnet key only; no real credential is present. |
| FV-046 | [PASS] | Test data is deterministic or seeded  tests are reproducible across environments | Foundry tests are deterministic; fuzz runs are reproducible through Foundry seeds when supplied. |
| FV-047 | [FAIL-5] | All external calls (network, DB, filesystem, CPI) have explicit error handling | PurchasePermissionLib does not catch reverting ERC165/SBT calls, allowing one dependency to block a whole tier; PoC passes. |
| FV-048 | [PARTIAL] | Error messages do not leak internal paths, versions, stack traces, or database schemas | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-049 | [PARTIAL] | Panics/unhandled exceptions in production code are caught at the boundary and logged | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-050 | [PARTIAL] | Errors are distinguished: client errors (4xx) vs server errors (5xx)  no catch-all 500 | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-051 | [PARTIAL] | Resource exhaustion is handled gracefully: OOM, disk full, connection pool exhausted | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-052 | [PARTIAL] | Timeout handling exists for all external calls  no unbounded waits | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-053 | [PASS] | Partial failure in multi-step operations is handled (rollback, compensation, or idempotent retry) | Failed push transfers move liabilities into escrow and claim paths preserve state on transfer failure. |
| FV-054 | [PASS] | Error handling does not silently swallow errors  all catch blocks log or propagate | External failures are propagated or converted to explicit escrow branches; no silent catch exists. |
| FV-055 | [PASS] | On-chain programs return specific error codes, not generic "ProgramError" | Contracts expose specific custom errors in IInvestmentErrors and periphery interfaces. |
| FV-056 | [PARTIAL] | Error types are exhaustive  match/switch on error kinds covers all variants | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-057 | [PARTIAL] | Circuit breakers or fallbacks exist for critical external dependencies | Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists. |
| FV-058 | [PASS] | Exceptional conditions in financial math (divide-by-zero, negative balances) are blocked, not wrapped | Solidity 0.8 checked arithmetic blocks overflow/underflow and divisors are constrained by product state. |

### Checklist 17: 17-logging-monitoring-incident-response.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| LM-001 | [PARTIAL] | Every state-changing on-chain instruction emits an event with relevant parameters | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-002 | [PARTIAL] | Events include the actor (signer/authority) who triggered the state change | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-003 | [PARTIAL] | Events include both old and new values for critical state fields (e.g. fund status, NAV) | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-004 | [PASS] | Financial events (deposit, withdrawal, swap, fee collection) include amounts and token mints | Invested, YieldReceived/Distributed, InvestmentReturned, Deposited, and Withdrawn events include amounts and identifiers. |
| LM-005 | [PASS] | Admin/governance events (config change, pause, authority transfer) are emitted and indexed | Role, tier, product, recovery, and metadata administration emit dedicated events. |
| LM-006 | [PARTIAL] | Failed operations emit distinct error events (not just silent returns) | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-007 | [N/A] | Backend API endpoints log request metadata: timestamp, IP/wallet, method, path, status code | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-008 | [N/A] | Authentication events are logged: login success, login failure, token refresh, logout | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-009 | [N/A] | Authorization failures are logged with the denied action and the caller identity | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-010 | [N/A] | Database mutations (create, update, delete) have audit trail: who, when, what changed | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-011 | [PARTIAL] | Event/log schemas are documented and versioned  breaking changes are tracked | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-012 | [N/A] | Log entries are structured (JSON) not free-text  parseable by automated systems | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-013 | [PASS] | Events are not emitted for operations that did NOT actually change state (no misleading events) | Events follow successful state paths; reverted transactions cannot retain misleading logs. |
| LM-014 | [PARTIAL] | On-chain events use indexed fields for efficient querying (e.g. fund address, manager) | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-015 | [N/A] | All security-relevant events are logged: auth, access control, input validation failures | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-016 | [PARTIAL] | Logs do NOT contain secrets: passwords, tokens, private keys, session IDs, PII | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-017 | [N/A] | Logs do NOT contain raw user input that could enable log injection attacks | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-018 | [N/A] | Log entries include correlation IDs to trace a request across services | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-019 | [N/A] | Log levels are properly used: ERROR for failures, WARN for anomalies, INFO for operations | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-020 | [N/A] | Logs cannot be tampered with: append-only storage, or signed/checksummed entries | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-021 | [N/A] | Log retention period is defined and enforced (minimum 90 days for security events) | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-022 | [N/A] | Logs are stored separately from the application  not on the same volume/service | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-023 | [N/A] | Rate-limit violation events are logged with source IP/wallet | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-024 | [N/A] | Transaction signature verification failures are logged with full context | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-025 | [N/A] | Server-side logging exists (not just client-side console.log) | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-026 | [N/A] | Log volume is manageable  no debug-level logging in production flooding storage | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-027 | [N/A] | Runtime health monitoring exists: uptime, response time, error rate, CPU/memory | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-028 | [PARTIAL] | On-chain monitoring tracks critical program state changes in real-time | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-029 | [PARTIAL] | Vault/treasury balance is monitored with alerts for unexpected decreases | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-030 | [PARTIAL] | Anomaly detection for unusual transaction patterns: large withdrawals, rapid-fire calls | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-031 | [N/A] | Alerting is configured for error rate spikes (e.g. > 5% 5xx in 5 minutes) | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-032 | [PARTIAL] | Alerts have defined severity levels and escalation paths (page on critical, email on warn) | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-033 | [PARTIAL] | Alert fatigue is managed: no noisy alerts that are routinely ignored | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-034 | [N/A] | External dependency health is monitored: RPC nodes, databases, third-party APIs | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-035 | [N/A] | SSL/TLS certificate expiry is monitored with advance alerts ( 30 days before expiry) | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-036 | [N/A] | Domain/DNS changes are monitored for unauthorized modifications | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-037 | [PARTIAL] | Program upgrade authority changes are monitored and alerted on-chain | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-038 | [PARTIAL] | Token mint authority usage is monitored  unexpected mints trigger immediate alerts | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-039 | [N/A] | Monitoring dashboards are accessible to the team (not just one person) | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-040 | [N/A] | Monitoring systems themselves have redundancy  single monitoring failure doesn't blind the team | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-041 | [FAIL-4] | Incident response plan exists and is documented | No incident-response plan or runbook was found in the repository. |
| LM-042 | [PARTIAL] | IR plan defines roles: who leads response, who communicates, who patches | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-043 | [FAIL-3] | Emergency pause mechanism exists for on-chain program (freeze fund operations) | No emergency pause/circuit-breaker is implemented for contract operations. |
| LM-044 | [PARTIAL] | Emergency pause can be triggered by multisig, not just a single key | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-045 | [PARTIAL] | Communication plan exists: how to notify users, where to post status updates | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-046 | [PARTIAL] | Contact list for IR team is maintained and up-to-date (not stale) | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-047 | [PARTIAL] | Post-mortem process is defined: root cause analysis, timeline, lessons learned | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-048 | [PARTIAL] | Post-mortems are published (at least internally) and action items are tracked to completion | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-049 | [PARTIAL] | IR plan has been practiced (tabletop exercise or drill) at least once | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-050 | [PARTIAL] | Evidence preservation protocol exists for potential legal/forensic needs | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-051 | [PARTIAL] | Bug bounty program or responsible disclosure policy is published | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-052 | [PARTIAL] | IR plan covers both on-chain exploits and off-chain compromises (backend, keys, DNS) | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-053 | [N/A] | Backup strategy is documented: what is backed up, frequency, retention period | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-054 | [N/A] | Database backups are tested for restore  at least one successful restore test documented | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-055 | [N/A] | Recovery Time Objective (RTO) and Recovery Point Objective (RPO) are defined for each service | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-056 | [N/A] | Backup data is encrypted at rest and in transit | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-057 | [N/A] | Backups are stored in a different region/provider from production (geographic redundancy) | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-058 | [PARTIAL] | On-chain program state can be reconstructed from events/transactions (event sourcing capability) | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-059 | [N/A] | Failover procedure for critical infrastructure is documented and tested | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-060 | [N/A] | RPC endpoint failover: application switches to backup RPC on primary failure | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |
| LM-061 | [PARTIAL] | Key recovery procedure exists: what happens if a deploy key is lost/compromised | On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo. |
| LM-062 | [N/A] | Business continuity plan covers extended outage (>24h)  manual processes, user communication | Backend/log-storage/hosting control is outside the Solidity-only repository scope. |

### Checklist 18: 18-privacy-compliance-change-management.md

| ID | Verdict | Check | Evidence |
|---|---|---|---|
| PC-001 | [N/A] | All personal data (PII) collected by the application is inventoried and documented | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-002 | [N/A] | Each PII field has a stated purpose  no collection without justification | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-003 | [N/A] | Data minimization: only the minimum necessary PII is collected for each purpose | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-004 | [N/A] | User consent mechanism exists for PII collection (opt-in, not opt-out) where required | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-005 | [N/A] | Privacy policy is published, accessible, and accurately describes data practices | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-006 | [N/A] | PII is encrypted at rest in databases (field-level or full-disk encryption) | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-007 | [N/A] | PII is encrypted in transit (TLS 1.2+ for all endpoints handling personal data) | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-008 | [N/A] | Data retention policy exists: PII is deleted after its stated retention period | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-009 | [N/A] | Right to deletion: mechanism exists for users to request erasure of their data | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-010 | [N/A] | Right to access: users can export/view their stored personal data | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-011 | [N/A] | Cross-border data transfers comply with applicable regulations (e.g. GDPR adequacy) | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-012 | [N/A] | Wallet addresses are treated as pseudonymous identifiers  linked PII gets full protection | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-013 | [N/A] | KYC/identity data (if collected) has stricter access controls than general app data | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-014 | [N/A] | PII is not logged in plaintext in application logs | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-015 | [PARTIAL] | Applicable regulations are identified and documented (e.g. GDPR, MiCA, DORA, SOC 2) | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-016 | [PARTIAL] | Each regulation's requirements are mapped to specific controls in the codebase | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-017 | [PARTIAL] | OWASP Top 10 (2025) categories are mapped to project security controls | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-018 | [PARTIAL] | SOC 2 Trust Service Criteria applicability is assessed: Security, Availability, Confidentiality, Processing Integrity, Privacy | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-019 | [PARTIAL] | Compliance documentation is version-controlled and reviewed periodically | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-020 | [PARTIAL] | Regulatory changes are tracked  process exists to update controls when laws change | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-021 | [PARTIAL] | Third-party compliance dependencies are documented (e.g. cloud provider SOC 2 reports) | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-022 | [PARTIAL] | Financial regulations applicable to DeFi in target jurisdictions are identified | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-023 | [PARTIAL] | AML/KYC requirements are assessed and implemented if the product requires them | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-024 | [PARTIAL] | Terms of Service exist and are legally reviewed | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-025 | [PARTIAL] | Geographic restrictions (geofencing) are implemented where regulations require | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-026 | [PARTIAL] | Compliance status is tracked in a living document, not just at audit time | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-027 | [PASS] | All production changes go through version control (Git)  no direct production edits | Repository and deployment artifacts are version controlled. |
| PC-028 | [PARTIAL] | Pull request / merge request required for all production branch changes | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-029 | [PARTIAL] | Code review by at least one independent reviewer before merge to production branch | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-030 | [PARTIAL] | Security-sensitive changes require review by a security-aware team member | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-031 | [FAIL-5] | CI/CD pipeline runs automated tests before deployment is allowed | Automated tests are not triggered on pull requests or pushes by the current workflow. |
| PC-032 | [PARTIAL] | Deployment to production requires explicit approval (not auto-deploy on merge) | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-033 | [PARTIAL] | Rollback procedure is documented and tested  can revert to previous version within RTO | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-034 | [PASS] | On-chain program upgrades follow documented approval process (multisig for mainnet) | The deployment script transfers upgrade Dictionary ownership to the configured Safe multisig. |
| PC-035 | [N/A] | Database migrations are reviewed, reversible where possible, and tested in staging | No database or migration layer exists in repository scope. |
| PC-036 | [FAIL-3] | Changelog is maintained documenting all significant changes with dates and authors | No CHANGELOG file was found. |
| PC-037 | [PARTIAL] | Emergency hotfix process exists with post-hoc review requirement | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-038 | [PARTIAL] | Feature flags / environment separation prevents untested code from reaching production | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-039 | [PARTIAL] | Access to production deployment is restricted to authorized personnel only | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-040 | [PARTIAL] | Third-party dependency updates follow a review process (not auto-merged) | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-041 | [PASS] | External penetration test has been performed at least once before mainnet launch | A third-party audit PDF and tracked remediation set are present under docs/audit/. |
| PC-042 | [N/A] | Pentest scope covered: web application, API endpoints, authentication flows | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-043 | [PASS] | Pentest scope covered: on-chain program interactions (crafted transactions, edge cases) | On-chain crafted edge cases and prior findings have regression/PoC coverage. |
| PC-044 | [N/A] | Pentest scope covered: cloud infrastructure and server configuration | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-045 | [PARTIAL] | Pentest findings are tracked to resolution with re-test confirmation | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-046 | [PARTIAL] | Pentest report is retained and available for compliance/audit purposes | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-047 | [N/A] | Automated security scanning (DAST) runs periodically against live environments | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-048 | [N/A] | API security testing covers: auth bypass, rate limiting, injection, IDOR, mass assignment | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-049 | [PARTIAL] | Wallet/key management security has been tested: key storage, signing process, recovery | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-050 | [PARTIAL] | Attack surface inventory exists: all public endpoints, on-chain entry points, admin interfaces | Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation. |
| PC-051 | [N/A] | LLM/AI integrations sanitize all outputs before using in code execution or database queries | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-052 | [N/A] | Prompt injection defenses exist: user input is not directly concatenated into system prompts | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-053 | [N/A] | AI-generated content is labeled as such when shown to users | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-054 | [N/A] | AI model outputs are validated against expected schemas before downstream processing | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-055 | [N/A] | AI/ML model access is authenticated  no unauthenticated inference endpoints | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-056 | [N/A] | Training data does not contain secrets, private keys, or sensitive PII | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-057 | [N/A] | Rate limiting is applied to AI/ML inference endpoints to prevent abuse/cost attacks | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-058 | [N/A] | AI decision explanations are logged for auditability when used in financial decisions | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-059 | [N/A] | Adversarial input testing has been performed on AI components | No backend PII store, database, web API, or AI/ML component exists in scope. |
| PC-060 | [N/A] | AI/ML dependencies are pinned and audited like any other third-party code | No backend PII store, database, web API, or AI/ML component exists in scope. |

### Audit Metrics

| Metric | Value |
|---|---:|
| Total items evaluated | 1182 |
| PASS | 48 |
| FAIL | 15 |
| PARTIAL | 170 |
| N/A | 949 |
| Highest severity | 6 |
| Repository Risk Score | 6 |

## Known Vector Results

| Vector | Verdict | Evidence |
|---|---|---|
| KV-001 Private Key Leak | [PASS] | Current-source and git-history scans found no live secret; only empty templates and the labeled public Anvil localnet key. |
| KV-002 Flash Loan Price Manipulation | [N/A] | No oracle, collateral pricing, AMM, lending, or NAV mechanism. |
| KV-003 Reentrancy (CPI) | [PASS] | Value-moving entry points use ReentrancyGuard; failed push transfers use escrow and state is transaction-atomic. |
| KV-004 Missing Access Control | [FAIL-6] | Duplicate initial minters survive one revocation and remain authorized; see F-001 and passing PoC. |
| KV-005 Oracle Manipulation | [N/A] | No price oracle is used. |
| KV-006 First Depositor / Share Inflation | [N/A] | No fungible vault share accounting or ERC4626 conversion exists. |
| KV-007 MEV Sandwich Attack | [N/A] | No swap or price-sensitive trade exists. |
| KV-008 Rug Pull / Admin Backdoor | [PARTIAL] | Admins can withdraw productPool only to the configured Safe by design; upgrades are Safe-owned, but no timelock is evidenced. |
| KV-009 Unchecked CPI Target | [N/A] | Solana CPI target model is not used. |
| KV-010 PDA Confusion / Type Cosplay | [N/A] | Solana PDA/account discriminator model is not used. |
| KV-011 Integer Overflow / Underflow | [PASS] | Solidity 0.8 checked arithmetic reverts on overflow/underflow; reviewed financial state transitions use bounded state preconditions. |
| KV-012 Arithmetic Rounding Exploit | [PASS] | Yield rounding is explicit and tolerance-accounted; fuzz and batch tests pass. |
| KV-013 Missing Signer Check | [N/A] | Solana signer model is not used; EVM authorization is covered by KV-004. |
| KV-014 Account Reinitialization | [PASS] | Initializable prevents repeat initialization; implementation initializers are disabled and proxy deployment includes atomic init calldata. |
| KV-015 Unchecked Account Owner | [N/A] | Solana account-owner substitution does not apply. |
| KV-016 Token Account Mismatch | [PASS] | One configured USDT token is used; sources and recipients are contract-defined or msg.sender/current owner. |
| KV-017 Vault Donation Attack | [N/A] | No ERC4626/share-price vault balance conversion exists. |
| KV-018 Fee-on-Transfer Token Exploit | [PASS] | Protocol intentionally supports a fixed USDT-like token, not arbitrary fee-on-transfer assets; this assumption must remain deployment-enforced. |
| KV-019 Freeze Authority Griefing | [PARTIAL] | Recipient blacklist failures escrow claims, but issuer-wide freeze remains an external USDT dependency risk. |
| KV-020 Program Upgrade Hijack | [PARTIAL] | Upgrade ownership is transferred to a Safe multisig; no timelock or deployed-bytecode verification evidence was available. |
| KV-021 Governance Attack (Vote Buying) | [N/A] | No token governance/voting mechanism. |
| KV-022 Bridge Exploit (Fake Proof) | [N/A] | No bridge or cross-chain proof flow. |
| KV-023 Token-2022 Transfer Hook Attack | [N/A] | Solana Token-2022 is not used. |
| KV-024 Stale/Missing Account Close | [N/A] | Solana rent/account-close model is not used; ERC721 burns are explicitly handled. |
| KV-025 Compute Budget Exhaustion DoS | [PARTIAL] | NFT payout loops are capped at 50, but active-product enumeration remains linear and has no explicit protocol cap. |
| KV-026 PDA Seed Collision | [N/A] | No Solana PDA seeds; CREATE2 salt is productId-scoped and product IDs are unique. |
| KV-027 Missing Discriminator Check | [N/A] | No Anchor discriminator model. |
| KV-028 Front-Running Transaction | [PASS] | No market-price execution exists; bearer NFT transfer timing is explicitly documented as intended. |
| KV-029 Withdraw-Before-Update Race | [N/A] | No NAV-based withdrawal flow. |
| KV-030 Infinite Mint / Uncapped Supply | [PASS] | NFT minting is owner-only and investment amount/total raised are capped by product offering constraints; minter revocation defect is separately F-001. |
| KV-031 NoSQL Injection (MongoDB) | [N/A] | No backend or frontend application exists in repository scope. |
| KV-032 SQL Injection | [N/A] | No backend or frontend application exists in repository scope. |
| KV-033 Mass Assignment (Vibe Coding) | [N/A] | No backend or frontend application exists in repository scope. |
| KV-034 BaaS Auth Bypass (Supabase/Firebase) | [N/A] | No backend or frontend application exists in repository scope. |
| KV-035 JWT Algorithm Confusion | [N/A] | No backend or frontend application exists in repository scope. |
| KV-036 SSRF (Server-Side Request Forgery) | [N/A] | No backend or frontend application exists in repository scope. |
| KV-037 CORS Misconfiguration | [N/A] | No backend or frontend application exists in repository scope. |
| KV-038 IDOR (Insecure Direct Object Reference) | [N/A] | No backend or frontend application exists in repository scope. |
| KV-039 Rate Limiting Bypass | [N/A] | No backend or frontend application exists in repository scope. |
| KV-040 Command Injection | [N/A] | No backend or frontend application exists in repository scope. |
| KV-041 Path Traversal / LFI | [N/A] | No backend or frontend application exists in repository scope. |
| KV-042 XML External Entity (XXE) | [N/A] | No backend or frontend application exists in repository scope. |
| KV-043 Prototype Pollution | [N/A] | No backend or frontend application exists in repository scope. |
| KV-044 Server-Side Template Injection | [N/A] | No backend or frontend application exists in repository scope. |
| KV-045 Webhook Forgery | [N/A] | No backend or frontend application exists in repository scope. |
| KV-046 GraphQL Introspection / Depth Attack | [N/A] | No backend or frontend application exists in repository scope. |
| KV-047 WebSocket Hijacking | [N/A] | No backend or frontend application exists in repository scope. |
| KV-048 ReDoS (Regex Denial of Service) | [N/A] | No backend or frontend application exists in repository scope. |
| KV-049 HTTP Response Splitting | [N/A] | No backend or frontend application exists in repository scope. |
| KV-050 Session Fixation | [N/A] | No backend or frontend application exists in repository scope. |
| KV-051 Account Enumeration | [N/A] | No backend or frontend application exists in repository scope. |
| KV-052 Unbounded Request Body DoS | [N/A] | No backend or frontend application exists in repository scope. |
| KV-053 Missing Wallet Signature Verification | [N/A] | No backend or frontend application exists in repository scope. |
| KV-054 Default Credentials in Production | [N/A] | No backend or frontend application exists in repository scope. |
| KV-055 Exposed Debug/Admin Endpoints | [N/A] | No backend or frontend application exists in repository scope. |
| KV-056 XSS via SVG / Image Injection | [N/A] | No backend or frontend application exists in repository scope. |
| KV-057 Stored XSS (User Content) | [N/A] | No backend or frontend application exists in repository scope. |
| KV-058 DOM-Based XSS | [N/A] | No backend or frontend application exists in repository scope. |
| KV-059 Clickjacking | [N/A] | No backend or frontend application exists in repository scope. |
| KV-060 OAuth State Forgery (CSRF via OAuth) | [N/A] | No backend or frontend application exists in repository scope. |
| KV-061 Sensitive Data in URL Parameters | [N/A] | No backend or frontend application exists in repository scope. |
| KV-062 Client-Side Auth Bypass | [N/A] | No backend or frontend application exists in repository scope. |
| KV-063 PostMessage Origin Bypass | [N/A] | No backend or frontend application exists in repository scope. |
| KV-064 LocalStorage Token Theft | [N/A] | No backend or frontend application exists in repository scope. |
| KV-065 Clipboard Hijacking (Crypto Address) | [N/A] | No backend or frontend application exists in repository scope. |
| KV-066 CSS Exfiltration | [N/A] | No backend or frontend application exists in repository scope. |
| KV-067 Wallet Blind Signing Exploit | [N/A] | No backend or frontend application exists in repository scope. |
| KV-068 Subresource Integrity Bypass | [N/A] | No backend or frontend application exists in repository scope. |
| KV-069 Third-Party Script Compromise | [N/A] | No backend or frontend application exists in repository scope. |
| KV-070 Open Redirect | [N/A] | No backend or frontend application exists in repository scope. |
| KV-071 Missing CSP (Content Security Policy) | [N/A] | No backend or frontend application exists in repository scope. |
| KV-072 API Key Exposure in Client Bundle | [N/A] | No backend or frontend application exists in repository scope. |
| KV-073 Dangling DNS / Subdomain Takeover | [N/A] | No backend or frontend application exists in repository scope. |
| KV-074 Insecure External Link (no rel) | [N/A] | No backend or frontend application exists in repository scope. |
| KV-075 Console Data Leak in Production | [N/A] | No backend or frontend application exists in repository scope. |
| KV-076 Dependency Confusion (Substitution Attack) | [PASS] | No private npm packages; package lock and pinned gitlinks are committed. |
| KV-077 Malicious npm Package (Typosquatting) | [PASS] | Two direct npm dev dependencies were reviewed and npm audit found zero vulnerabilities. |
| KV-078 Secrets in Git History | [PASS] | History scan found no real secret-bearing file or credential content; template files are non-production. |
| KV-079 .env File Committed to Repo | [PASS] | No populated .env file is tracked; .env is ignored and templates are intentionally committed. |
| KV-080 CI/CD Pipeline Injection | [FAIL-4] | Workflow actions use mutable tags and CI is manual-only; see F-004. |
| KV-081 Insecure Docker Configuration | [N/A] | No Dockerfile or container deployment configuration. |
| KV-082 Exposed Admin / Debug Endpoints in Production | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-083 Missing Rate Limiting on Critical Endpoints | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-084 Prototype Pollution | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-085 Server-Side Request Forgery (SSRF) | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-086 Insecure Deserialization | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-087 Insufficient Logging & Monitoring | [PARTIAL] | Contract events are broad, but no live monitoring or incident-response configuration is present in-repo. |
| KV-088 Insecure CORS Configuration | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-089 Unpatched Server Dependencies | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-090 Missing HTTPS / TLS Misconfiguration | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-091 Upgrade Authority Not Secured | [PARTIAL] | Safe multisig owns the upgrade Dictionary, but timelock and live authority verification were not available. |
| KV-092 DNS Hijacking / Domain Takeover | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-093 Improper Error Handling (Error Leak) | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-094 Missing Input Length Limits | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-095 Insecure Randomness | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-096 Missing Security Headers | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-097 Stale / Leaked Development Credentials | [PASS] | .env.sample contains only the explicitly labeled public Anvil localnet default key, not a production credential. |
| KV-098 Broken Access Control on API Endpoints | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-099 Insecure WebSocket Connections | [N/A] | No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope. |
| KV-100 Insufficient Backup / Disaster Recovery | [PARTIAL] | Git preserves source, but no disaster-recovery or business-continuity plan is documented. |

### Known Vector Metrics

| Metric | Count |
|---|---:|
| Total | 100 |
| PASS | 14 |
| FAIL | 2 |
| PARTIAL | 7 |
| N/A | 77 |

## Instruction Matrix

| Entry point | Authority | External calls | Principal state |
|---|---|---|---|
| initialize | one-time initializer, atomic deploy calldata | none | admins, minters, USDT, Safe |
| registerProduct | admin | CREATE2 InvestmentNFT deployment | product and active indexes |
| invest | investor | USDT transferFrom, NFT safeMint, tier SBT probes | raisedAmount, productPool |
| mintNFT | minter | NFT safeMint | raisedAmount |
| deposit / withdraw | admin | USDT transferFrom / transfer | productPool |
| distributeYield | admin/whitelisted Automation | NFT reads, USDT low-level transfer | cursor, pool, yield escrow |
| maturity | admin/whitelisted Automation | NFT reads/burn, USDT low-level transfer | cursor, pool, principal/yield escrow, active index |
| claimYield / claimPrincipal | current NFT owner | ownerOf, USDT transfer, NFT burn | escrow clearing |
| role/tier setters | Safe or admin | ERC165 probes for tier IDs | role arrays, tier registry |
| Automation.performUpkeep | configured forwarder | Investment proxy call | downstream lifecycle state |

## State Model Verification

- **Pool/escrow accounting:** Reviewed as a liability transfer: failed push payments debit productPool and create escrow while tokens remain in the shared contract balance. No double-credit path was confirmed.
- **NFT ownership:** Yield/principal rights intentionally follow current `ownerOf(tokenId)`; prior-owner escrow transfer is documented bearer behavior, not reported as theft.
- **Burn safety:** Maturity and claimPrincipal sweep all indexed yield escrow before burn on successful transfer; the prior locked-yield issue is fixed and regression-tested.
- **Batch cursors:** Distribution/maturity batches cap NFT reads at 50. Burns occur only after all distributions and below the next maturity cursor; no reachable burned-gap cursor revert was confirmed.
- **CREATE2:** Salt is `keccak256(SALT_PREFIX, productId)` and product IDs are unique. Constructor metadata changes init-code hash/address by design; no collision was confirmed.
- **Schedule:** Month-end/leap-year tests pass, but F-002 shows inconsistent handling of non-midnight timestamps.

## Remediation Roadmap

See `audit_1/roadmap.md`. Fix order: F-001 role revocation, F-002 canonical schedule validation, F-003 dependency fail-soft behavior, then CI and verification controls.

## Appendices

### Tool Results

- `forge test`: 45 suites, 283 passed, 0 failed, 0 skipped.
- Audit PoCs: 3 passed.
- `npm audit --audit-level=high`: 0 vulnerabilities.
- `forge fmt --check`: failed due repository-wide formatting/line-ending differences; no files were autoformatted.
- `forge coverage --report summary`: compiler stack-too-deep at RegisterProduct.
- `forge coverage --ir-minimum --report summary`: Yul stack exception in embedded RegisterProduct tests.
- Foundry emitted a non-test-impacting warning that its user-level signature cache was not writable in this sandbox.

### Limitations

- Deployment status, TVL, live proxy/Dictionary addresses, Safe threshold, Chainlink upkeep gas configuration, branch protection, production monitoring, and key custody were not provided and are marked PARTIAL rather than assumed secure.
- Third-party dependencies were reviewed at integration boundaries and by pins/audit output, not re-audited line-by-line.
- A passing PoC proves the undesired behavior is reachable; it does not by itself prove a permissionless attacker can satisfy every operational precondition.

### Disclaimer

This is a source-level security review, not a guarantee of absence of vulnerabilities. Findings distinguish confirmed code behavior from unverified deployment and organizational controls.
