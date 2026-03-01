# ERC-20 and ERC-4626: Lecture Outline

**Week 4, Day 2**
**Duration: 2 Hours**


## HOUR 1: ERC-20: THE STANDARD THAT ISN'T STANDARD

### Part 1: The Interface, Function by Function
- `totalSupply()` — stale caching with rebasing tokens
- `balanceOf()` — balance decay tokens, cold SLOAD cost (2100 gas)
- `transfer()` — USDT missing return value, why SafeERC20 exists
  - SafeERC20 internals: low-level call + returndatasize check
  - Audit pattern: no SafeERC20 = Medium at minimum
- `approve()` — approval race condition (frontrun approve to double-spend)
  - USDT reverts on non-zero-to-non-zero approval
  - Fix: approve 0 first, or use forceApprove
- `allowance()` — infinite approval inconsistency (some decrement, some don't)
- `transferFrom()` — order of operations varies, reentrancy through ERC-777 hooks
- Events — incorrect Transfer amounts (fee vs requested), off-chain accounting breaks

### Part 2: The Weird Tokens — A Taxonomy
Nine categories to check in every audit:
1. **Fee-on-transfer** (STA, PAXG) — credit requested vs received, last-withdrawer insolvency
   - Fix: measure balanceOf before/after
2. **Rebasing** (stETH, AMPL, aTokens) — balance changes without transfers, ghost value / insolvency
   - Fix: use wrapped versions (wstETH), shares-based accounting
3. **Blacklist/freeze** (USDC, USDT) — frozen contract = all funds locked, push-based DoS
   - Fix: pull-based withdrawals
4. **Pausable** (USDC, WBTC) — liquidation failure during pause, bad debt accumulation
5. **Transfer restrictions** — max amounts, per-address caps, cooldowns (common in RWAs)
6. **Hooks/callbacks** (ERC-777) — reentrancy through token transfer hooks
7. **Non-standard decimals** — 6 (USDC), 8 (WBTC), 2, 24 — normalize or die (10^12 error)
8. **Multiple entry points** — proxy tokens with multiple addresses, double-counting
9. **Upgradeable tokens** (USDC) — behavior can change post-deployment, ongoing trust assumption

### Part 3: Real Audit Findings
- Finding 1: Lending protocol + fee-on-transfer → protocol insolvency (Critical)
- Finding 2: Yield aggregator + USDT approval → funds stuck (Medium)
- Finding 3: DEX aggregator + missing return value → USDT swaps revert (Medium)
- Finding 4: Bridge + stETH rebasing → excess trapped forever (High)
- Finding 5: Governance + ERC-777 hooks → double voting (Critical)

### Part 4: Token Integration Audit Checklist
Nine questions, in order:
1. SafeERC20 used?
2. Arbitrary tokens or whitelist?
3. Credits requested or received amount?
4. Handles zero/self transfers?
5. Zero-first approval pattern?
6. Pull-based or push-based withdrawal?
7. Assumes 18 decimals?
8. Upgradeable token trust assumption?
9. Reentrancy through token hooks?


## HOUR 2: ERC-4626: THE VAULT STANDARD AND ITS ATTACK SURFACE 

### Part 5: What is ERC-4626 and Why Does It Exist?
- Pre-4626 fragmentation: yTokens, aTokens, cTokens — each custom
- The interface: deposit/mint/withdraw/redeem, preview functions, conversion functions, limits
- The core math: `shares = assets * totalSupply / totalAssets`
- Share price = `totalAssets / totalSupply` — the single ratio everything depends on

### Part 6: The Inflation Attack — Full Mechanics (1:15 – 1:35)
- Step-by-step with actual math (USDC 6 decimals):
  1. Attacker deposits 1 wei → 1 share
  2. Attacker donates 1M USDC directly (bypasses deposit)
  3. Victim deposits 999,999 USDC → 0 shares (integer division truncates)
  4. Attacker redeems 1 share → gets everything (~2M USDC)
- Why it works: EVM integer division, donation bypasses share minting
- **Mitigation 1:** Virtual shares/assets (OpenZeppelin _DECIMALS_OFFSET)
  - Dilutes donation across virtual share base
  - Tradeoff: small rounding tax on early depositors
- **Mitigation 2:** Dead shares — mint to 0xdead at construction
- **Mitigation 3:** Minimum deposit amount — raises attack cost
- Audit pattern: 6-point checklist for inflation vulnerability

### Part 7: Beyond Inflation — Other ERC-4626 Attack Surfaces (1:35 – 1:50)
- **Rounding direction** — deposit/mint round UP (vault-favorable), withdraw/redeem round DOWN
  - Wrong rounding = free value extraction via dust
  - Check Math.Rounding.Ceil vs Floor usage
- **Read-only reentrancy** — between asset transfer and share mint, share price is temporarily inflated
  - External protocols reading price during callback get manipulated values
  - Fix: mint before transfer, or reentrancy locks
- **totalAssets() manipulation** — balance-based (donation-vulnerable) vs accounting-based vs hybrid (external yield source)
  - Flash loan into yield source changes exchange rate → vault share price follows
- **Sandwich attacks** — front-run large deposits for share price profit
  - Mitigations: entry/exit fees, slippage protection (minShares parameter)
- **Withdrawal liquidity mismatch** — strategy doesn't have liquid funds, maxWithdraw lies
  - Audit: compare maxWithdraw return vs actual withdraw executability

### Part 8: Exercise — Spot the ERC-20/ERC-4626 Bugs (1:50 – 2:00)
- Drop SimpleVault contract in Telegram (6-7 bugs, 10 minutes)
- Walkthrough:
  1. Inflation attack — no virtual shares, raw balance totalAssets (Critical)
  2. Fee-on-transfer accounting mismatch — shares calculated pre-transfer (High/Critical)
  3. No SafeERC20 — USDT and non-compliant tokens revert (Medium)
  4. Read-only reentrancy in deposit — totalAssets up before totalSupply (High)
  5. flashDeposit callback enables share price manipulation mid-operation (Critical)
  6. Skim function math cancels out (dead code), no access control on empty vault (Medium/High)
  7. lastDepositBlock written but never enforced — no sandwich protection (Medium)

---

## Homework
1. Read OpenZeppelin ERC-4626 `_convertToShares` / `_convertToAssets`. Find one mainnet vault, check if it uses virtual shares. Post on X with contract address.
2. Browse Rareskills buggy ERC20 repo. Pick 3 buggy behaviors. Write 2-sentence explanation of how each breaks a lending protocol. Drop in group
