# RWA Investment Contracts

Solidity smart contracts for the RWA investment protocol (Foundry + [MC devkit](https://github.com/metacontract/mc)).

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge` / `cast`) — CI uses the **stable** channel (see `.github/workflows/test.yml`)
- Git with submodule support
- Node.js (optional) — only for `simple-git-hooks` / `lint-staged` (`npm install` runs `forge fmt` on staged `.sol` files)

## Setup

```bash
git clone --recurse-submodules <repo-url>
cd rwa-investment-contracts

# If you already cloned without submodules:
git submodule update --init --recursive

cp .env.example .env   # then fill in deploy/RPC values (never commit .env)
```

Verify the toolchain:

```bash
forge build
forge test
```

## Build toolchain

| Item | Pinned value |
|------|----------------|
| Solidity (project) | `0.8.28` — fixed in every `src/` / `test/` / `script/` file and `foundry.toml` (`solc = "0.8.28"`) |
| Foundry (CI) | `stable` (see `.github/workflows/test.yml`) |
| Optimizer | enabled, `optimizer_runs = 1_000_000`, `via_ir = true` |

Floating pragmas (`^0.8.28`) are not used in project-owned Solidity files.

## Git submodules (pinned)

Do **not** run `git submodule update --remote` without an explicit review. Submodule versions are recorded in three places:

1. **Git gitlink** — commit SHA stored in the parent repository tree
2. **`foundry.lock`** — machine-readable rev for `lib/mc` and `lib/chainlink-evm`
3. **This table** — human-readable reference

| Path | Tag / reference | Commit (short) |
|------|-----------------|----------------|
| `lib/mc` | `v0.1.0-alpha-361-gc75f753` | `c75f753` |
| `lib/chainlink-evm` | `contracts-v1.4.0` | `e06cc226` |

Chainlink contracts are sourced from [`smartcontractkit/chainlink-evm`](https://github.com/smartcontractkit/chainlink-evm) (not the deprecated `chainlink-brownie-contracts`). The project imports `AutomationCompatibleInterface` and vendor `DateTime` only; Chainlink Registry / Forwarder contracts are **not** vendored — the upkeep forwarder address is supplied at deploy time (see Deploy).

Nested dependencies inside `lib/mc` (forge-std, OpenZeppelin, etc.) are pinned indirectly via the `lib/mc` gitlink.

## Project layout

| Path | Purpose |
|------|---------|
| `src/investment/` | Core Investment proxy facets (MC bundle) |
| `src/periphery/` | `Automation.sol`, `InvestmentNFT.sol`, `interfaces/` |
| `script/deploy/` | `DeployInvestment.s.sol`, `DeployAutomation.s.sol`, `InvestmentDeployer.sol` |
| `test/` | Unit and scenario tests |
| `remappings.txt` | Import path aliases (including `@chainlink/` → `lib/chainlink-evm/contracts/`) |
| `foundry.toml` | Foundry profile (`solc`, optimizer, `fs_permissions` for `.env` / `mc.toml`) |
| `foundry.lock` | Pinned submodule revisions |
| `docs/audit/fix/` | Audit remediation notes (e.g. F-2026-16938) |

## Commands

```bash
forge build              # compile (lint notes are informational; exit 0 = success)
forge test               # run all tests
forge test -vvv          # verbose tests
forge fmt                # format Solidity sources
forge fmt --check        # check formatting without writing (not run in CI)
```

To skip linter output during build:

```bash
forge build --skip lint
```

## Environment variables

Copy `.env.example` to `.env`. Keys used by deploy scripts:

| Variable | Scope | Used by |
|----------|-------|---------|
| `DEPLOYER_PRIV_KEY` | global | deploy scripts (broadcast signer) |
| `RPC_URL` | global | `--rpc-url` when running `forge script` |
| `ADMINS_ADDR`, `MINTERS_ADDR` | global (comma-separated) | `DeployInvestment.s.sol` |
| `USDT_ADDR_{chainId}` | per chain | `DeployInvestment.s.sol` |
| `SAFE_MULTISIG_WALLET_ADDR_{chainId}` | per chain | `DeployInvestment.s.sol` |
| `FORWARDER_ADDR_{chainId}` | per chain | `DeployAutomation.s.sol` (Chainlink upkeep forwarder) |
| `INVESTMENT_PROXY_ADDR_{chainId}` | per chain | written by deploy; read by `DeployAutomation.s.sol` |
| `AUTOMATION_ADDR_{chainId}` | per chain | written by `DeployAutomation.s.sol` |

The `{chainId}` suffix must match `chainid()` of the RPC endpoint used when running `forge script` (e.g. `80002` for Polygon Amoy, `31337` for Anvil).

Example `.env` fragment:

```bash
USDT_ADDR_80002=0x...
SAFE_MULTISIG_WALLET_ADDR_80002=0x...
FORWARDER_ADDR_80002=0x...
```

## Deploy

Run against the target network RPC. Scripts read chain-scoped keys via `chainid()` at execution time.

```bash
# 1. Investment proxy (writes INVESTMENT_PROXY_ADDR_{chainId} to .env)
forge script script/deploy/DeployInvestment.s.sol \
  --rpc-url $RPC_URL --broadcast -vvv

# 2. Automation helper (requires INVESTMENT_PROXY_ADDR_{chainId} and FORWARDER_ADDR_{chainId})
forge script script/deploy/DeployAutomation.s.sol \
  --rpc-url $RPC_URL --broadcast -vvv
```

Before broadcasting, confirm that the RPC’s `chainid` matches the suffix on your `USDT_ADDR_*`, `SAFE_MULTISIG_WALLET_ADDR_*`, and `FORWARDER_ADDR_*` entries.

## CI

GitHub Actions workflow `.github/workflows/test.yml` (manual `workflow_dispatch`):

- checks out submodules recursively
- installs Foundry **stable**
- runs `forge build --sizes` and `forge test -vvv`

CI does not run `forge fmt --check`; formatting is enforced locally via `simple-git-hooks` + `lint-staged` when `npm install` has been run.

## Updating dependencies

1. Do **not** use `git submodule update --remote` without review.
2. To bump a submodule intentionally:
   - check out the desired tag/commit inside `lib/mc` or `lib/chainlink-evm`
   - commit the updated gitlink in the parent repo
   - update `foundry.lock` and this README table
   - run `forge build` and `forge test`
3. After changing Chainlink versions, confirm `@chainlink/` remapping in `remappings.txt` still resolves and re-run the full test suite.

Audit remediation details for toolchain pinning: `docs/audit/fix/F-2026-16938-floating-pragma-unpinned-dependencies.md`.
