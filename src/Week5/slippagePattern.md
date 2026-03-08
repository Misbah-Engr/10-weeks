## BAD: no slippage protection

```solidity
router.swapExactTokensForTokens(amount, 0, path, address(this), deadline);
```

## GOOD: slippage protection from oracle

```solidity
uint256 expectedOut = oracle.getPrice(tokenIn) * amount / oracle.getPrice(tokenOut);
uint256 minOut = expectedOut * 99 / 100; // 1% tolerance
router.swapExactTokensForTokens(amount, minOut, path, address(this), deadline);
```
