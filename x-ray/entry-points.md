# Entry Point Map

## Protocol Flow Paths

```text
initialize
  -> initialize(admins, minters, USDT, Safe)
  -> role arrays + config storage

admin product setup
  -> setAllowedByTierAddress / setAllowedByTierId (optional)
  -> registerProduct
  -> CREATE2 InvestmentNFT
  -> products + productIdKeys + activeProductIdKeys

USDT subscription
  -> invest
  -> tier check + USDT balance/allowance
  -> raisedAmount/productPool += amount
  -> USDT transferFrom
  -> InvestmentNFT.mint

JPY/off-chain subscription
  -> deposit (admin funds productPool)
  -> mintNFT (minter credits investor NFT)

scheduled yield
  -> Automation.checkUpkeep
  -> performUpkeep by forwarder
  -> distributeYield
  -> InvestmentNFT.getNFTInfos batch
  -> USDT push or tokenId escrow

maturity
  -> maturity
  -> InvestmentNFT.getNFTInfos batch
  -> USDT principal push or tokenId escrow
  -> burn on successful push
  -> remove active product when final batch completes

escrow recovery
  -> current NFT owner calls claimYield / claimPrincipal
  -> USDT push
  -> clear escrow
  -> claimPrincipal burns NFT after principal succeeds
```

---

## Permissionless

### `Invest.invest(uint256 productId, uint256 unitCount)`

| Aspect | Detail |
|--------|--------|
| Visibility | external, nonReentrant |
| Caller | Investor |
| Parameters | `productId` (user-controlled), `unitCount` (user-controlled) |
| Call chain | `Invest.invest()` -> `PurchasePermissionLib.hasPurchasePermission()` -> `IERC20.safeTransferFrom()` -> `InvestmentNFT.mint()` |
| State modified | `product.raisedAmount`, `product.productPool`, NFT `tokenIdCounter`, NFT `_investmentAmounts` |
| Value flow | USDT: investor -> Investment proxy; NFT: InvestmentNFT -> investor |
| Reentrancy guard | yes |

### `Claim.claimYield(uint256 productId, uint256 tokenId, uint256 distributionIndex)`

| Aspect | Detail |
|--------|--------|
| Visibility | external, nonReentrant |
| Caller | Current NFT owner |
| Parameters | `productId` (user-controlled), `tokenId` (user-controlled), `distributionIndex` (user-controlled) |
| Call chain | `Claim.claimYield()` -> `InvestmentNFT.getInvestmentAmount()` / `IERC721.ownerOf()` -> `UsdtTransferLib.tryTransfer()` |
| State modified | `escrow.unclaimedYield[productId][tokenId][distributionIndex]` |
| Value flow | USDT: Investment proxy -> current NFT owner |
| Reentrancy guard | yes |

### `Claim.claimPrincipal(uint256 productId, uint256 tokenId)`

| Aspect | Detail |
|--------|--------|
| Visibility | external, nonReentrant |
| Caller | Current NFT owner |
| Parameters | `productId` (user-controlled), `tokenId` (user-controlled) |
| Call chain | `Claim.claimPrincipal()` -> `InvestmentNFT.getInvestmentAmount()` / `IERC721.ownerOf()` -> `UsdtTransferLib.tryTransfer()` -> `InvestmentNFT.burn()` |
| State modified | `escrow.unclaimedPrincipal`, related `escrow.unclaimedYield` slots, NFT burn state |
| Value flow | USDT: Investment proxy -> current NFT owner; NFT burned |
| Reentrancy guard | yes |

### `Automation.performUpkeep(bytes performData)`

| Aspect | Detail |
|--------|--------|
| Visibility | external |
| Caller | Configured Chainlink forwarder only; no modifier but internal `msg.sender` check |
| Parameters | `performData` (keeper/forwarder-provided) |
| Call chain | `Automation.performUpkeep()` -> `IInvestment.distributeYield()` or `IInvestment.maturity()` |
| State modified | none in Automation; downstream Investment state changes |
| Value flow | none directly; downstream may transfer USDT |
| Reentrancy guard | no |

---

## Role-Gated

### Whitelisted Admins

#### `RegisterProduct.registerProduct(Schema.RegisterProductArgs args)`

| Aspect | Detail |
|--------|--------|
| Visibility | external, onlyWhiteLists |
| Caller | Admin / operations |
| Parameters | Product schedule, cap, tier, metadata (admin-controlled) |
| Call chain | `RegisterProduct.registerProduct()` -> `DistributionDateLib` -> `Create2.deploy(InvestmentNFT)` |
| State modified | `products`, `productIdKeys`, `activeProductIdKeys`, `activeIndex` |
| Value flow | none |
| Reentrancy guard | no |

#### `Deposit.deposit(uint256 productId, uint256 depositAmount)`

| Aspect | Detail |
|--------|--------|
| Visibility | external, nonReentrant, onlyWhiteLists |
| Caller | Admin / operations |
| Parameters | `productId`, `depositAmount` (admin-controlled) |
| Call chain | `Deposit.deposit()` -> `IERC20.safeTransferFrom()` |
| State modified | `product.productPool`, `product.isInsufficientBalance` |
| Value flow | USDT: admin -> Investment proxy |
| Reentrancy guard | yes |

#### `Withdraw.withdraw(uint256 productId, uint256 withdrawAmount)`

