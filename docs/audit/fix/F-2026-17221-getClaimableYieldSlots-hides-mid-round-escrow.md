# F-2026-17221: getClaimableYieldSlots がマルチバッチ配分中のエスクローをインデクサーに隠す

| 項目 | 内容 |
|------|------|
| コード | F-2026-17221 |
| 種別 | Vulnerability |
| 深刻度 | Low（影響度 2/5、尤度 3/5） |
| 対象 | `Getter.sol` — `getClaimableYieldSlots`, `getClaimableForToken` |
| 状態 | **修正対応** |

---

## 1. 概要

`distributeYield` は NFT ホルダー数がサブバッチ上限（50）を超える商品では複数回の TX に分割して配分を実行する。各サブバッチで送金に失敗したホルダーのエスクローは `distributionIndex = product.distributedCount + 1` に書き込まれるが、`distributedCount` のインクリメントは **最終サブバッチの完了時のみ** に行われる。

一方、`getClaimableYieldSlots` はループ上限を `product.distributedCount` としているため、進行中ラウンド（中間バッチ完了〜最終バッチ完了の間）に書き込まれたエスクローエントリが **view ヘルパーから見えなくなる**。

---

## 2. 根本原因

### 2.1 distributeYield のバッチ処理

```solidity
// DistributeYield.sol（抜粋）
uint256 distributionIndex = product.distributedCount + 1;  // L107

// エスクロー書き込み（送金失敗時）
escrow.unclaimedYield[productId][nftInfos[i].tokenId][distributionIndex] = individualPeriodYield;  // L125

// distributedCount は最終トークン到達時にのみインクリメント
if (nftInfos[i].tokenId == lastTokenId) {  // L134
    product.distributedCount++;             // L135
}
```

- 第 1 サブバッチ完了後: エスクローは index `1`（= `distributedCount + 1`）に書き込み済み、`distributedCount` は `0` のまま
- 第 2 サブバッチ完了後: `distributedCount` が `1` にインクリメントされる

### 2.2 getClaimableYieldSlots のループ上限

```solidity
// Getter.sol（抜粋）
uint256 maxIndex = product.distributedCount;  // L258
for (uint256 i = 1; i <= maxIndex; i++) {     // L261
    // ...
}
```

`distributedCount == 0` の間、ループは一度も実行されず、index `1` に既に存在するエスクローは返却されない。

---

## 3. 影響

| 観点 | 内容 |
|------|------|
| 資金安全性 | **影響なし** — エスクローはストレージに正しく書き込まれており、`getUnclaimedYield(productId, tokenId, distributedCount + 1)` および `claimYield(productId, tokenId, distributedCount + 1)` で参照・請求可能 |
| フロントエンド / インデクサー | `getClaimableYieldSlots` に依存する UI 表示で、マルチバッチ配分中にエスクロー残高が **一時的にゼロ表示** になる |
| `getClaimableForToken` | 内部で `getClaimableYieldSlots` を呼ぶため **同様に影響** |
| 隠蔽ウィンドウ | 第 1 サブバッチ完了〜最終サブバッチ完了までの全期間（2 TX 間に運用上の間隔がある場合は数分〜数時間） |

---

## 4. 監査 PoC の要点

1. NFT ホルダー 60 名の商品を登録（バッチサイズ 50 → 2 サブバッチ必要）
2. tokenId = 30 のホルダーを USDT ブロック対象に設定
3. 第 1 サブバッチ実行（ids 1–50）→ ブロックされたホルダーのエスクローが `index 1` に書き込まれる
4. **バグ確認**: `getClaimableYieldSlots(1, 30).length == 0`（ループが `1..0` で空）
5. ただし `getUnclaimedYield(1, 30, 1)` では正しい金額が返る
6. 第 2 サブバッチ実行（ids 51–60）→ `distributedCount` が `1` にインクリメント
7. `getClaimableYieldSlots(1, 30).length == 1` に変わり、スロットが正しく表示される

PoC ファイル: `test/PoC_GetClaimableYieldSlotsHidesMidRound.t.sol`（監査提出物）

---

## 5. 修正方針

### 5.1 `getClaimableYieldSlots` のループ上限を修正

**修正前:**

```solidity
uint256 maxIndex = product.distributedCount;
```

**修正後:**

