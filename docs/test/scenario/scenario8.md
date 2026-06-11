| 項目 | 内容 |
| --- | --- |
| シナリオ概要 | 主要動作検証。requiredTier を持つ商品登録、TierRegistry 設定、Invest の可否判定、手動 MintNFT（tier 非依存）、Getter 参照までを一連で確認する（NONE / BRONZE、SBT未保有時の invest 拒否、SBT保有時の invest 許可、イベント・状態更新） |
| 関数名 | `test_scenario8_TierRegistry_Register_Invest_MintNFT` |

| 登録商品 | 登録内容 |
| --- | --- |
| ProductID1 | 募集額：1,000,000USDT<br>一口の額：250USDT<br>募集締切日：2028-01-20 00:00:00 UTC<br>満期日：2028-04-30 00:00:00 UTC<br>予想利回り：5%<br>運用開始日：2028-01-31 00:00:00 UTC<br>初回利益分配日：2028-02-29 00:00:00 UTC<br>利益分配回数：2<br>利益分配の間隔：1 month（=1）<br>requiredTier：0（NONE） |
| ProductID2 | 募集額：1,000,000USDT<br>一口の額：250USDT<br>募集締切日：2028-01-20 00:00:00 UTC<br>満期日：2028-04-30 00:00:00 UTC<br>予想利回り：5%<br>運用開始日：2028-01-31 00:00:00 UTC<br>初回利益分配日：2028-02-29 00:00:00 UTC<br>利益分配回数：2<br>利益分配の間隔：1 month（=1）<br>requiredTier：1（BRONZE） |

| No | 試験手順 | 確認項目 |
| -: | ---- | ---- |
|  1 | TierRegistry 初期状態確認：BRONZE tier の登録内容取得 | BRONZE tier の allowedSbtByTier が空であること |
|  2 | ProductID1：商品登録（requiredTier=NONE） | 登録したデータで正しく各項目が登録されていること |
|  3 | BRONZE tier に BronzeSBT を設定 `setAllowedSbtByTier(1, [BronzeSBT])` | TierAllowedSbtUpdated が発火すること / Getter で BRONZE tier の登録内容が BronzeSBT 1件であること |
|  4 | ProductID2：商品登録（requiredTier=BRONZE） | 登録したデータで正しく各項目が登録されていること（F-2026-16955: tier 未設定のままでは `TierNotConfigured` で revert） |
|  5 | Getter で ProductID1 / ProductID2 の requiredTier を取得 | ProductID1 は 0、ProductID2 は 1 であること |
|  6 | ProductID1：出資（USDT） 投資家A（SBT未保有） | requiredTier=NONE のため投資可能であること / 商品情報データが正しく更新されていること / NFT が発行されていること |
|  7 | ProductID2：出資（USDT） 投資家B（SBT未保有） | requiredTier=BRONZE のため NotEligible(1) で revert すること / 商品情報データが更新されないこと / NFT が発行されないこと |
|  8 | ProductID2：再度 出資（USDT） 投資家B（SBT未保有） | 引き続き NotEligible(1) で revert すること / 商品情報データが更新されないこと / NFT が発行されないこと |
|  9 | 投資家B に BronzeSBT を付与 | 投資家B の BronzeSBT balanceOf が 1 以上であること |
| 10 | ProductID2：出資（USDT） 投資家B（BronzeSBT保有） | 投資可能であること / raisedAmount / productPool が正しく更新されること / NFT が発行されること |
| 11 | ProductID2：手動 MintNFT investor=投資家C（SBT未保有） | Mint 可能であること（tier はオンチェーンでは検証しない） / raisedAmount が正しく更新されること / NFT が発行されること / productpoolが更新されないこと |
| 12 | 投資家C に BronzeSBT を付与 | 投資家C の BronzeSBT balanceOf が 1 以上であること |
| 13 | 監視（Getter）：ProductID1 / ProductID2 / TierRegistry 取得 | 登録情報・requiredTier・進捗情報・TierRegistry 登録内容が正しく取得できること |
