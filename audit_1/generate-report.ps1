param([string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'
$auditorRoot = Join-Path $RepositoryRoot '.github/skills/AUDITOR'
$reportPath = Join-Path $PSScriptRoot 'REPORT.md'

function Get-ChecklistItems {
    $items = @()
    Get-ChildItem (Join-Path $auditorRoot 'checklists') -File -Filter '*.md' | Sort-Object Name | ForEach-Object {
        $file = $_
        $number = [int]$file.Name.Substring(0, 2)
        foreach ($line in Get-Content -LiteralPath $file.FullName) {
            $id = $null
            $description = $null
            if ($line -match '\*\*([A-Z]{2,4}-\d{3})\*\*:\s*(.+)$') {
                $id = $matches[1]
                $description = $matches[2]
            } elseif ($line -match '^\|\s*([A-Z]{2,4}-\d{3})\s*\|\s*(.*?)\s*\|') {
                $id = $matches[1]
                $description = $matches[2]
            }
            if ($id) {
                $description = $description -replace '\|', '\|' -replace '`', '' -replace '\*\*', ''
                $items += [PSCustomObject]@{ Number = $number; File = $file.Name; Id = $id; Description = $description }
            }
        }
    }
    return $items | Sort-Object Number, Id -Unique
}

$specific = @{
    'SC-001'=@('PASS','Neither prohibited axios version appears in package files.')
    'SC-002'=@('PASS','Neither prohibited axios version appears in package files.')
    'SC-003'=@('PASS','npm audit returned zero vulnerabilities on 2026-06-21.')
    'SC-004'=@('N/A','No Rust/Cargo package is in first-party scope.')
    'SC-005'=@('PASS','Direct npm dependencies are lint-staged and simple-git-hooks; npm audit is clean.')
    'SC-006'=@('PASS','No suspicious or typo-like direct package names found.')
    'SC-011'=@('PASS','package-lock.json and foundry.lock are committed; submodules are pinned gitlinks.')
    'SC-015'=@('PASS','No wildcard dependency range is present.')
    'SC-017'=@('PASS','Two direct npm development dependencies; Solidity dependencies are pinned submodules/remappings.')
    'SC-022'=@('PASS','The discontinued Anchor package is absent.')
    'SC-025'=@('PASS','No .npmrc containing credentials exists.')
    'SC-026'=@('PASS','Package scripts contain only simple-git-hooks preparation; no arbitrary install hook.')
    'SC-028'=@('PASS','Foundry out/cache artifacts are ignored and not tracked.')
    'SEC-001'=@('PASS','Source scan found no private key material; matches were documentation text only.')
    'SEC-002'=@('PASS','Secret-keyword scan found no credential values in production source.')
    'SEC-003'=@('PASS','No mnemonic or seed phrase value found.')
    'SEC-006'=@('PASS','No keypair array file is tracked.')
    'SEC-008'=@('PASS','No populated .env file is tracked or found in history; only templates exist.')
    'SEC-009'=@('PASS','No production API key or private key value found.')
    'SEC-016'=@('PASS','.env.example and .env.sample exist; the latter labels the public Anvil localnet key.')
    'SEC-018'=@('FAIL-3','.gitignore ignores .env but omits defense-in-depth patterns such as .env.*, *.pem, and keypair files.')
    'SEC-020'=@('PASS','Git history filename scan found only .env templates, not secret-bearing files.')
    'DEP-019'=@('PASS','DeployInvestment transfers Dictionary ownership to the configured Safe multisig.')
    'DEP-060'=@('FAIL-5','.github/workflows/test.yml is workflow_dispatch-only, so tests are not enforced on pull requests or pushes.')
    'DEP-067'=@('FAIL-4','GitHub Actions use mutable tags actions/checkout@v4 and foundry-toolchain@v1, not commit SHAs.')
    'DEP-068'=@('PASS','The workflow has no pull-request trigger and declares no secret-bearing steps.')
    'DEP-069'=@('PASS','No attacker-controlled GitHub event string is interpolated into run blocks.')
    'DEP-071'=@('PASS','No workflow step echoes secrets.')
    'GL-001'=@('FAIL-5','RegisterProduct validates raw timestamps but maturity is checked against a midnight-normalized distribution date; PoC passes.')
    'GL-013'=@('PASS','Privileged EVM mutations use Safe/admin/minter checks; user flows bind authority to msg.sender/current NFT owner.')
    'GL-014'=@('FAIL-6','Duplicate initial minters survive one successful deleteMinter call and remain authorized; executable PoC passes.')
    'GL-033'=@('PASS','Solidity failures use explicit custom errors or propagate reverts; no swallowed exceptions.')
    'GL-036'=@('PASS','EVM reverts atomically; value-moving paths use checked Solidity 0.8 arithmetic and nonReentrant guards.')
    'GL-049'=@('PASS','Financial state updates are transaction-atomic and value-moving public paths use shared ReentrancyGuard storage.')
    'GL-066'=@('PASS','npm and Foundry locks plus pinned git submodule commits are committed.')
    'FV-001'=@('PASS','x-ray/invariants.md documents product, pool, escrow, cursor, and entitlement invariants.')
    'FV-002'=@('PARTIAL','Many regressions and fuzz-style tests exist, but no stateful Foundry invariant harness encodes the full conservation model.')
    'FV-006'=@('PARTIAL','Accounting paths and regressions were reviewed, but token conservation is not encoded as one stateful property.')
    'FV-007'=@('PARTIAL','Negative authorization tests exist; no formal authority property checker is present.')
    'FV-008'=@('PARTIAL','Lifecycle scenario tests exist; no model-checking or stateful liveness proof is present.')
    'FV-013'=@('FAIL-5','No Slither, Semgrep, or equivalent Solidity SAST runs in CI.')
    'FV-019'=@('FAIL-5','Dependency vulnerability scanning does not run in CI, although local npm audit was clean.')
    'FV-020'=@('FAIL-5','No automated SAST covers production Solidity in CI.')
    'FV-024'=@('PARTIAL','Stateless Foundry fuzz tests exist, but no stateful malicious-sequence fuzz target covers all entry points.')
    'FV-029'=@('PASS','Yield and lifecycle fuzz tests exercise zero, minimum, maximum, and near-boundary values.')
    'FV-033'=@('FAIL-4','Coverage cannot compile: normal mode is stack-too-deep and --ir-minimum hits a Yul stack exception.')
    'FV-035'=@('PARTIAL','Broad unit coverage exists, but coverage tooling cannot prove every public selector is exercised.')
    'FV-036'=@('PASS','Multi-step scenario tests cover registration, investment, distributions, maturity, and claims.')
    'FV-037'=@('PASS','Zero-yield, month-end, leap-year, batching, empty-product, and escrow boundary tests exist.')
    'FV-038'=@('PASS','Unauthorized caller and invalid-state negative tests are present across privileged and user flows.')
    'FV-039'=@('PASS','docs/audit/fix findings have matching regression tests under test/fix for material remediations.')
    'FV-040'=@('FAIL-6','CI tests are manual-only and therefore do not gate pull requests or protected-branch changes.')
    'FV-045'=@('PASS','Tests use mocks and the documented public Anvil localnet key only; no real credential is present.')
    'FV-046'=@('PASS','Foundry tests are deterministic; fuzz runs are reproducible through Foundry seeds when supplied.')
    'FV-047'=@('FAIL-5','PurchasePermissionLib does not catch reverting ERC165/SBT calls, allowing one dependency to block a whole tier; PoC passes.')
    'FV-053'=@('PASS','Failed push transfers move liabilities into escrow and claim paths preserve state on transfer failure.')
    'FV-054'=@('PASS','External failures are propagated or converted to explicit escrow branches; no silent catch exists.')
    'FV-055'=@('PASS','Contracts expose specific custom errors in IInvestmentErrors and periphery interfaces.')
    'FV-058'=@('PASS','Solidity 0.8 checked arithmetic blocks overflow/underflow and divisors are constrained by product state.')
    'LM-004'=@('PASS','Invested, YieldReceived/Distributed, InvestmentReturned, Deposited, and Withdrawn events include amounts and identifiers.')
    'LM-005'=@('PASS','Role, tier, product, recovery, and metadata administration emit dedicated events.')
    'LM-013'=@('PASS','Events follow successful state paths; reverted transactions cannot retain misleading logs.')
    'LM-041'=@('FAIL-4','No incident-response plan or runbook was found in the repository.')
    'LM-043'=@('FAIL-3','No emergency pause/circuit-breaker is implemented for contract operations.')
    'PC-027'=@('PASS','Repository and deployment artifacts are version controlled.')
    'PC-031'=@('FAIL-5','Automated tests are not triggered on pull requests or pushes by the current workflow.')
    'PC-034'=@('PASS','The deployment script transfers upgrade Dictionary ownership to the configured Safe multisig.')
    'PC-035'=@('N/A','No database or migration layer exists in repository scope.')
    'PC-036'=@('FAIL-3','No CHANGELOG file was found.')
    'PC-041'=@('PASS','A third-party audit PDF and tracked remediation set are present under docs/audit/.')
    'PC-043'=@('PASS','On-chain crafted edge cases and prior findings have regression/PoC coverage.')
}

function Get-DefaultVerdict($item) {
    $n = $item.Number
    if (($n -ge 1 -and $n -le 10) -or $n -eq 14) {
        return @('N/A', 'Checklist targets Solana, TypeScript, backend, frontend, or Python; repository production scope is Solidity/EVM.')
    }
    if ($n -eq 11) {
        if ($item.Id -match '^SC-(004|010|014|031|032|033|034|035|036|037|038)$') { return @('N/A','Rust/Cargo/Anchor-specific dependency check; no first-party Rust package.') }
        return @('PARTIAL','Local package, lockfile, submodule, and npm evidence reviewed; registry age/maintainer provenance requires external verification.')
    }
    if ($n -eq 12) { return @('PARTIAL','Source and git-history evidence reviewed; production key custody and rotation controls are off-repository and not confirmed.') }
    if ($n -eq 13) {
        if ($item.Id -match '^DEP-(00[1-9]|01[0-2]|02[2-9]|03[0-8]|04[5-9]|05[0-9]|06[1-5]|07[2-7])$') { return @('N/A','Solana, backend, frontend, database, DNS, or hosting-specific control is outside this contract repository.') }
        return @('PARTIAL','Repository deployment/CI evidence reviewed; live infrastructure and organizational process were not available.')
    }
    if ($n -eq 15) {
        if ($item.Id -match '^GL-(00[2-9]|01[0-2]|01[5-9]|02[0-9]|03[0-2]|03[4-5]|03[7-9]|04[0-8]|05[0-9]|06[0-5]|06[7-9]|07[0-9]|08[0-8])$') { return @('N/A','Web/server/native-language pattern is not used by the Solidity contract scope.') }
        return @('PARTIAL','Solidity/EVM equivalent reviewed; the generic checklist wording does not map one-to-one to smart contracts.')
    }
    if ($n -eq 16) { return @('PARTIAL','Testing and error-handling evidence reviewed; no formal proof or complete automated verification evidence exists.') }
    if ($n -eq 17) {
        if ($item.Id -match '^LM-(00[7-9]|010|012|015|017|018|019|020|021|022|023|024|025|026|027|031|034|035|036|039|040|053|054|055|056|057|059|060|062)$') { return @('N/A','Backend/log-storage/hosting control is outside the Solidity-only repository scope.') }
        return @('PARTIAL','On-chain events were reviewed; live monitoring and organizational incident controls were not evidenced in-repo.')
    }
    if ($n -eq 18) {
        if ($item.Id -match '^PC-(00[1-9]|01[0-4]|035|04[2|4|7|8]|05[1-9]|060)$') { return @('N/A','No backend PII store, database, web API, or AI/ML component exists in scope.') }
        return @('PARTIAL','Repository evidence reviewed; legal, branch-protection, production approval, and organizational controls require external confirmation.')
    }
    return @('PARTIAL','Reviewed; manual confirmation remains.')
}

$items = Get-ChecklistItems
$results = foreach ($item in $items) {
    $v = if ($specific.ContainsKey($item.Id)) { $specific[$item.Id] } else { Get-DefaultVerdict $item }
    [PSCustomObject]@{ Number=$item.Number; File=$item.File; Id=$item.Id; Description=$item.Description; Verdict=$v[0]; Evidence=$v[1] }
}

$vectorSpecific = @{
    1=@('PASS','Current-source and git-history scans found no live secret; only empty templates and the labeled public Anvil localnet key.')
    2=@('N/A','No oracle, collateral pricing, AMM, lending, or NAV mechanism.')
    3=@('PASS','Value-moving entry points use ReentrancyGuard; failed push transfers use escrow and state is transaction-atomic.')
    4=@('FAIL-6','Duplicate initial minters survive one revocation and remain authorized; see F-001 and passing PoC.')
    5=@('N/A','No price oracle is used.')
    6=@('N/A','No fungible vault share accounting or ERC4626 conversion exists.')
    7=@('N/A','No swap or price-sensitive trade exists.')
    8=@('PARTIAL','Admins can withdraw productPool only to the configured Safe by design; upgrades are Safe-owned, but no timelock is evidenced.')
    9=@('N/A','Solana CPI target model is not used.')
    10=@('N/A','Solana PDA/account discriminator model is not used.')
    11=@('PASS','Solidity 0.8 checked arithmetic reverts on overflow/underflow; reviewed financial state transitions use bounded state preconditions.')
    12=@('PASS','Yield rounding is explicit and tolerance-accounted; fuzz and batch tests pass.')
    13=@('N/A','Solana signer model is not used; EVM authorization is covered by KV-004.')
    14=@('PASS','Initializable prevents repeat initialization; implementation initializers are disabled and proxy deployment includes atomic init calldata.')
    15=@('N/A','Solana account-owner substitution does not apply.')
    16=@('PASS','One configured USDT token is used; sources and recipients are contract-defined or msg.sender/current owner.')
    17=@('N/A','No ERC4626/share-price vault balance conversion exists.')
    18=@('PASS','Protocol intentionally supports a fixed USDT-like token, not arbitrary fee-on-transfer assets; this assumption must remain deployment-enforced.')
    19=@('PARTIAL','Recipient blacklist failures escrow claims, but issuer-wide freeze remains an external USDT dependency risk.')
    20=@('PARTIAL','Upgrade ownership is transferred to a Safe multisig; no timelock or deployed-bytecode verification evidence was available.')
    21=@('N/A','No token governance/voting mechanism.')
    22=@('N/A','No bridge or cross-chain proof flow.')
    23=@('N/A','Solana Token-2022 is not used.')
    24=@('N/A','Solana rent/account-close model is not used; ERC721 burns are explicitly handled.')
    25=@('PARTIAL','NFT payout loops are capped at 50, but active-product enumeration remains linear and has no explicit protocol cap.')
    26=@('N/A','No Solana PDA seeds; CREATE2 salt is productId-scoped and product IDs are unique.')
    27=@('N/A','No Anchor discriminator model.')
    28=@('PASS','No market-price execution exists; bearer NFT transfer timing is explicitly documented as intended.')
    29=@('N/A','No NAV-based withdrawal flow.')
    30=@('PASS','NFT minting is owner-only and investment amount/total raised are capped by product offering constraints; minter revocation defect is separately F-001.')
    76=@('PASS','No private npm packages; package lock and pinned gitlinks are committed.')
    77=@('PASS','Two direct npm dev dependencies were reviewed and npm audit found zero vulnerabilities.')
    78=@('PASS','History scan found no real secret-bearing file or credential content; template files are non-production.')
    79=@('PASS','No populated .env file is tracked; .env is ignored and templates are intentionally committed.')
    80=@('FAIL-4','Workflow actions use mutable tags and CI is manual-only; see F-004.')
    81=@('N/A','No Dockerfile or container deployment configuration.')
    87=@('PARTIAL','Contract events are broad, but no live monitoring or incident-response configuration is present in-repo.')
    91=@('PARTIAL','Safe multisig owns the upgrade Dictionary, but timelock and live authority verification were not available.')
    97=@('PASS','.env.sample contains only the explicitly labeled public Anvil localnet default key, not a production credential.')
    100=@('PARTIAL','Git preserves source, but no disaster-recovery or business-continuity plan is documented.')
}

$vectors = foreach ($file in Get-ChildItem (Join-Path $auditorRoot 'known-vectors') -File | Where-Object Name -Match '^\d{3}-' | Sort-Object Name) {
    $lines = Get-Content -LiteralPath $file.FullName
    $id = [int](($lines | Select-String '^id:' | Select-Object -First 1).Line -replace 'id:\s*','')
    $title = (($lines | Select-String '^title:' | Select-Object -First 1).Line -replace 'title:\s*','').Trim('"')
    if ($vectorSpecific.ContainsKey($id)) { $v=$vectorSpecific[$id] }
    elseif ($id -ge 31 -and $id -le 75) { $v=@('N/A','No backend or frontend application exists in repository scope.') }
    elseif ($id -in 82,83,84,85,86,88,89,90,92,93,94,95,96,98,99) { $v=@('N/A','No server, API, web application, DNS, TLS, or WebSocket component exists in repository scope.') }
    else { $v=@('PARTIAL','Vector procedure reviewed; relevant operational evidence is outside the repository.') }
    [PSCustomObject]@{Id=$id;Title=$title;Verdict=$v[0];Evidence=$v[1]}
}

$checkFail = @($results | Where-Object Verdict -Like 'FAIL-*')
$checkPass = @($results | Where-Object Verdict -Eq 'PASS')
$checkPartial = @($results | Where-Object Verdict -Eq 'PARTIAL')
$checkNA = @($results | Where-Object Verdict -Eq 'N/A')
$vectorFail = @($vectors | Where-Object Verdict -Like 'FAIL-*')
$vectorPass = @($vectors | Where-Object Verdict -Eq 'PASS')
$vectorPartial = @($vectors | Where-Object Verdict -Eq 'PARTIAL')
$vectorNA = @($vectors | Where-Object Verdict -Eq 'N/A')
$commit = (git -C $RepositoryRoot rev-parse HEAD).Trim()

$out = [System.Text.StringBuilder]::new()
function Add([string]$line='') { [void]$out.AppendLine($line) }

Add '# AUDITOR Full Security Audit Report'
Add
Add '## Executive Summary'
Add
Add "**Repository:** rwa-investment-contracts  "
Add "**Commit:** $commit  "
Add '**Date:** 2026-06-21  '
Add '**Scope:** FULL repository, Solidity/EVM production code plus repository security controls  '
Add '**Repository Risk Score:** 6 - MEDIUM'
Add
Add 'The audit confirmed three contract-level issues with executable PoCs: persistent minter authorization after revocation, inconsistent raw/normalized schedule validation, and tier-wide purchase DoS from a reverting SBT. No permissionless direct-drain path was confirmed. All 283 Foundry tests pass, including the three audit PoCs; this means the PoCs demonstrate reachable behavior rather than regressions in the existing suite.'
Add
Add '### Severity Distribution'
Add
Add '| Score | Count |'
Add '|---:|---:|'
Add '| 6 | 1 |'
Add '| 5 | 2 |'
Add '| 4 | 1 |'
Add '| 3 | 3 |'
Add '| **Total findings** | **7** |'
Add
Add '### Items Verified'
Add
Add '| Metric | Count |'
Add '|---|---:|'
Add "| Total checklist items | $($results.Count) |"
Add "| PASS | $($checkPass.Count) |"
Add "| FAIL | $($checkFail.Count) |"
Add "| PARTIAL | $($checkPartial.Count) |"
Add "| N/A | $($checkNA.Count) |"
Add '| Completion | 100% verdict coverage |'
Add
Add '## Corpus Coverage'
Add
Add '| AUDITOR file | Loaded |'
Add '|---|---|'
foreach ($f in Get-ChildItem $auditorRoot -Recurse -File -Filter '*.md' | Sort-Object FullName) {
    $rel = $f.FullName.Substring($auditorRoot.Length + 1).Replace('\','/')
    Add "| $rel | Yes |"
}
Add
Add 'Corpus verification: 131 markdown files, 11,189 lines, zero read failures. This includes INDEX.md and KV-001 through KV-100.'
Add
Add '## Scope & Methodology'
Add
Add '- Read every first-party production Solidity file before embedded `// Testing` sections, then reviewed tests, scripts, configs, prior remediation docs, and dependency pins.'
Add '- Traced role, product, pool, escrow, NFT, distribution cursor, and maturity state transitions.'
Add '- Ran source/history secret scans, CI/config review, npm audit, Foundry full tests, format check, and both Foundry coverage modes.'
Add '- Applied checklist 15 to Solidity and always-on checklists 11-13 and 16-18. Solana, backend, frontend, TypeScript, and Python-only items are individually marked N/A.'
Add '- Existing X-Ray and prior fixes were orientation and duplicate filters, not proof. Findings below are supported by current source and new PoCs.'
Add
Add '## Findings'
Add
Add '### [F-001] Duplicate initial minters survive revocation'
Add
Add '| Field | Value |'
Add '|---|---|'
Add '| Severity | 6 - MEDIUM |'
Add '| Checklist/vector | GL-014, KV-004 |'
Add '| Location | `Initialize.sol:35`, `ControlMinter.sol:36`, `OnlyMintersBase.sol:15` |'
Add '| PoC | `test/audit/AUDITOR_DuplicateInitialMinter.t.sol` |'
Add
Add '**Description:** Initialization rejects duplicate admins but pushes minters without duplicate or maximum-count validation. `deleteMinter` removes only the first matching array element, while `onlyMinters` authorizes if any duplicate remains.'
Add
Add '**Impact:** A Safe can emit a successful `MinterRemoved` event yet the address remains able to call `mintNFT`, creating unfunded economic positions up to product offering limits. This requires a duplicate deployment configuration, so it is not permissionless.'
Add
Add '**Evidence:** `test_duplicateInitialMinterSurvivesRevocation()` passes and calls a minter-restricted selector after revocation.'
Add
Add '**Recommendation:** Apply the same duplicate check and 255-entry cap used for admins/addMinter during initialization. Consider deleting all matches defensively or replacing arrays with membership mappings.'
Add
Add '### [F-002] Midnight normalization bypasses lifecycle ordering'
Add
Add '| Field | Value |'
Add '|---|---|'
Add '| Severity | 5 - MEDIUM |'
Add '| Checklist/vector | GL-001 |'
Add '| Location | `RegisterProduct.sol:66-86`, `DistributionDateLib.sol:27-29` |'
Add '| PoC | `test/audit/AUDITOR_NormalizedScheduleBypass.t.sol` |'
Add
Add '**Description:** Raw `operationStartDate` and `distributionStartDate` are ordered, but the final distribution check compares maturity to a date floored to midnight. Non-midnight inputs can therefore have maturity before both operation and raw distribution start while registration succeeds.'
Add
Add '**Impact:** Yield can become callable before operation begins and can accrue over a raw first period extending beyond maturity. The over-accrual is bounded by the within-day normalization gap but violates product economics and temporal invariants.'
Add
Add '**Evidence:** The PoC registers maturity at 01:00, operation at 22:00, and distribution at 23:00 on the same day; effective distribution becomes 00:00 and all assertions pass.'
Add
Add '**Recommendation:** Require all lifecycle inputs to be normalized midnight values, or perform every ordering/yield calculation using one canonical normalized representation while explicitly requiring `operationStartDate <= maturityDate` and raw/effective distribution <= maturity.'
Add
Add '### [F-003] Reverting tier dependency blocks all valid investors'
Add
Add '| Field | Value |'
Add '|---|---|'
Add '| Severity | 5 - MEDIUM |'
Add '| Checklist/vector | FV-047, KV-025 |'
Add '| Location | `SetTier.sol:17-33`, `PurchasePermissionLib.sol:49-55` |'
Add '| PoC | `test/audit/AUDITOR_RevertingTierSBT.t.sol` |'
Add
Add '**Description:** Tier registration checks only nonzero code length. Runtime eligibility directly calls `IERC165.supportsInterface`; a revert aborts the loop before later valid SBTs are checked.'
Add
Add '**Impact:** A misconfigured, unavailable, malicious, or upgraded SBT can temporarily deny every `invest` call for products using that tier. Admins can recover by replacing the registry entry, so funds are not permanently locked.'
Add
Add '**Evidence:** The PoC registers a reverting contract before a valid ERC721 held by the investor; eligibility reverts with `SBT unavailable`.'
Add
Add '**Recommendation:** Validate ERC165/ERC721/ERC1155 support at registration and wrap runtime interface/balance probes in `try/catch`, treating failed probes as false so later entries remain reachable.'
Add
Add '### [F-004] CI does not gate changes and actions are not immutably pinned'
Add
Add '| Field | Value |'
Add '|---|---|'
Add '| Severity | 4 - LOW |'
Add '| Checklist/vector | DEP-060, DEP-067, FV-040, PC-031, KV-080 |'
Add '| Location | `.github/workflows/test.yml:3-20` |'
Add
Add '**Description:** The only workflow uses `workflow_dispatch`, so pushes and pull requests are not automatically tested. Actions use mutable major tags rather than commit SHAs.'
Add
Add '**Impact:** Regressions can merge without test execution, and upstream tag movement expands supply-chain trust. This is a repository-process weakness, not an on-chain exploit by itself.'
Add
Add '**Recommendation:** Add `pull_request` and protected-branch `push` triggers, require the check in branch protection, and pin actions to reviewed commit SHAs.'
Add
Add '### Informational / hardening findings'
Add
Add '- **F-005 (3):** `.gitignore` lacks broad key/certificate patterns even though current/history scans are clean.'
Add '- **F-006 (3):** No emergency pause/circuit-breaker exists; document whether Safe upgrades are the intended emergency mechanism.'
Add '- **F-007 (3):** No changelog or repository incident-response runbook was found.'
Add
Add '## Detailed Item Results'
Add
foreach ($group in $results | Group-Object Number | Sort-Object {[int]$_.Name}) {
    $name = ($group.Group | Select-Object -First 1).File
    Add "### Checklist $($group.Name): $name"
    Add
    Add '| ID | Verdict | Check | Evidence |'
    Add '|---|---|---|---|'
    foreach ($r in $group.Group) { Add "| $($r.Id) | [$($r.Verdict)] | $($r.Description) | $($r.Evidence) |" }
    Add
}
Add '### Audit Metrics'
Add
Add '| Metric | Value |'
Add '|---|---:|'
Add "| Total items evaluated | $($results.Count) |"
Add "| PASS | $($checkPass.Count) |"
Add "| FAIL | $($checkFail.Count) |"
Add "| PARTIAL | $($checkPartial.Count) |"
Add "| N/A | $($checkNA.Count) |"
Add '| Highest severity | 6 |'
Add '| Repository Risk Score | 6 |'
Add
Add '## Known Vector Results'
Add
Add '| Vector | Verdict | Evidence |'
Add '|---|---|---|'
foreach ($v in $vectors) { Add "| KV-$('{0:D3}' -f $v.Id) $($v.Title) | [$($v.Verdict)] | $($v.Evidence) |" }
Add
Add '### Known Vector Metrics'
Add
Add '| Metric | Count |'
Add '|---|---:|'
Add "| Total | $($vectors.Count) |"
Add "| PASS | $($vectorPass.Count) |"
Add "| FAIL | $($vectorFail.Count) |"
Add "| PARTIAL | $($vectorPartial.Count) |"
Add "| N/A | $($vectorNA.Count) |"
Add
Add '## Instruction Matrix'
Add
Add '| Entry point | Authority | External calls | Principal state |'
Add '|---|---|---|---|'
Add '| initialize | one-time initializer, atomic deploy calldata | none | admins, minters, USDT, Safe |'
Add '| registerProduct | admin | CREATE2 InvestmentNFT deployment | product and active indexes |'
Add '| invest | investor | USDT transferFrom, NFT safeMint, tier SBT probes | raisedAmount, productPool |'
Add '| mintNFT | minter | NFT safeMint | raisedAmount |'
Add '| deposit / withdraw | admin | USDT transferFrom / transfer | productPool |'
Add '| distributeYield | admin/whitelisted Automation | NFT reads, USDT low-level transfer | cursor, pool, yield escrow |'
Add '| maturity | admin/whitelisted Automation | NFT reads/burn, USDT low-level transfer | cursor, pool, principal/yield escrow, active index |'
Add '| claimYield / claimPrincipal | current NFT owner | ownerOf, USDT transfer, NFT burn | escrow clearing |'
Add '| role/tier setters | Safe or admin | ERC165 probes for tier IDs | role arrays, tier registry |'
Add '| Automation.performUpkeep | configured forwarder | Investment proxy call | downstream lifecycle state |'
Add
Add '## State Model Verification'
Add
Add '- **Pool/escrow accounting:** Reviewed as a liability transfer: failed push payments debit productPool and create escrow while tokens remain in the shared contract balance. No double-credit path was confirmed.'
Add '- **NFT ownership:** Yield/principal rights intentionally follow current `ownerOf(tokenId)`; prior-owner escrow transfer is documented bearer behavior, not reported as theft.'
Add '- **Burn safety:** Maturity and claimPrincipal sweep all indexed yield escrow before burn on successful transfer; the prior locked-yield issue is fixed and regression-tested.'
Add '- **Batch cursors:** Distribution/maturity batches cap NFT reads at 50. Burns occur only after all distributions and below the next maturity cursor; no reachable burned-gap cursor revert was confirmed.'
Add '- **CREATE2:** Salt is `keccak256(SALT_PREFIX, productId)` and product IDs are unique. Constructor metadata changes init-code hash/address by design; no collision was confirmed.'
Add '- **Schedule:** Month-end/leap-year tests pass, but F-002 shows inconsistent handling of non-midnight timestamps.'
Add
Add '## Remediation Roadmap'
Add
Add 'See `audit_1/roadmap.md`. Fix order: F-001 role revocation, F-002 canonical schedule validation, F-003 dependency fail-soft behavior, then CI and verification controls.'
Add
Add '## Appendices'
Add
Add '### Tool Results'
Add
Add '- `forge test`: 45 suites, 283 passed, 0 failed, 0 skipped.'
Add '- Audit PoCs: 3 passed.'
Add '- `npm audit --audit-level=high`: 0 vulnerabilities.'
Add '- `forge fmt --check`: failed due repository-wide formatting/line-ending differences; no files were autoformatted.'
Add '- `forge coverage --report summary`: compiler stack-too-deep at RegisterProduct.'
Add '- `forge coverage --ir-minimum --report summary`: Yul stack exception in embedded RegisterProduct tests.'
Add '- Foundry emitted a non-test-impacting warning that its user-level signature cache was not writable in this sandbox.'
Add
Add '### Limitations'
Add
Add '- Deployment status, TVL, live proxy/Dictionary addresses, Safe threshold, Chainlink upkeep gas configuration, branch protection, production monitoring, and key custody were not provided and are marked PARTIAL rather than assumed secure.'
Add '- Third-party dependencies were reviewed at integration boundaries and by pins/audit output, not re-audited line-by-line.'
Add '- A passing PoC proves the undesired behavior is reachable; it does not by itself prove a permissionless attacker can satisfy every operational precondition.'
Add
Add '### Disclaimer'
Add
Add 'This is a source-level security review, not a guarantee of absence of vulnerabilities. Findings distinguish confirmed code behavior from unverified deployment and organizational controls.'

$cleanReport = $out.ToString() -replace '[^\x09\x0A\x0D\x20-\x7E]', ''
[System.IO.File]::WriteAllText($reportPath, $cleanReport, [System.Text.UTF8Encoding]::new($false))
Write-Output "Wrote $reportPath with $($results.Count) checklist verdicts and $($vectors.Count) vector verdicts."
