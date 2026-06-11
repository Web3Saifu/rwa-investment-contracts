| 項目 | 内容 |
| --- | --- |
| シナリオ概要 | 月次分配の日付計算・**Push 成功時の** 残高・シミュレーション突合（isMonthEnd、うるう年）。送金失敗時はエスクロー + claim（F-2026-16871） |
| 関数名 | `test_scenarioM_MonthlyDistribution_MonthEnd_LeapYear` |

| 登録商品 | 登録内容 |
| --- | --- |
| ProductID1 | 募集額：1,000,000USDT<br>一口の額：250USDT<br>募集締切日：2028-01-20 00:00:00 UTC<br>満期日：2028-04-30 00:00:00 UTC<br>予想利回り：5%<br>運用開始日：2028-01-31 00:00:00 UTC（※月末）<br>初回利益分配日：2028-02-29 00:00:00 UTC（※うるう年・月末）<br>利益分配回数：2<br>利益分配の間隔：1 month（=1）<br>狙い/観点：<br>1) 月末補正：1/31開始→2/29→3/31 のように「月末に寄る」か<br>2) うるう年：2028/02/29 を扱えるか<br>3) 境界：分配日-1秒は対象外／分配日ちょうどは対象<br>4) シミュレーション：simulatePeriodYield / simulateTotalYield と実分配が矛盾しないか<br>補足：isMonthEnd が自動判定（distributionStartDate が月末なら true）になる想定で検証 |

| No | 試験手順 | 確認項目 |
| -: | ---- | ---- |
|  1 | ProductID1：商品登録（月次・月末補正/うるう年）<br>registerProduct(ProductID1, params...)<br>getProduct(ProductID1) で登録値一致確認（interval=1、totalDistributionCount=2、operationStartDate=2028/01/31、distributionStartDate=2028/02/29） | 登録したデータで正しく各項目が登録されていること |
|  2 | ProductID1：出資（USDT）募集額未達、投資家2人<br>invest(ProductID1, investorA)<br>invest(ProductID1, investorB)<br>raisedAmount / productPool 更新確認、NFT balance/tokenIdCounter 確認 | 商品情報データが正しく更新されていること / NFTが発行されていること |
|  3 | 利益分配前シミュレーション取得（初回・総額）<br>simulateFirstPeriodYield(ProductID1) を取得（firstSim）<br>simulateTotalYield(ProductID1) を取得（totalSim）<br>assert firstSim > 0, totalSim > 0 | 利益分配前に想定分配額が取得できること / 総分配シミュレーションが取得できること / 値が0より大きいこと |
|  4 | 管理者入金（分配原資＋元本）<br>deposit(ProductID1, raisedAmount + totalSim) を実行<br>getProduct(ProductID1).productPool が増えていること | 入金後 productPool が増加していること |
|  5 | 境界確認：分配日 - 1秒<br>vm.warp(2028-02-29 00:00:00 UTC - 1)<br>checkUpkeep() を実行し upkeepNeeded=false を確認 | checkUpkeep が false（対象なし） |
|  6 | 初回分配日へ時間移動<br>vm.warp(2028-02-29 00:00:00 UTC) | - |
|  7 | checkUpkeep（初回）<br>checkUpkeep() を実行<br>performData を decode して actionType=DistributeYield, productId=1 を確認 | ProductID1 が DistributeYield 対象であること |
|  8 | performUpkeep（初回分配）<br>performUpkeep(performData)<br>投資家2人のUSDT残高増加を確認<br>getProduct(ProductID1).distributedCount==1 を確認 | 利益分配が正しく行われていること / distributedCount が 1 になること |
|  9 | 初回：実分配額とシミュレーション突合<br>実分配合計 actual1 を算出<br>理論値 periodYield1 を算出（calculateFirstDistributionPeriod→calculatePeriodYield）<br>assert actual1 >= periodYield1<br>assert actual1 <= firstSim | 実分配合計が、理論値以上＆firstSim 以下（許容誤差込み） |
| 10 | 次回分配日が「月末補正」になっていることを確認<br>DistributionDateLib.calculateNextDistributionDate(...) で nextDate を取得<br>nextDate が 2028-03-31 00:00:00 UTC（期待）であることを確認 | 次回分配日が 2028-03-31 00:00:00 UTC になること |
| 11 | 境界確認：2回目分配日 - 1秒<br>vm.warp(2028-03-31 00:00:00 UTC - 1)<br>checkUpkeep() => upkeepNeeded=false を確認 | checkUpkeep が false（対象なし） |
| 12 | 2回目分配日へ時間移動<br>vm.warp(2028-03-31 00:00:00 UTC) | - |
| 13 | checkUpkeep（2回目）<br>checkUpkeep() を実行<br>actionType=DistributeYield, productId=1 を確認 | ProductID1 が DistributeYield 対象であること |
| 14 | performUpkeep（2回目分配）<br>performUpkeep(performData)<br>投資家2人のUSDT残高増加を確認<br>getProduct(ProductID1).distributedCount==2 を確認 | 利益分配が正しく行われていること / distributedCount が 2 になること |
| 15 | 2回目：実分配額とシミュレーション突合<br>simulateSecondOnwardsPeriodYield(ProductID1) を分配直前に取得（secondSim）<br>実分配合計 actual2 を算出<br>理論値 periodYield2 を算出（calculateDistributionPeriod→calculatePeriodYield）<br>assert actual2 >= periodYield2<br>assert actual2 <= secondSim | 実分配合計が、理論値以上＆simlate 以下（許容誤差込み） |
| 16 | 最終：実分配合計と総分配シミュレーション突合<br>totalActual=actual1+actual2<br>simulateTotalYield(ProductID1) を再取得（totalSim2）<br>assert totalActual >= (periodYield1+periodYield2)<br>assert totalActual <= totalSim2 | actual1+actual2 が totalSim 以下（許容誤差込み）かつ理論合計以上 |
| 17 | 冪等性：同一performDataで再実行<br>vm.expectRevert(DistributionCompleted 等)<br>performUpkeep(2回目のperformData) を再実行 | 正しく revert すること |
| 18 | 監視（Getter）<br>getProduct(ProductID1) で distributedCount=2、raisedAmount、productPool の整合など確認 | 登録情報・進捗情報が正しく取れること |
