// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Callee } from "v2-core/interfaces/IUniswapV2Callee.sol";
import {console2} from "forge-std/console2.sol";
// This is a practice contract for flash swap arbitrage
contract Arbitrage is IUniswapV2Callee, Ownable {

    //
    // EXTERNAL NON-VIEW ONLY OWNER
    //
    struct CallBackData {
        address priceLowerPool;
        address priceHigherPool;
        uint256 borrowETH;
        uint256 amountIn;
        uint256 amountOut;
        address weth;
        address usdc;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Withdraw failed");
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(msg.sender, amount), "Withdraw failed");
    }

    //
    // EXTERNAL NON-VIEW
    //

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external override {
        // TODO
        console2.log("uniswapV2Call");
        CallBackData memory _data = abi.decode(data, (CallBackData));
        require(msg.sender == address(_data.priceLowerPool), "Sender must be uniswapV2Router");
        require(sender == address(this), "Sender must be this contract");
        // IERC20(_data.priceLowerPool).approve(address(_data.priceHigherPool), _data.borrowETH);

        IERC20(_data.weth).transfer(_data.priceHigherPool, _data.borrowETH);
        IUniswapV2Pair(_data.priceHigherPool).swap(0,_data.amountOut, address(this), bytes(""));
        IERC20(_data.usdc).transfer(_data.priceLowerPool, _data.amountIn);

        // IERC20(_USDC).transfer(_data.priceLowerPool, _data.amountIn);
        // IERC20(address(weth)).deposit{value: _data.amountIn}();
    }

    // Method 1 is
    //  - borrow WETH from lower price pool
    //  - swap WETH for USDC in higher price pool
    //  - repay USDC to lower pool
    // Method 2 is
    //  - borrow USDC from higher price pool
    //  - swap USDC for WETH in lower pool
    //  - repay WETH to higher pool
    // for testing convenient, we implement the method 1 here
    function arbitrage(address priceLowerPool, address priceHigherPool, uint256 borrowETH) external {
        // TODO
        address weth = IUniswapV2Pair(priceLowerPool).token0();
        address usdc = IUniswapV2Pair(priceLowerPool).token1();
        uint256 reserveInLow;
        uint256 reserveOutLow;
        uint256 reserveInHigh;
        uint256 reserveOutHigh;
        require(borrowETH > 0, "Borrow amount must be greater than 0");
        (reserveInLow, reserveOutLow,) = IUniswapV2Pair(priceLowerPool).getReserves();
        uint256 getAmountIn = _getAmountIn(borrowETH,reserveOutLow,reserveInLow);
        (reserveInHigh, reserveOutHigh,) = IUniswapV2Pair(priceHigherPool).getReserves();
        uint256 getAmountOut = _getAmountOut(borrowETH,reserveInHigh,reserveOutHigh);
        console2.log("getAmountIn",getAmountIn);
        CallBackData memory data = CallBackData(
            priceLowerPool,
            priceHigherPool,
            borrowETH,
            getAmountIn,
            getAmountOut,
            weth,
            usdc
        );
        IUniswapV2Pair(priceLowerPool).swap(borrowETH, 0, address(this), abi.encode(data));
        

    }

    //
    // INTERNAL PURE
    //

    // copy from UniswapV2Library
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    // copy from UniswapV2Library
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
