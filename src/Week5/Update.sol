// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Update {

  function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
      uint32 blockTimestamp = uint32(block.timestamp % 2**32);
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      
      if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
          price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
          price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
      }
      
      reserve0 = uint112(balance0);
      reserve1 = uint112(balance1);
      blockTimestampLast = blockTimestamp;
  }

}
