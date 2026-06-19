🧩 6. সহজভাবে মনে রাখো

👉 ইউজার টাকা দেয়
👉 NFT পায় (proof of investment)
👉 সিস্টেম ট্র্যাক করে
👉 অটোমেশন পেমেন্ট দেয়
👉 শেষে USDT ফেরত আসে






6. Raised Amount vs Product Pool

এটা Audit-এর জন্য খুব Important।

Normal Investment:

Alice Invest 1000

raisedAmount += 1000
productPool += 1000

দুটোই বাড়লো।

JPY Path:

Bob Bank-এ JPY পাঠালো

NFT Mint হলো

তখন:

raisedAmount += 1000

কিন্তু:

productPool unchanged

তাই:

raisedAmount = 2000

productPool = 1000

হয়ে যেতে পারে।

এই Gap পরে Admin Deposit করে পূরণ করবে।






7. Distribution Cursor কী?

ধরো:

10,000 NFT Holder

সবাইকে এক Transaction-এ Pay করা Gas-এর জন্য অসম্ভব।

তাই Batch Processing।

প্রথম Call:

NFT1 → NFT50

শেষে Store:

distributedTokenId = 50

পরের Call:

NFT51 → NFT100

এটাই Cursor।

Cursor = "কোথায় পর্যন্ত কাজ হয়েছে"








1. Maturity Cursor আবার সহজভাবে

ধরো Product A-তে:

1000 Investors
1000 NFTs

মেয়াদ শেষ হয়েছে।

এখন protocol সবাইকে Principal ফেরত দিবে।

কিন্তু এক transaction-এ 1000 জনকে payment করলে gas শেষ হয়ে যেতে পারে।

তাই batch করে।










1. "Yield/Principal if Push Transfer Fail" মানে কী?

প্রথমে Push Transfer কী বুঝি।

Push Transfer:

Protocol
   ↓
নিজে User-কে টাকা পাঠায়

উদাহরণ:

distributeYield()

Protocol
↓
Alice-কে 10 USDT পাঠালো

এটাই Push।

কিন্তু যদি Transfer Fail করে?

উদাহরণ:

Alice blacklist

বা

Alice contract transfer reject করলো

তখন:

Protocol টাকা পাঠাতে পারলো না

এখন দুইটা option ছিল:

Bad Design
Revert

ফলে:

সব Investors-এর payment বন্ধ
Protocol-এর Design

তারা বলে:

Transfer Fail?
↓
Escrow-তে রেখে দাও

পরে Alice নিজে:

claim()

ডেকে টাকা তুলবে।

এটাকে বলে:

Push failed
↓
User later Pulls

মানে User নিজে এসে নিয়ে যায়।









. SBT কী?

SBT = Soul Bound Token

এটা NFT-এর মতো।

কিন্তু একটা বড় পার্থক্য আছে।

Normal NFT:

Alice
 ↓
Bob

Transfer করা যায়।

SBT:

Alice

Transfer করা যায় না।

Think:

University Degree

KYC Badge

VIP Membership

এগুলো অন্যকে বিক্রি করা যায় না।

তাই SBT ব্যবহার করা হয়।








3. Gold Tier NFT মানে কী?

ধরো Protocol একটা NFT দিয়েছে:

Gold Investor Badge

যার কাছে এটা আছে:

Gold Tier Investor

ধরা হবে।

তখন Invest করার আগে Protocol Check করবে:

hasPurchasePermission()

এটা আসলে জিজ্ঞেস করছে:

এই User-এর কাছে
Gold Badge আছে?

যদি থাকে:

Allow Invest

না থাকলে:

Revert






5. Tier-Gating Bypass Seeker

এটা Tier System Attack।

ধরো:

Gold Tier লাগবে

Invest করার সময়:

Alice
Gold SBT আছে

Invest Allowed।

তারপর:

Alice
NFT Bob-কে বিক্রি করলো

এখন:

Bob
Gold Tier Holder না

কিন্তু NFT Holder।

Question:

Bob Yield পাবে?
Bob Claim করতে পারবে?
Bob Principal পাবে?







Minter → Accounting Boundary

এটা সবচেয়ে interesting।

Report আবার repeat করছে:

MintNFT

করলে:

raisedAmount++

কিন্তু:

productPool++
না

মানে:

Investment Record তৈরি

কিন্তু Fund আসে নাই

এই Boundary Audit-এর High Priority Area।
