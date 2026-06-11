# F-2026-16865: 初期化およびAdmin管理におけるゼロアドレスバリデーション欠如による永続的設定不正

| 項目 | 内容 |
|------|------|
| コード | F-2026-16865 |
| 種別 | Vulnerability |
| 深刻度 | Low（Impact 3/5, Likelihood 2/5） |
| 対象 | `Initialize.sol`, `ControlAdmin.sol` |
| 状態 | **対応済**（2026-05-27 実装完了） |

---

## 1. 概要

`Initialize` コントラクトの `initialize` 関数は、`admins` 配列に対しては `address(0)` のバリデーションを行っているが、`usdtAddress` および `safeMultisigWallet` パラメータには同等のチェックが存在しない。`initializer` modifier により再実行不可であるため、ゼロアドレスで初期化された場合、再デプロイ以外に回復手段がない。

また、`ControlAdmin` コントラクトの `addAdmin` 関数にもゼロアドレスバリデーションが欠如しており、初期化時に適用されるチェックとの一貫性が失われている。

---

## 2. 現状の実装

### 2.1 初期化（`Initialize.sol`）

```solidity
function initialize(address[] calldata admins, address usdtAddress, address safeMultisigWallet)
    external
    initializer
{
    for (uint8 i = 0; i < admins.length; i++) {
        if (admins[i] == address(0)) revert IInvestmentErrors.InvalidAddress();
        Storage.WhiteListsState().admins.push(admins[i]);
        emit IInvestmentEvents.AdminAdded(admins[i], msg.sender);
    }

    // ゼロアドレスチェックなし
    Storage.ConfigState().USDT_ADDRESS = usdtAddress;
    Storage.ConfigState().SAFE_MULTISIG_WALLET = safeMultisigWallet;
}
```

- `admins` 配列にはゼロアドレスチェックが適用されているが、`usdtAddress` / `safeMultisigWallet` には適用されていない。
- `initializer` modifier により 1 回限りの実行。ゼロアドレスが設定された場合、USDT 転送は全て失敗し、Safe Multisig Wallet 参照も不正となる。

### 2.2 Admin追加（`ControlAdmin.sol`）

```solidity
function addAdmin(address _admin) external onlyOwner {
    address[] memory admins = Storage.WhiteListsState().admins;
    for (uint256 i = 0; i < admins.length; i++) {
        if (admins[i] == _admin) {
            revert IInvestmentErrors.AlreadyExistsAdmin();
        }
    }
    // ゼロアドレスチェックなし
    Storage.WhiteListsState().admins.push(_admin);
    emit IInvestmentEvents.AdminAdded(_admin, msg.sender);
}
```

- `initialize` で `admins` に適用されているゼロアドレスチェックが `addAdmin` には存在しない。
- `address(0)` が admin リストに追加されると、ホワイトリスト反復処理やアクセス制御に予期しない動作が発生する可能性がある。

---

## 3. 脆弱性のメカニズム

```mermaid
flowchart TD
    A[initialize 呼び出し] --> B{usdtAddress == address(0)?}
    B -->|Yes| C[USDT_ADDRESS = address(0) が永続的に設定]
    C --> D[全 USDT 転送が失敗: 回復不能]
    B -->|No| E[正常設定]

    A --> F{safeMultisigWallet == address(0)?}
    F -->|Yes| G[SAFE_MULTISIG_WALLET = address(0) が永続的に設定]
    G --> H[Owner 権限チェックが破綻: 回復不能]
    F -->|No| I[正常設定]

    J[addAdmin 呼び出し] --> K{_admin == address(0)?}
    K -->|Yes| L[admin リストに address(0) が追加]
    L --> M[ホワイトリスト反復に予期しない動作]
    K -->|No| N[正常追加]
```

### 3.1 影響シナリオ

| シナリオ | 結果 |
|----------|------|
| `usdtAddress = address(0)` で初期化 | 全ての USDT 送金（利払い・満期返還）が永続的に失敗 |
| `safeMultisigWallet = address(0)` で初期化 | `onlyOwner` 修飾子が事実上誰にも権限を与えない状態に |
| `addAdmin(address(0))` | admin リストにゼロアドレスが混入し、ホワイトリストチェックに不整合 |

---

## 4. 影響

| 観点 | 内容 |
|------|------|
| 回復可能性 | `initialize` で設定されたアドレスは変更不可のため、再デプロイが必要 |
| 資金への影響 | `usdtAddress` がゼロの場合、利払い・満期返還が全て失敗 |
| アクセス制御 | `safeMultisigWallet` がゼロの場合、Owner 権限が事実上無効化 |
| 一貫性 | `initialize` と `addAdmin` でバリデーション基準が異なる |
| 悪用可能性 | Dependent（デプロイ時の設定ミスが必要） |

