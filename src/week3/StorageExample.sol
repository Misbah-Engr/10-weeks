contract Example {
    uint256 public a;       // Slot 0 (full 32 bytes)
    address public owner;   // Slot 1 (20 bytes, starts at byte 0)
    bool public paused;     // Slot 1 (1 byte, starts at byte 20, packed with owner)
    uint256 public b;       // Slot 2

    mapping(address => uint256) public balances;

    mapping(address => mapping(uint256 => bool)) balancesStatus;
}
