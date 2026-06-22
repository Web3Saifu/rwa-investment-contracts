# Remediation Roadmap

1. Reject duplicate and oversized minter arrays in `Initialize.initialize`; add the PoC as a permanent regression test.
2. Validate all lifecycle timestamps in one canonical representation. Either require midnight timestamps or compare raw timestamps and calculate yield from normalized values consistently.
3. Validate ERC165 support when registering SBTs and wrap runtime `supportsInterface`/`balanceOf` probes in `try/catch` so one dependency cannot block later valid entries.
4. Run CI on pull requests and protected-branch pushes; pin GitHub Actions to immutable commit SHAs.
5. Add stateful invariant tests for pool plus escrow conservation and lifecycle liveness; restructure embedded tests enough for coverage tooling to compile.
6. Document emergency response, monitoring, and upgrade/timelock policy before production deployment.