```solidity
uint256 maxIndex = product.distributedCount + 1;
if (maxIndex > product.totalDistributionCount) {
    maxIndex = product.totalDistributionCount;
}
```

この修正により:

- `distributedCount + 1` で進行中ラウンドの index もカバー
- `totalDistributionCount` でキャップし、全配分完了後のオーバーフロー参照を防止
- 進行中ラウンドでエスクローが書かれていない token に対しては `unclaimedYield > 0` チェックでスキップされるため誤表示なし

### 5.2 エッジケース検証

| シナリオ | 修正後 `maxIndex` | 動作 |
|---|---|---|
| 配分未開始、バッチも未実行 | `min(1, totalDistributionCount)` | index 1 をチェック → 0 なのでスキップ。正常 |
| 第 1 ラウンド中間バッチ完了 | `min(1, totalDistributionCount)` | index 1 のエスクローが表示される。修正目的達成 |
| 全配分完了 (`distributedCount == totalDistributionCount`) | `min(totalDistributionCount + 1, totalDistributionCount)` = `totalDistributionCount` | 全完了分を表示。正常 |

### 5.3 NatSpec の追記

修正後の関数に「進行中ラウンドのエスクローも best-effort で含まれる」旨をコメントに追記する。

### 5.4 影響を受けない関連箇所

- **`Claim.claimPrincipal`** (L86): `product.distributedCount` をループ上限にしているが、`isMaturity == true` が前提であり、満期時は全配分完了済み（`distributedCount == totalDistributionCount`）のため影響なし
- **`claimYield`**: `distributionIndex` を直接引数で受け取るため影響なし

---

## 6. 対応方針（確定）

| 項目 | 方針 |
|------|------|
| コントラクト修正 | `Getter.sol` — `getClaimableYieldSlots` のループ上限変更 |
| NatSpec | 修正後の関数コメントに best-effort 表示である旨を追記 |
| テスト | 修正後に既存テスト全通過を確認 + 監査 PoC ベースの回帰テスト追加 |
| 監査への回答 | 推奨通りに修正。修正コミットを添付して返答 |

### 6.1 監査返答案（ドラフト）

> F-2026-17221 について、指摘の通り `getClaimableYieldSlots` のループ上限が `distributedCount` であるため、マルチバッチ配分中のエスクローエントリがヘルパーから見えない期間が発生する問題を確認しました。  
> 推奨に従い、ループ上限を `min(distributedCount + 1, totalDistributionCount)` に変更し、進行中ラウンドのエスクローも表示されるよう修正しました。  
> 資金の安全性には影響がないことを確認済みです。修正コミットを添付します。

---

## 7. タスクチェックリスト

### 7.1 コントラクト

- [x] `Getter.sol` — `getClaimableYieldSlots` のループ上限を `min(distributedCount + 1, totalDistributionCount)` に変更
- [x] NatSpec に進行中ラウンドの best-effort 表示である旨を追記

### 7.2 テスト

- [x] 修正後に既存テスト全通過を確認（`forge test` — 228 tests passed）
- [x] 監査 PoC ベースの回帰テスト作成・実行（`test/fix/F-2026-17221_GetClaimableYieldSlotsMidRound.t.sol` — 5 tests passed）

### 7.3 ドキュメント・監査

- [x] 本ファイルの作成
- [ ] 監査報告書への正式回答

---

## 8. 参考リンク

| リソース | パス |
|----------|------|
| Getter（対象） | `src/investment/functions/Getter.sol` |
| 利払い分配 | `src/investment/functions/onlyWhiteLists/DistributeYield.sol` |
| Claim（影響なし） | `src/investment/functions/Claim.sol` |
| スキーマ | `src/investment/storage/Schema.sol` |
| 回帰テスト | `test/fix/F-2026-17221_GetClaimableYieldSlotsMidRound.t.sol` |
| 監査 PoC | `test/PoC_GetClaimableYieldSlotsHidesMidRound.t.sol`（想定） |

---

## 9. 変更履歴

| 日付 | 内容 |
|------|------|
| 2026-05-26 | 初版作成（監査指摘 F-2026-17221 の整理・修正方針策定） |
| 2026-05-26 | 修正実装完了（Getter.sol ループ上限変更 + 回帰テスト 5 件追加、全 228 テスト通過） |
