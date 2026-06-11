| 項目     | 内容                                                                                                            |
| ------ | ------------------------------------------------------------------------------------------------------------- |
| シナリオ概要 | ERC721 / ERC1155 混在時の OR 判定検証。TierRegistry に 721 と 1155 の両方を設定し、どちらか一方の条件を満たせば Invest / MintNFT が許可されることを確認する |
| 関数名    | `test_scenario11_TierRegistry_Mixed721And1155_ORLogic`                                                        |

| 登録商品       | 登録内容                                                                                                                                                                                                                                  |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ProductID1 | 募集額：1,000,000USDT<br>一口の額：250USDT<br>募集締切日：2028-01-20 00:00:00 UTC<br>満期日：2028-04-30 00:00:00 UTC<br>予想利回り：5%<br>運用開始日：2028-01-31 00:00:00 UTC<br>初回利益分配日：2028-02-29 00:00:00 UTC<br>利益分配回数：2<br>利益分配の間隔：1 month（=1）<br>requiredTier：1（BRONZE） |

| No | 試験手順                                               | 確認項目                                                                               |
| -: | -------------------------------------------------- | ---------------------------------------------------------------------------------- |
|  1 | BRONZE tier に `[BronzeSBT721, BronzePass1155]` を設定 | Getter で address が 2 件登録されていること                                                    |
|  2 | BRONZE tier に tokenId `[100]` を設定（`setAllowedByTierId(1, BronzePass1155, [100])`） | `TierAllowedByTierIdUpdated` が発火すること / Getter `getAllowedByTierId(1, BronzePass1155)` で id が 1 件登録されていること |
|  3 | ProductID1：商品登録（requiredTier=BRONZE）               | 登録したデータで正しく各項目が登録されていること（F-2026-16955: 手順1より前に登録すると `TierNotConfigured` で revert）                                                           |
|  4 | 投資家A に BronzeSBT721 を付与（ERC1155 は未保有）              | 投資家A の ERC721 `balanceOf > 0` / ERC1155 `balanceOf(100) = 0` であること                 |
|  5 | 投資家B に BronzePass1155 tokenId=100 を付与（ERC721 は未保有） | 投資家B の ERC1155 `balanceOf(100) > 0` / ERC721 `balanceOf = 0` であること                 |
|  6 | 投資家C は ERC721 / ERC1155 とも未保有                      | 両方の残高が 0 であること                                                                     |
|  7 | ProductID1：出資（USDT） 投資家A（ERC721 のみ保有）              | 投資可能であること / 商品情報データが正しく更新されること / NFT が発行されること                                      |
|  8 | ProductID1：出資（USDT） 投資家B（ERC1155 のみ保有）             | 投資可能であること / 商品情報データが正しく更新されること / NFT が発行されること                                      |
|  9 | ProductID1：出資（USDT） 投資家C（どちらも未保有）                  | `NotEligible(1)` で revert すること / 商品情報データが更新されないこと / NFT が発行されないこと                  |
| 10 | ProductID1：手動 MintNFT investor=投資家B（ERC1155 のみ保有）  | Mint 可能であること / `raisedAmount` が正しく更新されること / NFT が発行されること / `productPool` は更新されないこと |
| 11 | 監視（Getter）：ProductID1 / TierRegistry 取得            | `requiredTier` は 1 のままであること / address 一覧・`getAllowedByTierId(1, BronzePass1155)` の id 一覧・進捗情報が正しく取得できること |
