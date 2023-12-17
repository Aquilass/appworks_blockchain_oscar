pragma solidity ^0.8.19;
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {
  IFlashLoanSimpleReceiver,
  IPoolAddressesProvider,
  IPool
} from "aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import {IUniswapV2Callee} from "v2-core/interfaces/IUniswapV2Callee.sol";
import {IUniswapV2Factory} from "v2-core/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "v2-core/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "v2-periphery/interfaces/IUniswapV2Router02.sol";
import {CToken} from "compound-protocol/CToken.sol";
import {CTokenInterface} from "compound-protocol/CTokenInterfaces.sol";
import {CErc20Delegator} from "compound-protocol/CErc20Delegator.sol";
import{console2} from "forge-std/console2.sol";
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ISwapRouter.ExactInputSingleParams memory params) external returns (uint256 amountOut);
}
// TODO: Inherit IFlashLoanSimpleReceiver
contract AaveFlashLoan {
  address constant POOL_ADDRESSES_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
  IUniswapV2Router02 public router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  IUniswapV2Factory public factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
  address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  ISwapRouter swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  function execute(bytes calldata _params) external {
    // (user1, cUNI, cUSDC,USDC, UNI, repayAmount);
    (address user1, address cUNI, address cUSDC, address USDC, address UNI, uint256 repayAmount) = abi.decode(_params, (address, address, address, address, address, uint256));
    IPool(POOL()).flashLoanSimple(address(this), USDC, repayAmount, _params, 0);
  }
  function executeOperation(
    address assets,
    uint256 amounts,
    uint256 premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool) {
    (address user1, CErc20Delegator  cUNI, CErc20Delegator  cUSDC, address USDC, address UNI, uint256 repayAmount) = abi.decode(params, (address, CErc20Delegator, CErc20Delegator, address, address, uint256));
    ERC20(USDC).approve(address(cUSDC), type(uint256).max);
    cUSDC.liquidateBorrow(user1, amounts, CTokenInterface(cUNI));
    cUNI.redeem(CErc20Delegator(cUNI).balanceOf(address(this)));
    console2.log("UNI balance after liquidate", ERC20(UNI).balanceOf(address(this)));

    ERC20(UNI).approve(address(swapRouter), type(uint256).max);
    ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams({
        tokenIn: address(UNI),
        tokenOut: assets,
        fee: 3000, // 0.3%
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: ERC20(UNI).balanceOf(address(this)),
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
    });
    swapRouter.exactInputSingle(swapParams);
    // address pair = IUniswapV2Factory(factory).getPair(UNI, USDC);
    // address[] memory path = new address[](2);
    // path[0] = UNI;
    // path[1] = USDC;
    // ERC20(UNI).approve(
    //     address(router),
    //     type(uint256).max
    //     );
    // router.swapExactTokensForTokens(
    //     ERC20(UNI).balanceOf(address(this)),
    //     0,
    //     path,
    //     address(this),
    //     block.timestamp
    //     );
    console2.log("USDC balance before repay ", ERC20(USDC).balanceOf(address(this)));
    ERC20(assets).approve(address(msg.sender), amounts + premiums);
    return true;

    }
  function ADDRESSES_PROVIDER() public view returns (IPoolAddressesProvider) {
    return IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER);
  }
  function withdraw() public {
    ERC20(USDC).transfer(msg.sender, ERC20(USDC).balanceOf(address(this)));
  }

  function POOL() public view returns (IPool) {
    return IPool(ADDRESSES_PROVIDER().getPool());
  }
}
