// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Burn {

  function burn(address to) external lock returns (uint amount0, uint amount1) {
      uint balance0 = IERC20(token0).balanceOf(address(this));
      uint balance1 = IERC20(token1).balanceOf(address(this));
      uint liquidity = balanceOf[address(this)]; // LP tokens sent to pair
  
      amount0 = liquidity * balance0 / totalSupply;
      amount1 = liquidity * balance1 / totalSupply;
      require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
      
      _burn(address(this), liquidity);
      _safeTransfer(token0, to, amount0);
      _safeTransfer(token1, to, amount1);
      _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), _reserve0, _reserve1);
  }

}
