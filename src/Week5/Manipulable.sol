// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Manipulable {
  // Lending protocol determines collateral value from Uniswap spot price
  function getPrice(address token) public view returns (uint256) {
      (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
      return uint256(reserve1) * 1e18 / uint256(reserve0);
  }

}
