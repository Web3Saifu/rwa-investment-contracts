# F-2026-17008: distributeYield / maturity における到達不能な owner != address(0) チェック

| 項目 | 内容 |
|------|------|
| コード | F-2026-17008 |
| 種別 | Vulnerability |
| 深刻度 | Info（衝突率 1/5、尤度比 5/5） |
| 対象 | `DistributeYield.sol`, `Maturity.sol` |
| 状態 | **対応済**（2026-05-27 ガード削除） |

---

## 1. 概要

`DistributeYield` および `Maturity` のライフサイクルループ内で `if (nftInfos[i].owner != address(0))` というガード条件が存在するが、上流の `getNFTInfos` が返す配列には `owner == address(0)` のエントリが含まれることはないため、このチェックは**デッドコード**である。

---

## 2. 原因分析

### 2.1 getNFTInfos の実装

`InvestmentNFT.getNFTInfos` は各エントリの `owner` を `ownerOf(tokenId)` で取得する。

```solidity
// InvestmentNFT.sol（抜粋）
function getNFTInfos(uint256 startTokenId) external view returns (NFTInfo[] memory) {
    // ...
    for (uint256 i = 0; i < length; i++) {
        uint256 tokenId = startTokenId + i;
        nftInfos[i] = NFTInfo({
            tokenId: tokenId,
            owner: ownerOf(tokenId),          // ← ここで _requireOwned が呼ばれる
            investmentAmount: _investmentAmounts[tokenId]
        });
    }
    return nftInfos;
}
```

### 2.2 OpenZeppelin v5 の ownerOf

OpenZeppelin v5 の `ownerOf` は内部で `_requireOwned` を呼び出し、存在しない（またはバーン済みの）トークンに対しては **revert** する。

```solidity
// ERC721.sol（OpenZeppelin v5）
function _requireOwned(uint256 tokenId) internal view returns (address) {
    address owner = _ownerOf(tokenId);
    if (owner == address(0)) {
        revert ERC721NonexistentToken(tokenId);
    }
    return owner;
}
```

### 2.3 結論

`getNFTInfos` が正常に返った時点で、配列内の全エントリの `owner` は非ゼロであることが保証される。`owner == address(0)` となるトークンが含まれていれば `getNFTInfos` 自体が revert するため、下流の `owner != address(0)` チェックは常に `true` となり、`false` 分岐には到達できない。

---

## 3. 該当コード

### 3.1 DistributeYield.sol（119 行目）

```solidity
for (uint256 i = 0; i < nftInfos.length; i++) {
    if (nftInfos[i].owner != address(0)) {   // ← デッドコード
        uint256 individualPeriodYield = ...;
        // ... 分配処理 ...
    }                                          // ← 対応する閉じ括弧

    if (nftInfos[i].tokenId == lastTokenId) {
        // ...
    }
}
```

### 3.2 Maturity.sol（76 行目）

```solidity
for (uint256 i = 0; i < nftInfos.length; i++) {
    if (nftInfos[i].owner != address(0)) {   // ← デッドコード
        uint256 investmentAmount = ...;
        // ... 償還処理 ...
    }                                          // ← 対応する閉じ括弧

    if (nftInfos[i].tokenId == lastTokenId) {
        // ...
    }
}
```

---

## 4. 影響

| 観点 | 内容 |
|------|------|
| セキュリティ | なし — ガード条件が常に `true` のため、処理ロジックへの実質的影響はない |
| ガス | 微小だが、不要な比較命令が毎反復で実行される |
| 可読性 | デッドコードの存在がレビュアーを誤導しうる（「address(0) が返るケースがあるのか？」） |

---

## 5. 対応方針

### 5.1 修正内容

監査推奨どおり、両ファイルから `if (nftInfos[i].owner != address(0))` のガードを**削除**し、内部のロジックブロックのネストを 1 段フラット化する。

| ファイル | 修正 |
|----------|------|
| `src/investment/functions/onlyWhiteLists/DistributeYield.sol` | `if (nftInfos[i].owner != address(0)) { ... }` を削除し、内部ロジックをループ直下へ展開 |
| `src/investment/functions/onlyWhiteLists/Maturity.sol` | 同上 |

### 5.2 修正の安全性

- **機能的影響なし**: 削除するガードは常に `true` であり、分岐の除去は実行パスを変えない
- **既存テスト**: 全テストが修正後もそのまま pass するはず（到達不能分岐のため）
- **ガス最適化**: 微小だがループ毎の比較命令が不要になる

---

## 6. タスクチェックリスト

### 6.1 コントラクト

- [x] `DistributeYield.sol`: `if (nftInfos[i].owner != address(0))` ガードの削除
- [x] `Maturity.sol`: `if (nftInfos[i].owner != address(0))` ガードの削除

### 6.2 テスト

- [x] 既存テストの pass 確認（`forge test`）

### 6.3 ドキュメント・監査

- [x] 本ファイル（`docs/audit/fix/F-2026-17008-dead-owner-zero-check.md`）の作成
- [ ] 監査報告書への正式回答

---

## 7. 監査返答案（ドラフト）

> F-2026-17008 について、指摘のとおり `DistributeYield` および `Maturity` 内の `owner != address(0)` チェックはデッドコードである。  
> `getNFTInfos` は内部で OpenZeppelin v5 の `ownerOf` → `_requireOwned` を呼び出し、存在しないトークンに対しては `ERC721NonexistentToken` で revert するため、返却配列に `address(0)` のエントリは含まれ得ない。  
> 推奨どおり、両コントラクトから当該ガード条件を削除する。

---

## 8. 参考リンク

| リソース | パス |
|----------|------|
| 利払い分配 | `src/investment/functions/onlyWhiteLists/DistributeYield.sol` |
| 満期 | `src/investment/functions/onlyWhiteLists/Maturity.sol` |
| NFT（getNFTInfos） | `src/periphery/InvestmentNFT.sol` |
| OpenZeppelin ERC721 | `lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol` |

---

## 9. 変更履歴

| 日付 | 内容 |
|------|------|
| 2026-05-27 | 初版作成（監査指摘 F-2026-17008 の整理・修正方針） |
| 2026-05-27 | `DistributeYield` / `Maturity` からガード削除を実装、シーケンス図を更新 |
