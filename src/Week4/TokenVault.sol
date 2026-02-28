// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVault {
    mapping(address => mapping(address => uint256)) public deposits;
    // token => total deposited
    mapping(address => uint256) public totalDeposited;
    address public trustedForwarder;

    constructor(address _forwarder) {
        trustedForwarder = _forwarder;
    }

    function _msgSender() internal view returns (address sender) {
        if (msg.sender == trustedForwarder) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = msg.sender;
        }
    }

    function deposit(address token, uint256 amount) external {
        IERC20(token).transferFrom(_msgSender(), address(this), amount);
        deposits[token][_msgSender()] += amount;
        totalDeposited[token] += amount;
    }

    function withdraw(address token, uint256 amount) external {
        address sender = _msgSender();
        require(deposits[token][sender] >= amount, "Insufficient");
        deposits[token][sender] -= amount;
        totalDeposited[token] -= amount;
        IERC20(token).transfer(sender, amount);
    }

    function emergencyMigrate(address token, address newVault) external {
        address sender = _msgSender();
        uint256 userDeposit = deposits[token][sender];
        require(userDeposit > 0, "Nothing to migrate");
        deposits[token][sender] = 0;
        totalDeposited[token] -= userDeposit;
        IERC20(token).approve(newVault, userDeposit);
        // Assumes newVault will pull the tokens
    }

    function batchDeposit(address[] calldata tokens, uint256[] calldata amounts) external {
        require(tokens.length == amounts.length, "Length mismatch");
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).transferFrom(msg.sender, address(this), amounts[i]);
            deposits[tokens[i]][msg.sender] += amounts[i];
            totalDeposited[tokens[i]] += amounts[i];
        }
    }
}