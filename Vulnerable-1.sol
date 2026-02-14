// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleVault {
    mapping(address => uint256) public balances;
    address public admin;
    bool public paused;
    
    constructor() {
        admin = msg.sender;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    function deposit() external payable whenNotPaused {
        balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 amount) external whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        balances[msg.sender] -= amount;
    }
    
    function withdrawAll() external whenNotPaused {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");
        
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
        
        balances[msg.sender] = 0;
    }
    
    function setPaused(bool _paused) external {
        paused = _paused;
    }
    
    function emergencyWithdraw(address to) external {
        require(msg.sender == admin, "Not admin");
        uint256 balance = address(this).balance;
        (bool success, ) = to.call{value: balance}("");
        require(success);
    }
    
    function setAdmin(address _newAdmin) external {
        admin = _newAdmin;
    }
}