// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Mint {

function mint(address to) external lock returns (uint liquidity) {
    (uint112 _reserve0, uint112 _reserve1,) = getReserves();
    uint balance0 = IERC20(token0).balanceOf(address(this));
    uint balance1 = IERC20(token1).balanceOf(address(this));
    uint amount0 = balance0 - _reserve0;
    uint amount1 = balance1 - _reserve1;

    if (totalSupply == 0) {
        liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
        _mint(address(0), MINIMUM_LIQUIDITY); // Lock minimum liquidity forever
    } else {
        liquidity = Math.min(
            amount0 * totalSupply / _reserve0,
            amount1 * totalSupply / _reserve1
        );
    }
    
    require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');
    _mint(to, liquidity);
    _update(balance0, balance1, _reserve0, _reserve1);
}
}
