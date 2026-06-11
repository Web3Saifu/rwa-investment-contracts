# Investment Contract

## SetProductRequiredTier

登録済み商品の `requiredTier` を管理者が更新する（F-2026-16955 追補 API）。満期済み（`isMaturity == true`）商品も更新可能。`invest` / `mintNFT` は従来どおり満期時に `MaturedProduct` で拒否される。

```mermaid
sequenceDiagram
    actor admin
    participant setTier as SetTier
    participant products as ProductsState
    participant registry as TierRegistryState

    note over admin: productId, requiredTier (0 = none)
    admin ->> setTier: setProductRequiredTier(productId, requiredTier)
    setTier ->> products: load products[productId]
    products -->> setTier: return
    break productId == 0 (product not found)
        setTier -->> admin: revert ProductNotFound
    end
    break requiredTier != 0 and allowedByTierAddress[requiredTier] is empty
        setTier ->> registry: allowedByTierAddress[requiredTier]
        registry -->> setTier: return empty
        setTier -->> admin: revert TierNotConfigured
    end
    break previousRequiredTier == requiredTier
        setTier -->> admin: success (no event)
    end
    setTier ->> products: products[productId].requiredTier = requiredTier
    setTier ->> setTier: emit ProductRequiredTierUpdated(productId, previous, new)
    setTier -->> admin: success
```

### 関連

| 項目 | 内容 |
|------|------|
| 実装 | `src/investment/functions/onlyWhiteLists/SetTier.sol` |
| イベント | `ProductRequiredTierUpdated`（`IInvestmentEvents.sol`） |
| 登録時検証 | `Sequence-RegisterProduct.md`（CREATE2 前の `TierNotConfigured`） |
| 監査 | `docs/audit/fix/F-2026-16955-missing-tier-registry-validation-register-product.md` §11 |
