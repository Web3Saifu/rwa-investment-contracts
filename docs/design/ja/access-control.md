# Access Control

## 全体像

```text
┌──────────────────────────── Investment Contract ────────────────────────────┐
│                                                                             │
│  ┌────────────── Safe only ──────────────┐  ┌────── whiteList only ──────┐  │
│  │ addAdmin                              │  │ distributeYield            │  │
│  │ deleteAdmin                           │  │ registerProduct            │  │
│  │ addMinter                             │  │ deposit                    │  │
│  │ deleteMinter                          │  │ withdraw                   │  │
│  │ Dictionary                            │  │ maturity                   │  │
│  │ mapping(bytes4 selector => imple)     │  │ setAllowedByTierAddress    │  │
│  └───────────────────────────────────────┘  │ setAllowedByTierId         │  │
│                                             └────────────────────────────┘  │
│  ┌────────────── minter only ────────────┐                                  │
│  │ mintNFT (JPY payment)                 │                                  │
│  └───────────────────────────────────────┘                                  │
│                                                                             │
│                      ┌──────────── All accessible ────────────┐             │
│                      │ Getter                                 │             │
│                      │ invest                                 │             │
│                      └────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘

                 │
                 ├─────────────→ NFT Contract
                 │
                 ▼

┌─────────────────────────────── NFT Contract ────────────────────────────────┐
│                                                                             │
│  ┌──────── InvestmentContract only ────────┐                                │
│  │ mint(uint256 productId, address to)     │                                │
│  │ burn(uint256 tokenId)                   │                                │
│  └─────────────────────────────────────────┘                                │
│                                                                             │
│  ┌────────────── All accessible ──────────────┐                             │
│  │ getTokenIds(uint256 productId)             │                             │
│  └────────────────────────────────────────────┘                             │
│                                                                             │
│  ┌───────────── whiteList only ───────────────┐                             │
│  │ setURI(string tokenId)                     │                             │
│  └────────────────────────────────────────────┘                             │
└─────────────────────────────────────────────────────────────────────────────┘


┌──────────────────── Safe Multisig Wallet ────────────────────┐
│ EOA / EOA / EOA / EOA / Dev EOA                              │
└──────────────────────────────────────────────────────────────┘
                  │
                  ▼
┌──────────────────── whiteList address ───────────────────────┐
│ Administrators (Admin EOA )                                  │
│ ChainLink                                                    │
│  └─ Automation Contract                                      │
└──────────────────────────────────────────────────────────────┘

┌──────────────────── minter address ──────────────────────────┐
│ Minter EOA(s)                                                │
└──────────────────────────────────────────────────────────────┘

Investors EOA ─────────────────────────→ invest / Getter / NFT参照
ChainLinkKeeper (forwarder) ───────────→ Automation Contract
```

---

## 1. Investment Contract

### 1.0 デプロイ時初期化（`initialize`）

| 項目 | 検証 |
|---|---|
| `admins[]` | ゼロアドレス不可（`InvalidAddress`）。calldata 内の重複不可（`AlreadyExistsAdmin`）。`addAdmin` と同一のユニーク制約 |
| `minters[]` | ゼロアドレス不可（`InvalidAddress`） |
| `usdtAddress` / `safeMultisigWallet` | ゼロアドレス不可（`InvalidAddress`）。再初期化不可（`initializer`） |

### 1.1 Safe only

| Function / 項目 | 権限 | 備考 |
|---|---|---|
| `addAdmin` | Safe のみ | admin数上限255（`MAX_ADMINS`）。重複は `AlreadyExistsAdmin` |
| `deleteAdmin` | Safe のみ | 先頭一致1件のみ削除（admin 配列は初期化・追加時にユニークである前提） |
| `addMinter` | Safe のみ | minter数上限255（`MAX_MINTERS`）。重複は `AlreadyExistsMinter` |
| `deleteMinter` | Safe のみ | 先頭一致1件のみ削除 |
| `Dictionary` | Safe のみ | |
| `mapping(bytes4 selector => address imple)` | Safe のみ | |

