// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiVault {
    mapping(address => uint256) public balances;
    address public admin;
    bool public paused;          // packed with admin in slot 1

    constructor() {
        admin = msg.sender;
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    function deposit() external payable whenNotPaused {
        balances[msg.sender] += msg.value;
    }

    function batchDeposit(bytes[] calldata calls) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, ) = address(this).delegatecall(calls[i]);
            require(success, "Batch call failed");
        }
    }

    function withdraw(uint256 amount) external whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        balances[msg.sender] -= amount;
    }

    function setAdmin(address newAdmin) external {
        require(msg.sender == admin, "Not admin");
        assembly {
            sstore(1, newAdmin)
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function onlyEOA() external whenNotPaused {
        require(!isContract(msg.sender), "No contracts");
        balances[msg.sender] += 1 ether;
    }

    receive() external payable {}
}
