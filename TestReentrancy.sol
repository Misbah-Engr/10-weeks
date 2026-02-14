// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {victimContract, attacker} from "../src/Week2.sol";
import "forge-std/console.sol";

contract TestReentrancy is Test {
    victimContract public victimC;
    attacker public attackerContract;
    address user2 = makeAddr("user2");

    function setUp() public {
        victimC = new victimContract();
        attackerContract = new attacker();
        vm.deal(address(victimC), 10 ether);
        vm.deal(address(user2), 10 ether);
        vm.deal(address(attackerContract), 10 ether);
        attackerContract.setVictimAddress(address(victimC));
    }

    function testReentrancy() public {
        vm.startPrank(user2);
        victimC.deposit{value: 10 ether}();
        vm.stopPrank();

        vm.startPrank(address(attackerContract));
        attackerContract.deposit{value: 1 ether}(address(victimC));
        attackerContract.withdraw(address(victimC));
        vm.stopPrank();
        assertEq(address(victimC).balance, 0);
        console.log(address(attackerContract).balance);
    }
}
