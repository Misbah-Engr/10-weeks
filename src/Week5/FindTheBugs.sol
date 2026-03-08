// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VulnerableDEXAggregator {
    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;
    
    mapping(address => mapping(address => uint256)) public deposits;
    mapping(address => bool) public supportedTokens;
    
    uint256 public totalFees;
    address public owner;
    
    constructor(address _router, address _factory) {
        router = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(_factory);
        owner = msg.sender;
    }
    
    // Bug 1: Where's the slippage protection?
    function swapExact(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        
        uint256 fee = amountIn * 3 / 1000; // 0.3% aggregator fee
        uint256 swapAmount = amountIn - fee;
        totalFees += fee;
        
        IERC20(tokenIn).approve(address(router), swapAmount);
        
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        
        uint256[] memory amounts = router.swapExactTokensForTokens(
            swapAmount,
            0,                    // amountOutMin = 0
            path,
            msg.sender,
            block.timestamp
        );
        
        return amounts[amounts.length - 1];
    }
    
    // Bug 2: What's wrong with this price check?
    function getTokenPrice(address token, address quoteToken) public view returns (uint256) {
        address pair = factory.getPair(token, quoteToken);
        require(pair != address(0), "No pair");
        
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        
        if (IUniswapV2Pair(pair).token0() == token) {
            return uint256(reserve1) * 1e18 / uint256(reserve0);
        } else {
            return uint256(reserve0) * 1e18 / uint256(reserve1);
        }
    }
    
    // Bug 3: Think about who can call this and when
    function depositForLater(address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender][token] += amount;
    }
    
    function withdrawDeposit(address token) external {
        uint256 amount = deposits[msg.sender][token];
        require(amount > 0, "Nothing to withdraw");
        
        IERC20(token).transfer(msg.sender, amount);
        deposits[msg.sender][token] = 0;
    }
    
    // Bug 4: Look at what this function trusts
    function swapWithCallback(
        address pair,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external {
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }
    
    // Bug 5: How is this getting the LP token value?
    function depositLP(address pair, uint256 lpAmount) external {
        uint256 value = getLPValue(pair, lpAmount);
        require(value > 0, "Worthless LP");
        
        IERC20(pair).transferFrom(msg.sender, address(this), lpAmount);
        deposits[msg.sender][pair] += value; // Store USD value, not LP amount
    }
    
    function getLPValue(address pair, uint256 lpAmount) public view returns (uint256) {
        (uint112 r0, uint112 r1,) = IUniswapV2Pair(pair).getReserves();
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        
        uint256 totalSupply = IUniswapV2Pair(pair).totalSupply();
        
        uint256 amount0 = uint256(r0) * lpAmount / totalSupply;
        uint256 amount1 = uint256(r1) * lpAmount / totalSupply;
        
        // Price both sides in token1
        uint256 price0 = getTokenPrice(token0, token1);
        uint256 value = amount0 * price0 / 1e18 + amount1;
        
        return value;
    }
    
    // Bug 6: What about fee-on-transfer tokens?
    function batchSwap(
        address[] calldata tokensIn,
        address[] calldata tokensOut,
        uint256[] calldata amounts
    ) external {
        require(tokensIn.length == tokensOut.length && tokensOut.length == amounts.length, "Length mismatch");
        
        for (uint256 i = 0; i < tokensIn.length; i++) {
            IERC20(tokensIn[i]).transferFrom(msg.sender, address(this), amounts[i]);
            IERC20(tokensIn[i]).approve(address(router), amounts[i]);
            
            address[] memory path = new address[](2);
            path[0] = tokensIn[i];
            path[1] = tokensOut[i];
            
            router.swapExactTokensForTokens(
                amounts[i],     // Uses requested amount, not actual received
                0,
                path,
                msg.sender,
                block.timestamp
            );
        }
    }
    
    function withdrawFees(address token) external {
        require(msg.sender == owner, "Not owner");
        IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }
}
