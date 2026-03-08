// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract VulnerableVault {
    IUniswapV2Pair public pair;
    
    // Calculates LP token value based on reserve ratio
    function getLPTokenPrice() public view returns (uint256) {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        // Price = (r0 * priceToken0 + r1 * priceToken1) / totalSupply
        return (uint256(r0) * getExternalPrice(token0) + uint256(r1) * getExternalPrice(token1)) / totalSupply;
    }
    
    function deposit(uint256 lpAmount) external {
        uint256 value = lpAmount * getLPTokenPrice() / 1e18;
        // Credit user with `value` amount of borrowing power
        borrowingPower[msg.sender] += value;
        lpToken.transferFrom(msg.sender, address(this), lpAmount);
    }
}
