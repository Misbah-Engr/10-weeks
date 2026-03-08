# Decentralized Exchanges and Uniswap Case Study Outline

**Week 4, Day 2**

2 Hrs as usual

## HOUR 1: AMM MECHANICS AND UNISWAP V2 INTERNALS

### Why AMMs Exist
- Order book failure on-chain — gas cost kills market making
- Constant product formula: x * y = k
- Price impact math with worked example
- Fee mechanics: 0.3% deducted before invariant check, k only increases

### Uniswap V2 Architecture
- Factory, CREATE2 deterministic pair deployment
- Pair — holds funds, mints LP tokens, four critical functions
- Router — user-facing, NOT privileged, safety checks live here
- Calling the pair directly bypasses router protections

### The Pair Contract, Function by Function
- `swap()` — optimistic transfer, flash swap callback, balance-based accounting, invariant check
- `mint()` — MINIMUM_LIQUIDITY lock (anti-inflation attack), Math.min on ratios, two-step deposit
- `burn()` — pro-rata withdrawal, integer division rounding, impermanent loss
- `sync()` and `skim()` — recovery mechanisms, potential manipulation vectors

### The TWAP Oracle
- Cumulative price recording per block
- TWAP calculation: difference / elapsed time
- Problem: short windows, low-liquidity pools, UQ112x112 precision loss
- Oracle manipulation is #1 DeFi attack vector by value stolen

### Flash Swaps
- Non-empty `data` triggers `uniswapV2Call` callback before invariant check
- Zero upfront capital — receive first, pay back in same tx
- Reserves are inconsistent during callback — stale reads exploit protocols

---

## HOUR 2: ATTACK SURFACE AND REAL EXPLOITS

### Sandwich Attacks and MEV
- Front-run, victim swap, back-run — worked example with numbers
- Slippage tolerance = profit ceiling for attacker
- Audit pattern: any swap with `amountOutMin = 0` is a finding
- Auto-compounders and yield strategies as common victims

### Price Oracle Manipulation
- Spot price from `getReserves()` is trivially manipulable via flash loan
- Attack pattern: flash loan → swap to distort price → exploit protocol → swap back → repay
- Real exploits: Harvest Finance ($34M), Warp Finance ($7.7M), Mango Markets ($114M)
- Audit checklist: price source, same-tx manipulation, TWAP window length, circuit breakers

### Flash Loan Attacks Through AMMs
- Category 1: Direct pool manipulation (price distortion)
- Category 2: Liquidity removal (thin pool → easy price movement)
- Category 3: Cross-pool arbitrage exploitation
- Category 4: Reentrancy through flash swap callbacks — stale reserves during callback window

### Uniswap V3 Security Implications
- Concentrated liquidity — tick-based architecture, complexity = more bugs
- JIT liquidity — MEV by LPs against other LPs
- Oracle array (65,535 observations) — more accurate but more complex integration
- Position NFTs (ERC-721) — valuation complexity for lending protocols

### Uniswap V4 Hooks — New Attack Surface
- Custom logic at swap lifecycle points (before/after swap, add/remove liquidity)
- Hook contracts are untrusted — selective reverts, reentrancy, value extraction
- Core V4 is audited; hooks are not

### Live Exercise — 6-Bug Contract
1. Zero slippage — `amountOutMin = 0` (High/Critical)
2. Spot price oracle — `getReserves()` for pricing (Critical)
3. No SafeERC20 + owner rugpull via `withdrawFees` draining all balances (Critical)
4. Unguarded flash swap trigger — anyone calls `swapWithCallback` using contract balances (High)
5. LP value stored as USD not LP amount + chained oracle manipulation (High)
6. Fee-on-transfer accounting mismatch in `batchSwap` (Medium/High)


## Homework
1. Search Solodit for "oracle manipulation" / "price manipulation" — find 3 real findings, summarize each, post on X
2. Solve one DEX-related Damn Vulnerable DeFi challenge (The Rewarder, Puppet, or Puppet V2), post solution on X
