# Investment NFT

## mint
onlyOwner
```mermaid
sequenceDiagram
  participant Investment
  participant NFT

  Investment->>NFT: mint(to, amount)
  activate NFT
  NFT->>NFT: onlyOwner check
  break OwnableUnauthorizedAccount
    NFT-->>Investment: revert
  end
  break ZeroAmount (amount <= 0)
    NFT-->>Investment: revert
  end
  NFT->>NFT: tokenIdCounter++
  NFT->>NFT: _safeMint(to, tokenIdCounter)
  break Mint Fail
    NFT -->> Investment: revert
  end
  NFT->>NFT: _investmentAmounts[tokenId] = amount
  NFT-->>Investment: return tokenId
  deactivate NFT
```

## burn
onlyOwner
```mermaid
sequenceDiagram
  participant Investment
  participant NFT

  Investment->>NFT: burn(tokenId)
  activate NFT
  NFT->>NFT: onlyOwner check
  break OwnableUnauthorizedAccount
      NFT-->>Investment: revert
  end
  NFT->>NFT: owner = ownerOf(tokenId)
  NFT->>NFT: _burn(tokenId)
  NFT->>NFT: emit NFTBurned
  NFT->>NFT: delete _investmentAmounts[tokenId]
  NFT-->>Investment: end
  deactivate NFT
```

## getNFTInfos
```mermaid
sequenceDiagram
    participant Caller
    participant NFT

    Caller->>NFT: getNFTInfos(startTokenId)
    activate NFT
    NFT->>NFT: Initialize nftInfos array
    NFT->>NFT: endTokenId = return startTokenId + 49 < _tokenIdCounter ? startTokenId + 49 : _tokenIdCounter
    loop i from startTokenId to endTokenId
        NFT->>NFT: tokenId = i
        NFT->>NFT: owner = ownerOf(tokenId)
        NFT->>NFT: investmentAmount = investmentAmounts[tokenId]
        NFT->>NFT: nftInfo = {tokenId, owner, investmentAmount}
        NFT->>NFT: Add nftInfo to nftInfos array
    end
    NFT-->>Caller: return nftInfos
    deactivate NFT
```

## getInvestmentAmount

```mermaid
sequenceDiagram
    participant Caller
    participant NFT

    Caller->>NFT: getInvestmentAmount(tokenId)
    NFT->>NFT: return _investmentAmounts[tokenId]
    NFT-->>Caller: end
```

## setURI
onlyAdmin (Investment contract admin)
```mermaid
sequenceDiagram
    participant Admin
    participant NFT
    participant Investment

    Admin->>NFT: setURI(newBaseTokenURI)
    activate NFT
    NFT->>Investment: getAdminList()
    activate Investment
    Investment-->>NFT: adminList[]
    deactivate Investment
    NFT->>NFT: Iterates through adminList to check whether msg.sender is included
    break OwnableUnauthorizedAccount
        NFT-->>Admin: revert
    end
    NFT->>NFT: baseTokenURI = newBaseTokenURI
    NFT-->>Admin: end
    deactivate NFT
```

## tokenURI
All tokens share the same metadata.json (baseTokenURI)
```mermaid
sequenceDiagram
    participant Caller
    participant NFT

    Caller->>NFT: tokenURI(tokenId)
    activate NFT
    NFT->>NFT: _requireOwned(tokenId)
    break token does not exist
        NFT-->>Caller: revert
    end
    NFT-->>Caller: return baseTokenURI
    deactivate NFT
```