### 1.2 whiteList only

| Function | 権限 |
|---|---|
| `distributeYield` | whiteList のみ |
| `registerProduct` | whiteList のみ |
| `deposit` | whiteList のみ |
| `withdraw` | whiteList のみ |
| `maturity` | whiteList のみ |
| `setAllowedByTierAddress` | whiteList のみ。配列要素はデプロイ済みコントラクトアドレスのみ・重複不可（`TierSbtNotContract` / `DuplicateEntry`） |
| `setAllowedByTierId` | whiteList のみ。`ids` 配列の重複不可（`DuplicateEntry`）。空配列可。tokenId=0 可 |
| `setProductRequiredTier` | whiteList のみ。既存商品の `requiredTier` を更新（満期済み商品も可。`requiredTier != 0` 時はレジストリ必須） |

### 1.3 minter only

| Function | 権限 | 実装 |
|---|---|---|
| `mintNFT` | minter のみ | `src/investment/functions/onlyMinters/MintNFT.sol` |

### 1.4 NFT owner only（エスクロー請求）

| Function | 権限 |
|---|---|
| `claimYield` | 当該 `tokenId` の `ownerOf` のみ（`nonReentrant`） |
| `claimPrincipal` | 同上（満期時 Push 失敗でエスクローされた元本） |

### 1.5 All accessible

| Function | 権限 |
|---|---|
| `Getter` | 全員参照可（`getUnclaimedYield` / `getClaimableForToken` 等含む） |
| `invest` | 全員実行可 |

---

## 2. NFT Contract

### 2.1 InvestmentContract only

| Function | 権限 |
|---|---|
| `mint(uint256 productId, address to)` | Investment Contract のみ |
| `burn(uint256 tokenId)` | Investment Contract のみ |

### 2.2 All accessible

| Function | 権限 |
|---|---|
| `getTokenIds(uint256 productId)` | 全員参照可 |

### 2.3 whiteList only

| Function | 権限 |
|---|---|
| `setURI(string tokenId)` | whiteList のみ |

---

## 3. 権限主体

### 3.1 Safe Multisig Wallet

| 主体 | 役割 |
|---|---|
| Safe Multisig Wallet | 最上位管理 |
| EOA x 4 + Dev EOA | Safe の署名者 |

### 3.2 whiteList address

| 主体 | 役割 |
|---|---|
| Administrators (Admin EOA) | 運用管理 |
| ChainLink / Automation Contract | 自動実行系 |

### 3.3 minter address

| 主体 | 役割 |
|---|---|
| Minter EOA(s) | JPY 手動ミント（`mintNFT`） |

### 3.4 外部利用者

| 主体 | 役割 |
|---|---|
| Investors EOA | `invest` 実行、Getter / NFT参照 |
| ChainLinkKeeper (forwarder) | Automation Contract 起動 |

---

## 4. ルーティングの見方

| From | To | 用途 |
|---|---|---|
| Safe Multisig Wallet | Safe only 領域 | 管理者・minter 追加・削除、Dictionary更新 |
| whiteList address | whiteList only 領域 | 商品登録、分配、満期、入出金、Tier設定 |
| minter address | minter only 領域 | `mintNFT`（JPY 手動ミント） |
| Investors EOA | All accessible 領域 | `invest` / Getter |
| Investment Contract | NFT Contract | `mint` / `burn` |
| Investors EOA | NFT Contract | `getTokenIds` |
| whiteList address | NFT Contract | `setURI` |
| ChainLinkKeeper | Automation Contract | 自動実行トリガ |

---

## 5. 一言まとめ

- **Safe**: 最上位の設定変更（admin / minter 管理含む）
- **whiteList**: 日常運用・自動実行
- **minter**: JPY 手動ミント（`mintNFT` のみ）
- **Investor**: 投資と参照
- **Investment Contract**: NFT の mint / burn 実行主体
