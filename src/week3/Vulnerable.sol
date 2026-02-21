contract Vulnerable {
    address public owner;         // Slot 0
    bool public status;             // slot 0
    uint256 public totalDeposits; // Slot 1

    function updateOwner(address newOwner) external {
        assembly {
            sstore(0x00, newOwner)
        }
    }
}
