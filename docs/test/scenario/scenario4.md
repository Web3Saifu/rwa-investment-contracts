| 項目 | 内容 |
| --- | --- |
| シナリオ概要 | アクセス制御検証。すべての関数のアクセス制限を試験し、特にSafeとwhiteListの管理者同士の住み分けができているかを確認する |
| 関数名 | `test_access_control` |

| No | 試験手順 | 確認項目 |
| -: | ---- | ---- |
|  1 | 以下のアドレスを用意する（Safe / admin1 / admin2 / admin3 / admin4 / forwarder） | - |
|  2 | Safeでデプロイを行う | デプロイできること |
|  3 | Safeで以下の管理者追加を行う（admin1 / admin2 / admin3 / Automationコントラクト） | 登録されていること |
|  4 | admin3で以下の管理者追加を行う（admin4） | 権限エラーとなること |
|  5 | admin3で以下の管理者削除を行う（admin2） | 権限エラーとなること |
|  6 | safeで以下の関数呼び出しを行う（mintNFT / withdraw / deposit / registerProduct / distributeYield / maturity / setAllowedSbtByTier） | 権限エラーとなること |
|  7 | admin2で以下の関数呼び出しを行う（mintNFT / withdraw / deposit / registerProduct / distributeYield / maturity / setAllowedSbtByTier） | 呼び出せること（NotAdmin / NotOwner権限エラーにならないこと） |
|  8 | safeで以下の関数呼び出しを行う（performupkeep） | 権限エラーとなること |
|  9 | admin2で以下の関数呼び出しを行う（performupkeep） | 権限エラーとなること |
| 10 | forwarderで以下の関数呼び出しを行う（performupkeep） | 呼び出せること（権限エラーにならないこと） |
