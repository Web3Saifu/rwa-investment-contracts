| 項目 | 内容 |
| --- | --- |
| シナリオ概要 | 中央レジストリ更新反映検証。既存商品の requiredTier を変更せず、TierRegistry 更新のみで投資可否が変わることを確認する |
| 関数名 | `test_scenario9_TierRegistry_Update_AffectsExistingProduct` |

| 登録商品 | 登録内容 |
| --- | --- |
| ProductID1 | 募集額：1,000,000USDT<br>一口の額：250USDT<br>募集締切日：2028-01-20 00:00:00 UTC<br>満期日：2028-04-30 00:00:00 UTC<br>予想利回り：5%<br>運用開始日：2028-01-31 00:00:00 UTC<br>初回利益分配日：2028-02-29 00:00:00 UTC<br>利益分配回数：2<br>利益分配の間隔：1 month（=1）<br>requiredTier：1（BRONZE） |

| No | 試験手順 | 確認項目 |
| -: | ---- | ---- |
| 1 | BRONZE tier に BronzeSBT のみ設定 `setAllowedSbtByTier(1, [BronzeSBT])` | TierAllowedSbtUpdated が発火すること / Getter で BRONZE tier の登録内容が BronzeSBT のみであること |
| 2 | ProductID1：商品登録（requiredTier=BRONZE） | 登録したデータで正しく各項目が登録されていること |
| 3 | 投資家A に SilverSBT を付与（BronzeSBT は未保有） / 投資家BにGoldSBTを付与（BronzeSBT は未保有） | 投資家A の SilverSBT balanceOf が 1 以上であること / BronzeSBT、GoldSBT balanceOf は 0 であること / 投資家B の GoldSBT balanceOf が 1 以上であること / BronzeSBT、SilverSBT balanceOf は 0 であること |
| 4 | ProductID1：出資（USDT） 投資家A（SilverSBTのみ保有） | NotEligible(1) で revert すること / 商品情報データが更新されないこと / NFT が発行されないこと |
| 5 | BRONZE tier を更新 `setAllowedSbtByTier(1, [BronzeSBT, SilverSBT, GoldSBT])` | TierAllowedSbtUpdated が発火すること / Getter で BRONZE tier の登録内容が 3件に置換されていること |
| 6 | ProductID1：再度 出資（USDT） 投資家A（SilverSBTのみ保有） | 投資可能であること / requiredTier は変更していないこと / 商品情報データが正しく更新されること / NFT が発行されること |
| 7 | ProductID1：手動 MintNFT investor=投資家B（GoldSBTのみ保有） | BRONZE 行に GoldSBT が含まれるため Mint 可能であること / raisedAmount が正しく更新されること / NFT が発行されること |
| 8 | 監視（Getter）：ProductID1 / TierRegistry 取得 | 商品の requiredTier は 1 のままであること / TierRegistry 更新内容が正しく取得できること |
