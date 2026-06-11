# Getter

## getProduct
```mermaid
sequenceDiagram
  actor Viewer
  participant Investment
  Viewer->>Investment: getProduct(_productId)
  activate Investment
  Investment->>Investment: productInfo = ProductsState.product[_productId]
  alt productInfo.productId == 0
    Investment-->>Viewer: revert("Product does not exist")
  else
    Investment -->> Viewer: return productInfo
  end
  deactivate Investment
```

## getAllProducts
```mermaid
sequenceDiagram
  actor Viewer
  participant Investment
  Viewer->>Investment: getAllProducts()
  activate Investment
  Investment->>Investment: productCount = productIdKeys.length
  loop productCount
    Investment->>Investment: productId = productIdKeys[i]
    Investment->>Investment: Product p = ProductsState.products[productId]
    Investment->>Investment: productInfo.push(p)
  end
  Investment -->> Viewer: return productsInfo
  deactivate Investment
```

## getAdminList
```mermaid
sequenceDiagram
  actor Viewer
  participant Investment
  Viewer->>Investment: getAdminList()
  activate Investment
  Investment->>Investment: adminList = WhiteListsState.admins
  Investment -->> Viewer: return adminList
  deactivate Investment
```

## getAllowedByTierAddress
```mermaid
sequenceDiagram
  actor Viewer
  participant Investment
  Viewer->>Investment: getAllowedByTierAddress(tier)
  activate Investment
  Investment->>Investment: allowedAddresses = TierRegistryState.allowedByTierAddress[tier]
  Investment -->> Viewer: return allowedAddresses
  deactivate Investment
```

## getAllowedByTierId
```mermaid
sequenceDiagram
  actor Viewer
  participant Investment
  Viewer->>Investment: getAllowedByTierId(tier, sbt)
  activate Investment
  Investment->>Investment: ids = TierRegistryState.allowedByTierId[tier][sbt]
  Investment -->> Viewer: return ids
  deactivate Investment
```

## getDistributionDates
```mermaid
sequenceDiagram
  actor Viewer
  participant Investment
  Viewer->>Investment: getDistributionDates(productId)
  activate Investment
  Investment->>Investment: product = ProductsState.products[productId]
  alt product.productId == 0
    Investment-->>Viewer: revert (ProductNotFound)
  else
    Investment->>Investment: n = product.totalDistributionCount
    alt n == 0
      Investment-->>Viewer: return []
    else
      loop k in [0..n-1]
        Investment->>Investment: dates[k] = DistributionDateLib.calculateNextDistributionDate(distributionStartDate, distributionInterval, k, isMonthEnd)
      end
      Investment-->>Viewer: return dates
    end
  end
  deactivate Investment
```

## simulatePeriodYield
```mermaid
sequenceDiagram
  actor Viewer
  participant Investment
  participant NFT

  Viewer->>Investment: simulatePeriodYield(productId)
  activate Investment
  Investment->>Investment: product = ProductsState.products[productId]
  Investment->>Investment: n = product.totalDistributionCount
  alt n == 0
    Investment-->>Viewer: return []
  else
    Investment->>NFT: tokenIdCounter()
    NFT-->>Investment: nftCount
    Investment->>Investment: tolerance = CalculateYieldLib.calculatePeriodTolerance(nftCount)
    Investment->>Investment: firstPeriod = DistributionDateLib.calculateFirstDistributionPeriod(distributionStartDate, operationStartDate)
    Investment->>Investment: yields[0] = CalculateYieldLib.calculatePeriodYield(raisedAmount, expectedYield, firstPeriod) + tolerance
    loop i in [1..n-1]
      Investment->>Investment: period = DistributionDateLib.calculateDistributionPeriod(distributionStartDate, distributionInterval, i, isMonthEnd)
      Investment->>Investment: yields[i] = CalculateYieldLib.calculatePeriodYield(raisedAmount, expectedYield, period) + tolerance
    end
    Investment-->>Viewer: return yields
  end
  deactivate Investment
```

## simulateTotalYield
```mermaid
sequenceDiagram
  actor Viewer
  participant Investment
  participant NFT

  Viewer->>Investment: simulateTotalYield(productId)
  activate Investment
  Investment->>Investment: product = ProductsState.products[productId]
  Investment->>Investment: totalDistributionCount = product.totalDistributionCount
  Investment->>NFT: tokenIdCounter()
  NFT-->>Investment: nftCount
  Investment->>Investment: tolerance = CalculateYieldLib.calculateTotalTolerance(nftCount, totalDistributionCount)
  Investment->>Investment: firstPeriod = DistributionDateLib.calculateFirstDistributionPeriod(distributionStartDate, operationStartDate)
  Investment->>Investment: totalYield = CalculateYieldLib.calculatePeriodYield(raisedAmount, expectedYield, firstPeriod)
  loop i in [1..totalDistributionCount-1]
    Investment->>Investment: period = DistributionDateLib.calculateDistributionPeriod(distributionStartDate, distributionInterval, i, isMonthEnd)
    Investment->>Investment: totalYield += CalculateYieldLib.calculatePeriodYield(raisedAmount, expectedYield, period)
  end
  Investment-->>Viewer: return totalYield + tolerance
  deactivate Investment
```

## simulateIndividualPeriodYield
```mermaid
sequenceDiagram
  actor Viewer
  participant Investment
  participant NFT

  Viewer->>Investment: simulateIndividualPeriodYield(productId, tokenId)
  activate Investment
  Investment->>Investment: product = ProductsState.products[productId]
  alt product.productId == 0
    Investment-->>Viewer: revert (ProductNotFound)
  else
    Investment->>Investment: n = product.totalDistributionCount
    alt n == 0
      Investment-->>Viewer: return []
    else
      Investment->>NFT: getInvestmentAmount(tokenId)
      NFT-->>Investment: investmentAmount
      Investment->>Investment: firstPeriod = DistributionDateLib.calculateFirstDistributionPeriod(distributionStartDate, operationStartDate)
      Investment->>Investment: py0 = CalculateYieldLib.calculatePeriodYield(raisedAmount, expectedYield, firstPeriod)
      Investment->>Investment: yields[0] = CalculateYieldLib.calculateIndividualPeriodYield(py0, investmentAmount, raisedAmount)
      loop i in [1..n-1]
        Investment->>Investment: period = DistributionDateLib.calculateDistributionPeriod(distributionStartDate, distributionInterval, i, isMonthEnd)
        Investment->>Investment: py = CalculateYieldLib.calculatePeriodYield(raisedAmount, expectedYield, period)
        Investment->>Investment: yields[i] = CalculateYieldLib.calculateIndividualPeriodYield(py, investmentAmount, raisedAmount)
      end
      Investment-->>Viewer: return yields
    end
  end
  deactivate Investment
```

## simulateIndividualTotalYield
```mermaid
sequenceDiagram
  actor Viewer
  participant Investment

  Viewer->>Investment: simulateIndividualTotalYield(productId, tokenId)
  activate Investment
  Investment->>Investment: yields = _simulateIndividualPeriodYields(productId, tokenId)
  Investment->>Investment: totalYield = sum(yields)
  Investment-->>Viewer: return totalYield
  deactivate Investment
```
