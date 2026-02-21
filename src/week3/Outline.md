# Ethereum Virtual Machine

**Week 3, Day 1**
**Duration: 2 Hours**
**Reference: Ethereum Protocol Fellowship (external, not lecture material)**

---

## HOUR 1 - THE MACHINE
### Part 1: What is the EVM, Really? (0:00 – 0:15)
- Deterministic re-execution across all nodes, that's consensus
- Stack-based, quasi-Turing-complete, gas-bounded
- The four data locations: Stack, Memory, Storage, Calldata
- Cost differences across data locations and why they matter for security
- Where contract bytecode lives and why contracts are immutable

### Part 2: Opcodes and Bytecode
- Opcode categories that matter for auditors:
  - Arithmetic: ADD, SUB, MUL, DIV — unsigned 256-bit wrapping behavior, `unchecked` blocks as audit flags
  - Stack: PUSH, POP, DUP, SWAP — the plumbing
  - Memory: MLOAD, MSTORE - quadratic memory expansion cost
  - Storage: SLOAD, SSTORE - the most vulnerability-dense opcodes (gas costs: 20k write fresh, 5k modify, 2.1k cold read)
- The four CALL opcodes:
  - CALL - standard external call, new context
  - STATICCALL - read-only, reverts on state modification
  - DELEGATECALL - caller's context, target's code (proxy pattern backbone)
  - CALLCODE - deprecated, flag in audits
- Bytecode-level view of Checks-Effects-Interactions: SSTORE before CALL

### Part 3: Execution Context and Transaction Lifecycle
- Step-by-step: mempool → validator ordering → execution context → selector dispatch → execution → commit/revert
- msg.sender vs tx.origin at the EVM level, DELEGATECALL twist
- Function selector resolution: first 4 bytes of keccak256, compiler-generated dispatcher, selector collisions in proxies
- Atomicity: all-or-nothing state transitions, revert as a weapon (DoS via reverting recipient)

### Part 4: Gas - The Hidden Security Surface
- 63/64 rule and gas starvation in nested calls
- EIP-2929 cold access cost increases, why .transfer()/.send() broke
- Gas griefing attacks

---

**5-minute break**

---

## HOUR 2 - SECURITY IMPLICATIONS 

### Part 5: Storage Layout Deep Dive for Auditors
- Sequential slot assignment, variable packing rules
- How the EVM reads packed variables: SLOAD → AND → SHIFT
- Mapping slot computation: keccak256(abi.encode(key, slot))
- Dynamic array layout: length at declared slot, elements at keccak256(slot)
- Three security consequences:
  1. Proxy storage collisions and EIP-1967
  2. Uninitialized storage pointers (pre-0.5 Solidity)
  3. Raw assembly sstore wiping packed variables

### Part 6: Contract Creation at the EVM Level
- Creation bytecode vs runtime bytecode - constructor runs once, RETURN value becomes permanent code
- CREATE vs CREATE2 address derivation
- CREATE2 redeploy attack: SELFDESTRUCT + redeploy with different code at same address
- Dencun mitigation on Ethereum mainnet, still live on other chains

### Part 7: EVM-Level Patterns That Create Real Vulnerabilities
- Pattern 1: Returnbomb - malicious contract returns massive data, quadratic memory cost griefs caller
- Pattern 2: msg.value reuse in DELEGATECALL loops - CALLVALUE opcode doesn't change across delegatecalls
- Pattern 3: EXTCODESIZE bypass during construction - returns 0 in constructor
- Pattern 4: Phantom functions and fallback abuse - silent success on non-existent function selectors

### Part 8: Exercise - Spot the EVM-Level Bugs
- Drop MultiVault contract in Telegram (5 planted bugs, 10 minutes)
- Walkthrough:
  1. msg.value reuse in batchDeposit via delegatecall (Critical)
  2. Reentrancy in withdraw - CALL before SSTORE (Critical)
  3. setAdmin assembly sstore wipes packed `paused` flag (High)
  4. extcodesize bypass in onlyEOA during construction (Medium)
  5. batchDeposit + Bug 1 enables full vault drain (Critical)

---

## Homework
1. Complete 5+ EVM Puzzles by Franco Victorio - post solutions on X
2. Read Ethereum Protocol Fellowship EVM section - drop any security-relevant findings in the group