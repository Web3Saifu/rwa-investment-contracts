| 項目 | 内容 |
| --- | --- |
| シナリオ概要 | 主要動作検証（zeroYield）。`expectedYield=0`・長期満期・単回分配の条件で、分配時の支払額が0であること、および満期時に元本のみ償還されることを確認する |
| 関数名 | `test_zeroYield_longMaturity_singleDistribution_zeroPayout_thenMaturity` |

| 登録商品 | 登録内容 |
| --- | --- |
| ProductID101 | 募集額：1,000,000 USD（`1_000_000_000_000` / 6dec）<br>一口の額：250 USD（`250_000_000` / 6dec）<br>募集締切日：`2025-01-25 00:00:00 UTC` 相当（`now + 24 days`）<br>運用開始日：募集締切日と同日<br>初回利益分配日：運用開始日と同日<br>満期日：`now + 1000 * 365 days`（実質長期）<br>予想利回り：0%<br>利益分配回数：1<br>利益分配の間隔：0（単回分配のため許容）<br>requiredTier：0（NONE） |

| No | 試験手順 | 確認項目 |
| -: | ---- | ---- |
|  1 | 初期時刻を `2025-01-01 00:00:00 UTC` に設定する | 基準時刻が正しく設定されること |
|  2 | ProductID101 を登録する（`expectedYield=0`, 単回分配, 長期満期） | 登録したデータで正しく各項目が登録されていること |
|  3 | JPY経路相当（`mintNFT`）で募集額の半分を投資家2名へ割当する | NFT が発行され、投資情報が更新されること |
|  4 | USDT経路（`invest`）で残り半分を投資家2名が出資する | 投資情報が更新されること |
|  5 | `getProduct` を取得する | `raisedAmount == offeringAmount` であること |
|  6 | 管理者が `withdraw` で productPool 全額を引き出す | コントラクトのUSDT残高が0になること |
|  7 | 管理者が元本分のみ `deposit` する（`offeringAmount`） | productPool に元本のみ再入金されること |
|  8 | 初回分配日（運用開始日）へ時刻を進める | - |
|  9 | `checkUpkeep` を実行し performData を decode する | `DistributeYield` が返ること / `productId=101` であること |
| 10 | 分配前の投資家残高・pool残高を取得する | 分配前比較用の基準値が取得できること |
| 11 | `performUpkeep`（forwarder）で分配処理を実行する | 分配処理が実行できること |
| 12 | 分配後の状態を確認する | `distributedCount == 1` であること / 投資家1,2の増分が0であること / pool減少が0であること |
| 13 | 満期日まで時刻を進めて `checkUpkeep` を実行する | `Maturity` が返ること / `productId=101` であること |
| 14 | 償還前に投資家残高・pool残高・NFT principal内訳を取得する | 投資家別元本・合計元本が算出できること |
| 15 | `performUpkeep`（forwarder）で満期処理を実行する | 満期処理が実行できること |
| 16 | 満期後の投資家残高を確認する | 投資家1,2へそれぞれ元本分が返還されること |
| 17 | 満期後の商品状態・poolを確認する | `isMaturity == true` であること / `totalReturnedAmount == totalPrincipal` であること / pool減少量が `totalReturnedAmount` と一致すること |
