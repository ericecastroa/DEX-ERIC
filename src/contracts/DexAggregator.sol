// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface RouterInterface {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract DexAggregator {

    address public WETH;
    address public USDC;

    RouterInterface[2] public routers;

    constructor() {
        routers[0] = RouterInterface(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        ); // UNISWAP
        routers[1] = RouterInterface(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
            // 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
        ); // SUSHISWAP
        WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        USDC = 0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C;
        // WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        // USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }

    function uniRate(address[] memory path, uint256 amountIn)
        public
        view
        returns (uint256)
    {
        uint256[] memory uniswap = routers[0].getAmountsOut(amountIn, path);
        return uniswap[1];
    }

    function sushiRate(address[] memory path, uint256 amountIn)
        public
        view
        returns (uint256)
    {
        uint256[] memory sushi = routers[1].getAmountsOut(amountIn, path);
        return sushi[1];
    }

    function getHighestAmountOut(address[] memory path, uint256 amountIn)
        public
        view
        returns (uint256, uint256)
    {
        // getAmountsOut returns array in which the item at index 1 is the rate
        uint256[] memory uni = routers[0].getAmountsOut(amountIn, path);
        uint256[] memory sushi = routers[1].getAmountsOut(amountIn, path);
        // return the best exchange index + the actual rate
        if (uni[1] > sushi[1]) {
            return (0, uni[1]);
        } else {
            return (1, sushi[1]);
        }
    }

    function usdcToWeth(uint256 usdcAmount) public {
        IERC20 token = IERC20(USDC);
       
        token.transferFrom(msg.sender,address(this), usdcAmount);

        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = WETH;

        (uint256 routerIndex, uint256 minAmountOut) = getHighestAmountOut(
            path,
            usdcAmount
        );

        require(token.approve(address(routers[routerIndex]), usdcAmount));

        // we are setting the minimum amount about to the max amount, fails if we get any less
        // we are allowing the swap to take at most 5 minutes

        routers[routerIndex].swapExactTokensForTokens(
            usdcAmount,   //100
            minAmountOut, //2 weth
            path,
            msg.sender,
            block.timestamp + 5 minutes
        );
    }
}


// [0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C, 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6]
