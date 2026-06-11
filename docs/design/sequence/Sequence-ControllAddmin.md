# ControllAdmin

## initialize（デプロイ時・1回のみ）

`InvestmentDeployer.deployInvestment` 経由でプロキシに対して呼び出される。

```mermaid
sequenceDiagram
  actor deployer as Deployer
  participant Investment
  deployer->>Investment: initialize(admins, usdtAddress, safeMultisigWallet)
  activate Investment
  loop each admins[i]
    Investment-->>Investment: admins[i] != address(0)?
    break InvalidAddress
      Investment-->>deployer: revert
    end
    Investment-->>Investment: duplicate in admins[0..i-1]?
    break AlreadyExistsAdmin
      Investment-->>deployer: revert
    end
    Investment->>Investment: admins.push(admins[i])
    Investment-->>Investment: emit AdminAdded
  end
  Investment-->>Investment: usdtAddress / safeMultisigWallet != 0?
  break InvalidAddress
    Investment-->>deployer: revert
  end
  Investment-->>deployer: success
  deactivate Investment
```

## addAdmin
onlyOwner(Safe Multisig Wallet only)
- admin数は最大255に制限（`MAX_ADMINS = 255`）
```mermaid
sequenceDiagram
  actor smw as SafeMultisigWallet
  participant Investment
  smw->>Investment: addAdmin(_admin)
  activate Investment
  Investment-->>Investment: _checkOwner()
  break OwnableUnauthorizedAccount
      Investment-->>smw: revert
  end
  Investment-->>Investment: validate _admin != address(0)
  break InvalidAddress
      Investment-->>smw: revert
  end
  Investment-->>Investment: admins.length >= MAX_ADMINS?
  break AdminLimitReached
      Investment-->>smw: revert
  end
  Investment-->>Investment: duplicate check
  break AlreadyExistsAdmin
      Investment-->>smw: revert
  end
  Investment->>Investment: admins.push(_admin)
  Investment-->>smw: success
  deactivate Investment
```

## deleteAdmin
onlyOwner(Safe Multisig Wallet only)
```mermaid
sequenceDiagram
  actor smw as SafeMultisigWallet
  participant Investment
  smw->>Investment: deleteAdmin(_admin)
  activate Investment
  Investment-->>Investment: _checkOwner()
  break OwnableUnauthorizedAccount
      Investment-->>smw: revert
  end
  Investment->>Investment: _removeAdmin(_admin)
  Investment-->>smw: success
  deactivate Investment
```
