# Ethereum Improvement Proposals  Lecture Outline

**Week 3, Day 2 Continued**
**Duration: 2 Hours**


---

## PROTOCOL-LEVEL EIPs AND THEIR SECURITY

### Part 1: What is an EIP and Why Should You Care?
- EIP categories: Core (protocol changes), ERC (application standards), Informational/Meta
- Three reasons EIPs matter for security researchers:
  1. Gas cost changes break contracts with hardcoded assumptions
  2. New opcodes create new attack vectors
  3. ERC standards define "expected behavior"  deviations are vulnerabilities

### Part 2: The Gas EIPs: When the Rules Change Under Your Feet
- **EIP-2929** (Berlin)  Cold/warm access costs: SLOAD 800→2100, account access 700→2600
  - Broke .transfer()/.send() (2300 gas stipend insufficient for cold storage access)
  - Audit pattern: flag all hardcoded gas limits
- **EIP-2930** (Berlin)  Optional access lists (type 1 transactions)
  - Pre-declare storage/account access for warm pricing
  - Security: access lists leak MEV-relevant information
- **EIP-1559** (London)  Base fee + priority fee structure
  - block.basefee opcode as manipulable value in economic logic
  - tx.gasprice behavior change (effective gas price)
  - MEV connection through priority fees
- **EIP-3529** (London)  Reduced gas refunds (15000→4800 for storage clearing)
  - Killed gas token economics
  - Broke protocols relying on old refund math
- **EIP-3198** (London)  BASEFEE opcode
  - On-chain gas price oracles, manipulable dependency

### Part 3: The Opcode EIPs  New Capabilities, New Attack Vectors
- **EIP-1153** (Cancun)  Transient storage: TSTORE/TLOAD
  - Persists across calls within a transaction, clears between transactions
  - New bug class: transient storage assumption violations (per-call vs per-transaction)
  - Audit pattern: "What happens if this function is called twice in one tx?"
- **EIP-6780** (Cancun)  SELFDESTRUCT limited to creation transaction
  - Kills CREATE2 redeploy attack on mainnet
  - Still sends ETH, just doesn't delete code/storage
  - Chain-specific: not all chains adopted Cancun
- **EIP-3855** (Shanghai)  PUSH0 instruction
  - Minimal security impact, bytecode verification awareness
- **EIP-5656** (Cancun)  MCOPY instruction
  - Overlapping memory copy edge cases
- **EIP-4844** (Cancun)  Blob transactions
  - Blob data NOT accessible from EVM (only BLOBHASH and BLOBBASEFEE opcodes)
  - Separate blob fee market, independently manipulable
  - Blob pruning window: data availability is time-bounded

### Part 4: The Proxy and Account EIPs
- **EIP-1967**  Standard proxy storage slots
  - Deterministic slot computation via keccak256 hash - 1
  - Audit pattern: verify proxy reads/writes correct EIP-1967 slots
- **EIP-7702** (Pectra)  EOA code delegation
  - Blurs EOA/contract distinction: extcodesize non-zero for delegated EOAs
  - Breaks patterns that assume "EOA = simple caller"
- **EIP-4337**  Account abstraction via alternative mempool
  - New trust assumptions: bundler, EntryPoint, paymaster, account contract
  - Signature validation in account contract as attack surface

---

**5-minute break**

---

## HOUR 2  ERC STANDARDS AND HOW THEY BREAK

### Part 5: ERC-20  The Standard Everyone Claims to Follow
- Seven deviations that create vulnerabilities:
  1. Missing return values (USDT)  need SafeERC20
  2. Fee-on-transfer  actual balance < credited amount
  3. Rebasing tokens (stETH, AMPL)  balance changes without transfers
  4. Blacklist tokens (USDC, USDT)  frozen addresses break integrations
  5. Transfer limits / per-block restrictions
  6. Pausable tokens  liquidation mechanisms break during pause
  7. Approval race condition  frontrun approve to double-spend allowance

### Part 6: ERC-2612  Permit
- Off-chain signature for gasless approvals
- Attack 1: Permit front-running grief  front-run permit, user's tx reverts
  - Fix: try/catch around permit, fallback to existing allowance
- Attack 2: Permit phishing  trick user into signing approval for attacker
- Attack 3: Signature replay across chains  domain separator must include chainid
  - Audit pattern: cached vs recomputed domain separator on fork

### Part 7: ERC-721 and ERC-1155  NFTs and the Callback Problem
- safeTransferFrom mandatory callbacks: onERC721Received / onERC1155Received
- Reentrancy via safe transfer callbacks (same CEI pattern as ETH reentrancy)
- ERC-1155 batch transfer callback variations (per-item vs batch)
- setApprovalForAll as overly broad permission  audit flag
- transferFrom vs safeTransferFrom tradeoff: no callback vs reentrancy risk

### Part 8: ERC-4626 and ERC-2771
- **ERC-4626**  Tokenized vault inflation attack
  - First depositor donates to inflate share price, victim gets 0 shares
  - Mitigations: virtual offsets, dead shares, minimum deposit
- **ERC-2771**  Meta-transactions and trusted forwarder
  - Sender address appended to calldata, read on trusted forwarder check
  - Critical interaction: ERC-2771 + Multicall = sender spoofing
  - Audit pattern: verify trusted forwarder check, check for batch-call interactions

### Part 9: Exercise: Spot the EIP/ERC Bugs

## Homework
1. Read 3 full EIPs (one gas, one opcode, one ERC)  write one-paragraph security summary each, post on X
2. Search Solodit for "ERC-20" / "fee-on-transfer" / "rebasing" findings  read 3 real audit findings, summarize in group
