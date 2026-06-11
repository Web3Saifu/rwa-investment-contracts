# F-2026-17029: Flat Admin Whitelist による全権限付与（Mint 権限の分離で最小対応）

| 項目 | 内容 |
|------|------|
| コード | F-2026-17029 |
| 種別 | Vulnerability |
| 深刻度 | Low（監査評価: Impact 3/5, Likelihood 2/5） |
| 対象 | `OnlyWhiteListsBase.sol`, `ControlAdmin.sol`, `MintNFT.sol`, `Initialize.sol`, `InvestmentDeployer.sol` |
| 状態 | **対応済み** |

---

## 1. 概要

現状のプロトコルは、特権操作を単一の `onlyWhiteLists`（admin 配列）でガードしており、admin に追加されたアドレスは多数の重要関数を同一権限で実行できる。

監査では RBAC（役割分離）により blast radius を縮小することが推奨されているが、本プロジェクトでは **最小変更でリスクの大きい `mintNFT` 権限のみを分離**し、`onlyMinters` による **Minter 専用リスト**でガードする（他の特権関数は当面 `onlyWhiteLists` 継続）。

---

## 2. 現状の実装

### 2.1 admin 判定（Flat whitelist）

`OnlyWhiteListsBase.onlyWhiteLists` は `Storage.WhiteListsState().admins` の線形検索で `msg.sender` が含まれるかを判定し、含まれていれば全ての `onlyWhiteLists` 関数が実行可能となる。

- `src/investment/functions/onlyWhiteLists/OnlyWhiteListsBase.sol`
- `src/investment/storage/Schema.sol`（`$WhiteListsState.admins`）

### 2.2 admin の追加・削除（onlyOwner）

admin の追加・削除は `ControlAdmin.addAdmin/deleteAdmin` で行われ、`onlyOwner`（SAFE のマルチシグ）により保護されている。

- `src/investment/functions/onlyOwner/ControlAdmin.sol`

### 2.3 `mintNFT` の権限（指摘時: admin と同一）

指摘時点では `MintNFT.mintNFT` は `onlyWhiteLists` で保護されており、admin に入っていれば実行可能であった。

対応後は `onlyMinters` で保護し、minter リストに含まれるアドレスのみ実行可能とする。

- `src/investment/functions/onlyMinters/MintNFT.sol`

---

## 3. 指摘のメカニズム（要約）

admin リストに登録されたアドレスは、商品の登録・資金操作・分配・満期処理・tier 設定・NFT ミントを同一権限で実行できる。

この設計では、特定の運用キーが侵害された場合に、意図しない強権限操作が可能になり得る（監査では「ロール分離がない」こと自体が指摘対象）。

---

## 4. 影響整理（本プロジェクトの見立て）

本プロジェクトでは、全権限の中でも特に **`mintNFT` が最もクリティカル**と整理する。

- `mintNFT` は投資家アドレス（`investor`）を指定でき、支払いフローと独立に投資ポジション（NFT）と `raisedAmount` を進め得るため、侵害時の影響が大きい。
- `withdraw` は送金先が `SAFE_MULTISIG_WALLET` 固定であり、侵害 admin が任意送金先に資金を移すことはできない（ただし、運用上の誤操作・逸脱の観点のリスクは残る）。

よって、監査推奨の全面 RBAC（bitmask）ではなく、**mint 権限のみを分離**して blast radius を低減する。

---

## 5. 対応方針（確定）

### 5.1 基本方針

| 項目 | 方針 |
|------|------|
| コントラクト修正 | **採用** — `mintNFT` のみ `onlyMinters` に切替 |
| admin 管理 | 既存どおり `onlyOwner` による `addAdmin/deleteAdmin` を継続 |
| minter 管理 | **`onlyOwner`（SAFE マルチシグ）** の `addMinter/deleteMinter` を新設 |
| 変更範囲 | `MintNFT` とその権限ガード、minter ストレージ、初期化/デプロイ配線、関連テスト |
| 監査推奨 RBAC | 本チケットでは **全面導入しない**（将来拡張余地として残す） |

### 5.2 実装イメージ（設計）

- `src/investment/functions/onlyMinters/OnlyMintersBase.sol`（新規）
  - `modifier onlyMinters()`（または `onlyMinter`）
  - `_isMinter()` は `MintersState` を参照して判定
