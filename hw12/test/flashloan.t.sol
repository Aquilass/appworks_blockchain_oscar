// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import { ComptrollerG7 } from "compound-protocol/ComptrollerG7.sol";
import {SimplePriceOracle} from "compound-protocol/SimplePriceOracle.sol";
import {Unitroller} from "compound-protocol/Unitroller.sol";
import {WhitePaperInterestRateModel} from "compound-protocol/WhitePaperInterestRateModel.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {CErc20Delegate} from "compound-protocol/CErc20Delegate.sol";
import {OscarToken} from "../src/OscarToken.sol";
import {ComptrollerInterface} from "compound-protocol/ComptrollerInterface.sol";
import {InterestRateModel} from "compound-protocol/InterestRateModel.sol";
import {CErc20Delegator} from "compound-protocol/CErc20Delegator.sol";
import {CToken} from "compound-protocol/CToken.sol";
import {CTokenInterface} from "compound-protocol/CTokenInterfaces.sol";
import "../script/flashloan.s.sol";
import "../src/FlashLoanLiquidate.sol";

contract TestAAVEV3 is Test, DeployCompound {
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("User3");
    
    address public admin;
    uint256 initialCErc20Balance;
    CErc20Delegator public cUSDC;
    CErc20Delegator public cUNI;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    ERC20 usdc = ERC20(USDC);
    ERC20 uni = ERC20(UNI);
    // ComptrollerInterface public unitroller;
    ComptrollerG7 public unitroller;
    SimplePriceOracle public oracle;

    AaveFlashLoan public flashloan;

    // address public USDC;
    // ERC20 usdc;
    // address public UNI;
    // ERC20 uni;
    function setUp() public override {
        super.setUp();

        cUSDC = CErc20Delegator(cUSDCAddress);
        cUNI = CErc20Delegator(cUNIAddress);
        oracle = SimplePriceOracle(oracleAddress);
        unitroller = ComptrollerG7(unitrollerAddress);

        

        admin = address(adminAddress);
        vm.startPrank(admin);
        // add cToken to comptroller
        unitroller._supportMarket(CToken(address(cUSDCAddress)));
        unitroller._supportMarket(CToken(address(cUNIAddress)));
        //test3 user1 borrow/repay
        oracle.setUnderlyingPrice(CToken(address(cUSDCAddress)), 1e30);
        oracle.setUnderlyingPrice(CToken(address(cUNIAddress)), 5e18);
        unitroller._setCollateralFactor(CToken(address(cUNIAddress)), 5e17);
        // set liquidationIncentive
        unitroller._setLiquidationIncentive(1.08 * 1e18);
        //test6
        unitroller._setCloseFactor(5e17);
        vm.stopPrank(); 
        // deal token to cUSDC and cUNI to let borrower borrow, and avoid BorrowCashNotAvailable()        
        deal(address(USDC), user3, 10000 * 10 ** usdc.decimals());
        deal(address(UNI), user3, 10000 * 10 ** uni.decimals());
        vm.startPrank(user3);
        usdc.approve(address(cUSDC), type(uint256).max);
        cUSDC.mint(10000 * 10 ** usdc.decimals());
        uni.approve(address(cUNI), type(uint256).max);
        cUNI.mint(10000 * 10 ** uni.decimals());
        vm.stopPrank();
       // give user1 some UNI
        deal(address(UNI), user1, 1000 ** uni.decimals());


    }
    function test1_user1_mintUNI_and_borrowUSDC() public {
        vm.startPrank(user1);
        uni.approve(address(cUNI), type(uint256).max);
        cUNI.mint(1000 * 1e18);
        console2.log("cUNI balanceOf user1 after mint", cUNI.balanceOf(user1));
        assertEq(cUNI.balanceOf(user1), 1000 * 1e18);
        // borrow USDC
        address[] memory assets = new address[](1);
        assets[0] = address(cUNI);
        unitroller.enterMarkets(assets);
        cUSDC.borrow(2500 * 1e6);
        console2.log("USDC balanceOf user1 after borrow", usdc.balanceOf(user1));
        assertEq(usdc.balanceOf(user1), 2500 * 1e6);
        vm.stopPrank();

    }
    function test_aavev3_flashloan_shortfall() public {
        this.test1_user1_mintUNI_and_borrowUSDC();
        // set uni price to 4
        oracle.setUnderlyingPrice(CToken(address(cUNI)), 4e18);

        // liquidate
        uint256 borrowBalance = cUSDC.borrowBalanceStored(user1);
        uint256 repayAmount = borrowBalance /2;
        console2.log("repayAmount", repayAmount);
        // send data to flashloan contract
        bytes memory data = abi.encode(user1, cUNI, cUSDC,USDC, UNI, repayAmount);
        vm.startPrank(user2);
        flashloan = new AaveFlashLoan();
        flashloan.execute(data);

        flashloan.withdraw();
        console2.log("user2 balance after repay, profit amount: ", usdc.balanceOf(user2));
    }
}