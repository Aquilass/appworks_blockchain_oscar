// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract SimpleSwap is ISimpleSwap, ERC20("SimpleSwap", "SSWP") {
    address tokenA;
    address tokenB;
    uint256 private reserveA;
    uint256 private reserveB;

    event MintLiquidity(address indexed sender, uint amountA, uint amountB);
    event BurnLiquidity(address indexed sender, uint amountA, uint amountB, address to);

    constructor(address _tokenA, address _tokenB) {
        // check tokenA and tokenB are contract
        require(isContract(_tokenA), "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(isContract(_tokenB), "SimpleSwap: TOKENB_IS_NOT_CONTRACT");

        (tokenA, tokenB) = sortTokens(_tokenA, _tokenB);
    }
    
    // test_revert_constructor_tokenA_is_not_a_contract() 
    // reference: https://ethereum.stackexchange.com/questions/15641/how-does-a-contract-find-out-if-another-address-is-a-contract
    function isContract(address _address) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address _tokenA, address _tokenB) internal pure returns (address token0, address token1) {
        require(_tokenA != _tokenB, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");
        (token0, token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        require(token0 != address(0), "SimpleSwap: ZERO_ADDRESS");
    }

    function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired
    ) external override returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        //test_revert_addLiquidity_when_tokenA_amount_is_zero
        require(amountADesired > 0 && amountBDesired > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        (amountA, amountB) = _addLiquidity(amountADesired, amountBDesired);
        ERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        ERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        liquidity = mintLiquidity(msg.sender);
        emit AddLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    // 
    function _addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired
    ) internal view returns (uint256 amountA, uint256 amountB) {
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB) {
        this.transferFrom(msg.sender, address(this), liquidity);
        (amountA, amountB) = burnLiquidity(msg.sender);
        emit RemoveLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    function mintLiquidity(address to) public returns (uint liquidity) {
        address _tokenA = tokenA; // gas savings
        address _tokenB = tokenB; // gas savings

        uint balanceA = ERC20(_tokenA).balanceOf(address(this));
        uint balanceB = ERC20(_tokenB).balanceOf(address(this));
        uint256 _totalSupply = totalSupply();

        uint amountA = balanceA-reserveA;
        uint amountB = balanceB-reserveB;

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amountA *amountB);
        } else {
            liquidity = Math.min(amountA*_totalSupply / reserveA, amountB*_totalSupply / reserveB);
        }

        require(liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_MINTED");
        
        _mint(to, liquidity);
        _update(balanceA, balanceB);
        emit MintLiquidity(msg.sender, amountA, amountB);
    }

    function burnLiquidity(address to) internal returns (uint256 amountA, uint256 amountB) {
        address _tokenA = tokenA; // gas savings
        address _tokenB = tokenB; // gas savings

        uint256 balanceA = ERC20(_tokenA).balanceOf(address(this));
        uint256 balanceB = ERC20(_tokenB).balanceOf(address(this));
        uint256 totalSupply = totalSupply();
        
        uint256 liquidity = balanceOf(address(this));
        amountA = liquidity*balanceA / totalSupply; // using balances ensures pro-rata distribution
        amountB = liquidity*balanceB / totalSupply; // using balances ensures pro-rata distribution

        //test_revert_removeLiquidity_when_lp_token_balance_is_zero()
        require(amountA > 0 && amountB > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);

        ERC20(tokenA).transfer(to, amountA);
        ERC20(tokenB).transfer(to, amountB);
        balanceA = ERC20(tokenA).balanceOf(address(this));
        balanceB = ERC20(tokenB).balanceOf(address(this));

        _update(balanceA, balanceB);
        emit BurnLiquidity(msg.sender, amountA, amountB, to);
    }

    //SimpleSwap.swap.t.sol
    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut) {
        // test_revert_when_tokenIn_is_not_tokenA_or_tokenB()
        require(tokenIn == tokenA || tokenIn == tokenB, "SimpleSwap: INVALID_TOKEN_IN");
        // test_revert_when_tokenOut_is_not_tokenA_or_tokenB
        require(tokenOut == tokenA || tokenOut == tokenB, "SimpleSwap: INVALID_TOKEN_OUT");
        // test_revert_when_tokenIn_is_the_same_as_tokenOut
        require(tokenOut != tokenIn, "SimpleSwap: IDENTICAL_ADDRESS");
        // test_swap_from_tokenA_to_tokenB
        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        (uint256 reserveIn, uint256 reserveOut) = this.getReserves();
        require( reserveIn > 0 && 0 < reserveOut, "SimpleSwap: INSUFFICIENT_LIQUIDITY");

        // amountOut = amountIn * reserveOut / (reserveIn + amountIn)
        // use division to avoid amountOut overflow
        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;

        if (tokenIn == tokenA) {
            reserveA = reserveA + amountIn;
            reserveB = reserveB - amountOut;
            ERC20(tokenA).transferFrom(msg.sender, address(this), amountIn);
            ERC20(tokenB).transfer(msg.sender, amountOut);
        } else {
            reserveA = reserveA - amountOut;
            reserveB = reserveB + amountIn;
            ERC20(tokenA).transfer(msg.sender, amountOut);
            ERC20(tokenB).transferFrom(msg.sender, address(this), amountIn);
        }
        uint256 reserveInAfter = reserveIn + amountIn;
        uint256 reserveOutAfter = reserveOut - amountOut;
        // test_revert_when_k_value_is_not_greater_than_or_eq_original_k_value
        require(
            // END: ed8c6549bwf9
            reserveInAfter * reserveOutAfter >= reserveIn * reserveOut,
            "SimpleSwap: K_VALUE_NOT_GREATER_THAN_OR_EQ_ORIGINAL_K_VALUE"
        );

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    // SimpleSwap.common.t.sol
    function getReserves() external view override returns (uint256 _reserveA, uint256 _reserveB) {
        _reserveA = reserveA;
        _reserveB = reserveB;
    }

    function getTokenA() external view override returns (address _tokenA) {
        _tokenA = tokenA;
    }

    function getTokenB() external view override returns (address _tokenB) {
        _tokenB = tokenB;
    }
    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint _reserveA, uint _reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "INSUFFICIENT_AMOUNT");
        require(_reserveA > 0 && _reserveB > 0, "INSUFFICIENT_LIQUIDITY");
        amountB = amountA * (_reserveB) / _reserveA;
    }
    function _update(uint balanceA, uint balanceB) private {
        reserveA = uint256(balanceA);
        reserveB = uint256(balanceB);
    }
}