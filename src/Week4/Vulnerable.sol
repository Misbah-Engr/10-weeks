// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Vulnerable {
    // Using EIP-1153 transient storage
    bytes32 constant TEMP_SLOT = keccak256("temp");

    function processDeposit(uint256 amount) external {
        // Developer assumes this is "fresh" for each call
        uint256 existingTemp;
        assembly {
            existingTemp := tload(TEMP_SLOT)
        }
        // But if this function is called twice in one tx via multicall,
        // the second call sees the first call's value
        uint256 newTemp = existingTemp + amount;
        assembly {
            tstore(TEMP_SLOT, newTemp)
        }
    }

    function finalize() external {
        uint256 total;
        assembly {
            total := tload(TEMP_SLOT)
        }
        // Process based on accumulated total
        // This accumulation might not be intended
    }
}