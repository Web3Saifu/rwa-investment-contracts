# 1つのProxyで扱える商品の限界

## 前提

### 1. ストレージスロットのサイズ
- 1コントラクトあたり: `2^256` スロット
- 1スロットあたり: `32 byte (256 bit)`
- スロットインデックス範囲: `0` 〜 `2^256 - 1`

### 2. ブロックガスリミット（Ethereum / Polygon）
- 1ブロックの目標サイズ: `15,000,000 gas`
- 1ブロックの上限サイズ: `30,000,000 gas`

---

## 単体のProxyで扱える商品の限界

### 1. サイズ分析

#### ストレージ構造
- `mapping(uint256 productId => Product)` を利用
- マッピング本体のスロットは空のまま確保され、実データは以下で格納される  
  `keccak256(h(k) . p)`
  - `h()`: キー型に応じた関数
  - `k`: マッピングキー
  - `p`: マッピングのスロット位置

#### Productの最新フィールド（`Schema.Product` 準拠）
- `productId: uint256`
- `nftContract: address`（20 byte）
- `offeringAmount: uint256`
- `minInvestment: uint256`
- `offeringEndDate: uint256`
- `raisedAmount: uint256`
- `productPool: uint256`
- `maturityDate: uint256`
- `expectedYield: uint256`
- `operationStartDate: uint256`
- `distributionStartDate: uint256`
- `totalDistributionCount: uint256`
- `distributionInterval: uint256`
- `distributedCount: uint256`
- `distributedYieldPerCount: uint256`
- `distributedTokenId: uint256`
- `totalReturnedAmount: uint256`
- `maturedTokenId: uint256`
- `requiredTier: uint8`
- `isMaturity: bool`
- `isInsufficientBalance: bool`
- `isMonthEnd: bool`

#### 使用スロット数（最新版フィールド基準）
- `Product` 本体:
  - `uint256` が17個、`address` が1個で合計18スロット相当
  - `uint8 + bool + bool + bool` は同一スロットにパックされるため追加1スロット
  - 合計で **1商品あたり18スロット**
- さらに `productIdKeys`（`uint256[]`）に `productId` を保持するため、商品1件ごとに **+1スロット**
- したがって、実運用上の概算は **1商品あたり約19スロット**

`n` 件の場合:
- `products` 分: `18n`
- `productIdKeys` 分: `n`
- 合計: `19n`（+ 配列長管理用の固定スロット1）

10,000件の場合:
- `18 * 10,000 + 10,000 = 190,000` スロット
- 固定スロットを含めると概ね `190,001` スロット

### 2. ストレージ衝突の確率的分析

`n` 個の `productId` に対する衝突確率 `p`:

`p ≈ 1 - e^(-n^2 / 2N)`  
（ここで `N = 2^256`、`keccak256` の出力空間）

- 衝突確率50%となる `n`:
  - `n ≈ √(2N * ln(2))`
  - つまり `n ≈ 2^128`
- 衝突確率を `10^-12`（1兆分の1）に抑える場合:
  - `n ≈ 2^77` 程度
- 実質的に無視できるほど小さい確率として:
  - `2^32`（約43億）個

#### 使用可能なスロット（本ドキュメント上の整理）
- 約43億スロット

### 3. ブロックガスリミットによる制約
- 新規プロダクト登録時、保存対象は最新版フィールド基準で概ね `18〜19` スロット
- 1回あたり約`20,000 gas`（ゼロ→非ゼロ書き込み）として保守的に試算

計算:
- `30,000,000 / (20,000 * 19) ≈ 78`  
  → 1ブロックあたり約78個（上限ケース）
- `5,000,000 / (20,000 * 19) ≈ 13`  
  → 1トランザクションあたり約13個（上限ケース）

補足:
- 想定としては「1トランザクション = 1商品登録」
- 実際のgasは、ゼロ値書き込みやウォーム/コールド状態により上下する

### 4. 結論
- 現実的な運用上の上限: `5,000件〜10,000件`
- EVM/コントラクトの理論面だけなら、何千万件規模も登録余地はある
- ただしフロントエンド観点（一覧取得・レスポンス）を考えると、`5,000〜10,000件` が現実的