- `MintNFT` は `onlyWhiteLists` を外し `onlyMinters` に置換
- `ControlMinter`（名称は任意）として `addMinter/deleteMinter` を追加し、`onlyOwner` で保護
- `Schema` / `Storage` に `MintersState` を追加（ERC-7201 の新 storage slot を付与）

### 5.3 初期化とデプロイ配線（採用: Option B）

- `Initialize.initialize` の引数に `minters` を追加し、初期化時に minter を登録する（Option B を採用）。
- `MintNFT` は `src/investment/functions/onlyMinters/MintNFT.sol` に配置する。
- `InvestmentDeployer` は `bundle/investment/functions/onlyMinters/MintNFT.sol` を import し、`mc.use("MintNFT", MintNFT.mintNFT.selector, address(new MintNFT()))` で登録する。
- デプロイ時の minter 初期アドレスは `.env` の `MINTERS_ADDR`（CSV）から読み込む。

参照:

- `script/deploy/InvestmentDeployer.sol`
- `script/deploy/DeployInvestment.s.sol`
- `.env.example`（`MINTERS_ADDR`）

---

## 6. テスト方針

### 6.1 既存テストへの影響（想定）

- `MintNFTTest` は、これまで admin で成功していたケースが **minter でのみ成功**に変わるため、セットアップを更新する（minter 登録 or 直接ストレージ投入）。
- 「NotAdmin revert」を期待している箇所は、「NotMinter（新エラー）」に更新する。
- `registerProduct` / `deposit` / `withdraw` / `distributeYield` / `maturity` / `setAllowedByTier*` の既存テストは、`onlyWhiteLists` 継続のため影響を最小化できる。

### 6.2 回帰

- `forge test` 全体で Green を必須とする。

---

## 7. 監査返答案（ドラフト）

> F-2026-17029 について、監査が指摘した「admin 配列によるフラットな権限付与」に対し、本プロジェクトでは最も影響の大きい `mintNFT` の権限を admin から分離した。  
> 具体的には `mintNFT` を `onlyMinters`（Minter 専用リスト）で保護し、Minter の追加・削除は `onlyOwner`（SAFE マルチシグ）に限定する。  
> これにより、商品登録や資金操作等の既存運用権限を維持しつつ、侵害時の blast radius を縮小する。全面的な RBAC（役割 bitmask）導入は将来の拡張として検討する。

---

## 8. タスクチェックリスト

### 8.1 コントラクト

- [x] `Schema.sol` / `Storage.sol` に `MintersState` を追加（新 storage slot）
- [x] `onlyMinters` ベース（例: `OnlyMintersBase.sol`）を新設
- [x] `mintNFT` を `onlyMinters` に切替（`onlyMinters/MintNFT.sol` に配置）
- [x] `addMinter/deleteMinter`（`onlyOwner`）を追加
- [x] `Initialize` の minter 初期投入（Option B）
- [x] `InvestmentDeployer` の配線を更新（`MintNFT` 実装参照先、minter 管理関数の登録）

### 8.2 テスト

- [x] `MintNFTTest` のセットアップを更新（minter 登録）
- [x] revert 期待を `NotMinter` に更新
- [x] `forge test` 回帰確認

---

## 9. 参考リンク

| リソース | パス |
|----------|------|
| onlyWhiteLists | `src/investment/functions/onlyWhiteLists/OnlyWhiteListsBase.sol` |
| onlyMinters | `src/investment/functions/onlyMinters/OnlyMintersBase.sol` |
| Admin 管理 | `src/investment/functions/onlyOwner/ControlAdmin.sol` |
| Minter 管理 | `src/investment/functions/onlyOwner/ControlMinter.sol` |
| mintNFT | `src/investment/functions/onlyMinters/MintNFT.sol` |
| 初期化 | `src/investment/functions/initializer/Initialize.sol` |
| デプロイ配線 | `script/deploy/InvestmentDeployer.sol` |

---

## 10. 変更履歴

| 日付 | 内容 |
|------|------|
| 2026-05-28 | 初版作成（F-2026-17029 の整理と onlyMinters 方針） |
| 2026-05-29 | 実装反映（`onlyMinters/MintNFT.sol` 配置、デプロイ配線、チェックリスト完了） |

