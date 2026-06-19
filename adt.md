

Context:
- X-ray smell: [smell name]
- Target contract/function: [name]
- Expected invariant: [what must always remain true]
- Attack surface: [who can call, what state matters, what asset is at risk]

Task:
1) Verify whether the smell can actually lead to a vulnerability.
2) List the exact preconditions needed.
3) Build 5 to 10 negative scenarios / edge cases.
4) For each scenario, say whether it is real, unlikely, or false positive.
5) Suggest the minimum test or proof needed to confirm it.
6) Keep output in audit style, concise, and codebase-specific

















 // @audit *****
Areas Still Interesting

আমি focus রাখতাম:

Escrow ownership

কারণ docs বলছে:

push failure handled

কিন্তু docs কিছু বলেনি:

NFT transfer after escrow creation
Cursor progression

রিপোর্টে repeatedly highlighted।

কিন্তু security docs-এ mention নেই।

JPY mint accounting

Repeatedly highlighted।

Security docs-এও explicit mitigation mention নেই।

Active product indexing

Test gap আছে।

Docs mention নেই।

Cross-contract maturity accounting

Repeatedly highlighted।

Formal invariant fuzzing নেই। // @audit









 // @audit **
JPY accounting
Escrow ownership transitions
Cursor advancement
NFT transfer interactions
Principal/yield accounting invariants










 // @audit Area 3: Escrow Recovery

Report বারবার বলেছে:

push payment
↓
escrow
↓
claim

Audit questions:

Can escrow be claimed twice?
Can escrow ownership change unexpectedly?
Can transfer + escrow interaction break accounting?

Particularly:

Escrow created
↓
NFT transferred
↓
Claim

এই path আমার কাছে খুব interesting।











 // @audit Area 5: Current Holder NFT Entitlement

এটা report-এর সবচেয়ে subtle warning।

Protocol intentionally uses:

ownerOf(tokenId)

for entitlement।

Question:

Who owns unpaid yield?

Question:

Who owns escrow?

Question:

Who owns maturity principal?

When NFT moves:

Alice
↓
Bob








 // @audit 	JPY mint ↔ deposit reconciliation	🔥 Highest
2	Escrow ownership + NFT transfers	🔥 Very High
3	Lifecycle accounting invariants	🔥 Very High
4	Distribution/Maturity cursor logic	🔥 High
5	Current-holder entitlement model	⚠️ Hig