---

## 5. 監査推奨（要約）

### 5.1 `initialize` への修正

`usdtAddress` と `safeMultisigWallet` にゼロアドレスチェックを追加:

```solidity
if (usdtAddress == address(0)) revert IInvestmentErrors.InvalidAddress();
if (safeMultisigWallet == address(0)) revert IInvestmentErrors.InvalidAddress();
```

### 5.2 `addAdmin` への修正

重複チェックの前にゼロアドレスチェックを追加:

```solidity
if (_admin == address(0)) revert IInvestmentErrors.InvalidAddress();
```

---

## 6. 対応方針

### 6.1 基本方針: ゼロアドレスバリデーションの追加

監査推奨に従い、両ファイルにゼロアドレスバリデーションを追加する。

### 6.2 `Initialize.sol` への変更

admin ループの直後、config 設定の前にバリデーションを挿入する。

```solidity
function initialize(address[] calldata admins, address usdtAddress, address safeMultisigWallet)
    external
    initializer
{
    // set admins
    for (uint8 i = 0; i < admins.length; i++) {
        if (admins[i] == address(0)) revert IInvestmentErrors.InvalidAddress();
        Storage.WhiteListsState().admins.push(admins[i]);
        emit IInvestmentEvents.AdminAdded(admins[i], msg.sender);
    }

    // ゼロアドレスバリデーション追加
    if (usdtAddress == address(0)) revert IInvestmentErrors.InvalidAddress();
    if (safeMultisigWallet == address(0)) revert IInvestmentErrors.InvalidAddress();

    // set config
    Storage.ConfigState().USDT_ADDRESS = usdtAddress;
    Storage.ConfigState().SAFE_MULTISIG_WALLET = safeMultisigWallet;
}
```

### 6.3 `ControlAdmin.sol` への変更

`addAdmin` 関数の先頭（重複チェックループの前）にバリデーションを挿入する。

```solidity
function addAdmin(address _admin) external onlyOwner {
    if (_admin == address(0)) revert IInvestmentErrors.InvalidAddress();

    address[] memory admins = Storage.WhiteListsState().admins;
    for (uint256 i = 0; i < admins.length; i++) {
        if (admins[i] == _admin) {
            revert IInvestmentErrors.AlreadyExistsAdmin();
        }
    }
    Storage.WhiteListsState().admins.push(_admin);
    emit IInvestmentEvents.AdminAdded(_admin, msg.sender);
}
```

### 6.4 設計判断の根拠

| 判断 | 理由 |
|------|------|
| `initialize` の config 設定前にチェック | 状態変更前にバリデーションを行う fail-fast 原則 |
| `addAdmin` のループ前にチェック | 不要なループ処理を回避しガスを節約 |
| 既存の `InvalidAddress` エラーを再利用 | 新規エラー定義不要、一貫性を維持 |

---

## 7. 実装タスクチェックリスト

### 7.1 コントラクト

- [x] `Initialize.sol` — `usdtAddress` / `safeMultisigWallet` のゼロアドレスチェック追加（§6.2）
- [x] `ControlAdmin.sol` — `addAdmin` のゼロアドレスチェック追加（§6.3）

### 7.2 テスト

- [x] `Initialize.sol` — `usdtAddress = address(0)` で revert するテスト追加
- [x] `Initialize.sol` — `safeMultisigWallet = address(0)` で revert するテスト追加
- [x] `ControlAdmin.sol` — `addAdmin(address(0))` で revert するテスト追加
- [x] 既存テストの回帰確認（`forge test` 全件 Green）

### 7.3 ドキュメント

- [x] 本ファイルのステータス更新
- [ ] 監査報告書への正式回答

---

## 8. 参考リンク

| リソース | パス |
|----------|------|
| 初期化実装 | `src/investment/functions/initializer/Initialize.sol` |
| Admin管理実装 | `src/investment/functions/onlyOwner/ControlAdmin.sol` |
| エラー定義 | `src/investment/interfaces/IInvestmentErrors.sol` |
| イベント定義 | `src/investment/interfaces/IInvestmentEvents.sol` |

---

## 9. 変更履歴

| 日付 | 内容 |
|------|------|
| 2026-05-27 | 初版作成（監査指摘 F-2026-16865 の整理・対応方針） |
| 2026-05-27 | 実装完了: `Initialize.sol` に `usdtAddress` / `safeMultisigWallet` ゼロアドレスチェック追加、`ControlAdmin.sol` に `addAdmin` ゼロアドレスチェック追加、テストケース追加、`forge test` 全件 Green |