| Aspect | Detail |
|--------|--------|
| Visibility | external, nonReentrant, onlyWhiteLists |
| Caller | Admin / operations |
| Parameters | `productId`, `withdrawAmount` (admin-controlled) |
| Call chain | `Withdraw.withdraw()` -> `IERC20.safeTransfer(SAFE_MULTISIG_WALLET)` |
| State modified | `product.productPool` |
| Value flow | USDT: Investment proxy -> Safe multisig wallet |
| Reentrancy guard | yes |

#### `DistributeYield.distributeYield(uint256 productId)`

| Aspect | Detail |
|--------|--------|
| Visibility | external, nonReentrant, onlyWhiteLists |
| Caller | Admin or Automation contract if whitelisted |
| Parameters | `productId` (admin/automation-provided) |
| Call chain | `DistributeYield.distributeYield()` -> `InvestmentNFT.getNFTInfos()` -> `UsdtTransferLib.tryTransfer()` |
| State modified | `distributedCount`, `distributedTokenId`, `distributedYieldPerCount`, `productPool`, `isInsufficientBalance`, `escrow.unclaimedYield` |
| Value flow | USDT: Investment proxy -> NFT owners or escrow |
| Reentrancy guard | yes |

#### `Maturity.maturity(uint256 productId)`

| Aspect | Detail |
|--------|--------|
| Visibility | external, nonReentrant, onlyWhiteLists |
| Caller | Admin or Automation contract if whitelisted |
| Parameters | `productId` (admin/automation-provided) |
| Call chain | `Maturity.maturity()` -> `InvestmentNFT.getNFTInfos()` -> `UsdtTransferLib.tryTransfer()` -> `InvestmentNFT.burn()` |
| State modified | `isMaturity`, `maturedTokenId`, `totalReturnedAmount`, `productPool`, `escrow.unclaimedPrincipal`, `activeProductIdKeys`, `activeIndex` |
| Value flow | USDT: Investment proxy -> NFT owners or escrow; NFT burn on successful push |
| Reentrancy guard | yes |

#### `SetTier.setAllowedByTierAddress(uint8 tier, address[] sbts)`

| Aspect | Detail |
|--------|--------|
| Visibility | external, onlyWhiteLists |
| Caller | Admin / operations |
| Parameters | tier registry entries (admin-controlled) |
| Call chain | `SetTier.setAllowedByTierAddress()` |
| State modified | `allowedByTierAddress`, deleted `allowedByTierId` for removed SBTs |
| Value flow | none |
| Reentrancy guard | no |

#### `SetTier.setAllowedByTierId(uint8 tier, address sbt, uint256[] ids)`

| Aspect | Detail |
|--------|--------|
| Visibility | external, onlyWhiteLists |
| Caller | Admin / operations |
| Parameters | ERC1155 token IDs (admin-controlled) |
| Call chain | `SetTier.setAllowedByTierId()` -> `IERC165.supportsInterface()` |
| State modified | `allowedByTierId[tier][sbt]` |
| Value flow | none |
| Reentrancy guard | no |

#### `SetTier.setProductRequiredTier(uint256 productId, uint8 requiredTier)`

| Aspect | Detail |
|--------|--------|
| Visibility | external, onlyWhiteLists |
| Caller | Admin / operations |
| Parameters | product/tier (admin-controlled) |
| Call chain | `SetTier.setProductRequiredTier()` |
| State modified | `product.requiredTier` |
| Value flow | none |
| Reentrancy guard | no |

#### `InvestmentNFT.setURI(string newBaseTokenURI)`

| Aspect | Detail |
|--------|--------|
| Visibility | external; internal admin-list check through Investment contract |
| Caller | Investment admin |
| Parameters | metadata URI (admin-controlled) |
| Call chain | `InvestmentNFT.setURI()` -> `IInvestment.getAdminList()` |
| State modified | NFT `baseTokenURI` |
| Value flow | none |
| Reentrancy guard | no |

### Minters

#### `MintNFT.mintNFT(uint256 productId, uint256 unitCount, address investor)`

| Aspect | Detail |
|--------|--------|
| Visibility | external, nonReentrant, onlyMinters |
| Caller | Configured minter |
| Parameters | product, units, investor (minter-provided after off-chain settlement) |
| Call chain | `MintNFT.mintNFT()` -> `InvestmentNFT.mint()` |
| State modified | `product.raisedAmount`, NFT `tokenIdCounter`, NFT `_investmentAmounts` |
| Value flow | NFT: InvestmentNFT -> investor; no ERC20 transfer |
| Reentrancy guard | yes |

---

## Admin-Only

| Contract | Function | Parameters | State Modified |
|----------|----------|------------|----------------|
| `Initialize` | `initialize` | admins, minters, USDT, Safe | role arrays, config addresses |
| `ControlAdmin` | `addAdmin` | admin address | `WhiteListsState.admins` |
| `ControlAdmin` | `deleteAdmin` | admin address | `WhiteListsState.admins` |
| `ControlMinter` | `addMinter` | minter address | `MintersState.minters` |
| `ControlMinter` | `deleteMinter` | minter address | `MintersState.minters` |
| `InvestmentNFT` | `mint` | recipient, amount | token ownership, `_investmentAmounts`, `tokenIdCounter` |
| `InvestmentNFT` | `burn` | tokenId | token ownership, `_investmentAmounts` |

---

## View / Read Surface

Getter functions are public/external view and include product lists, active product lists, admin list, tier registry reads, simulated yields, distribution dates, unclaimed balances, and token claimable status. They do not directly move value but are important for Automation and frontend/off-chain accounting.

