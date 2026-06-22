# Audit Checkpoint

- Phase: report generation
- Corpus: 131 AUDITOR markdown files, 11,189 lines, zero read failures
- Production Solidity: reviewed file-by-file before embedded `// Testing` sections
- Tests: 283 passed, 0 failed, 0 skipped
- PoCs: duplicate initial minter, normalized schedule bypass, reverting tier SBT all pass
- Dependency audit: `npm audit` found 0 vulnerabilities
- Coverage: unavailable; normal mode stack-too-deep, IR-minimum Yul stack exception
- Confirmed code findings: 3
- Operational findings: CI trigger/action pinning and verification gaps

