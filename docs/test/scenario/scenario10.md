| 項目     | 内容                                                                                                     |
| ------ | ------------------------------------------------------------------------------------------------------ |
| シナリオ概要 | ERC1155 基本動作検証。requiredTier=2(SILVER) 商品に対し、TierRegistry の address / id 設定により Invest の可否が変わること、および手動 MintNFT が tier 非依存であることを確認する |
| 関数名    | `test_scenario10_TierRegistry_ERC1155_Register_Invest_MintNFT`                                         |

| 登録商品       | 登録内容                                                                                                                                                                                                                                  |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ProductID1 | 募集額：1,000,000USDT<br>一口の額：250USDT<br>募集締切日：2028-01-20 00:00:00 UTC<br>満期日：2028-04-30 00:00:00 UTC<br>予想利回り：5%<br>運用開始日：2028-01-31 00:00:00 UTC<br>初回利益分配日：2028-02-29 00:00:00 UTC<br>利益分配回数：2<br>利益分配の間隔：1 month（=1）<br>requiredTier：2（SILVER） |

| No | 試験手順                                                                       | 確認項目                                                                                        |
| -: | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
|  1 | SILVER tier の初期状態確認                                                        | `allowedByTierAddress[2]` が空であること / `allowedByTierId[2][pass1155]` は空であること                 |
|  2 | SILVER tier に ERC1155Address のみ設定（`setAllowedByTierAddress(2, [ERC1155])`） | `TierAllowedByTierAddressUpdated` が発火すること / Getter で address が 1 件登録されていること / id は空のままであること |
|  3 | ProductID1：商品登録（requiredTier=SILVER）                                       | 登録したデータで正しく各項目が登録されていること（F-2026-16955: 手順2より前に登録すると `TierNotConfigured` で revert）                                                                    |
|  4 | ProductID1：出資（USDT） 投資家A（ERC1155 id=2 未保有）                                  | `NotEligible(2)` で revert すること / 商品情報データが更新されないこと / NFT が発行されないこと                           |
|  5 | SILVER tier に tokenId 一覧を設定（`setAllowedByTierId(2, pass1155, [2, 3])`）    | `TierAllowedByTierIdUpdated` が発火すること / Getter で id 一覧が 2 件登録されていること                         |
|  6 | ProductID1：再度 出資（USDT） 投資家A（ERC1155 未保有）                                   | 引き続き `NotEligible(2)` で revert すること / 商品情報データが更新されないこと / NFT が発行されないこと                      |
|  7 | 投資家A に ERC1155 tokenId=2 を付与                                  | 投資家A の `balanceOf(id=2)` が 1 以上であること / `id=3` は 0                                      |
|  8 | ProductID1：出資（USDT） 投資家A（ERC1155 id=2 保有）                                  | 投資可能であること / `raisedAmount` `productPool` が正しく更新されること / NFT が発行されること                         |
|  9 | ProductID1：手動 MintNFT investor=投資家B（ERC1155 未保有）                           | Mint 可能であること（tier はオンチェーンでは検証しない） / `raisedAmount` が正しく更新されること / NFT が発行されること / `productPool` は更新されないこと |
| 10 | 投資家B に ERC1155 tokenId=2 を付与                                      | 投資家B の `balanceOf(id=2)` が 1 以上であること                                                       |
| 11 | 投資家C に ERC1155 tokenId=3 を付与後に出資                                     | `setAllowedByTierId(2, pass1155, [2,3])` の OR 条件で投資可能であること                                     |
| 12 | SILVER tier に 2つ目のERC1155（pass1155B）を追加（`setAllowedByTierAddress(2, [pass1155, pass1155B])`） | `TierAllowedByTierAddressUpdated` が発火すること / Getter で address が 2 件登録されていること |
| 13 | pass1155B に tokenId 一覧を設定（`setAllowedByTierId(2, pass1155B, [77])`）       | `TierAllowedByTierIdUpdated` が発火すること / `getAllowedByTierId(2, pass1155B)` で id が 1 件登録されていること |
| 14 | 投資家D に pass1155B tokenId=2 を付与して出資                                     | pass1155 の許可idと同じ数字でも、**pass1155B 側の許可idではない**ため `NotEligible(2)` で revert すること（混線しないこと） |
| 15 | 投資家D に pass1155B tokenId=77 を付与して出資                                     | `setAllowedByTierId(2, pass1155B, [77])` により投資可能であること |
| 16 | 監視（Getter）：ProductID1 / TierRegistry 取得                                    | `requiredTier` は 2 のままであること / address 一覧・`getAllowedByTierId(2, pass1155)` と `getAllowedByTierId(2, pass1155B)` の id 一覧・進捗情報が正しく取得できること |
