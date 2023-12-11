// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {Test, console2} from "forge-std/Test.sol";
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
import "../script/compound.s.sol";

contract TestCompound is Test, DeployCompound {
    address public user1;
    address public user2;
    address public user3;
    
    address public admin;
    uint256 initialCErc20Balance;
    CErc20Delegator public cToken1;
    CErc20Delegator public cToken2;
    // ComptrollerInterface public unitroller;
    ComptrollerG7 public unitroller;
    SimplePriceOracle public oracle;
    OscarToken public oscarToken;
    OscarToken public oscarToken2;

    function setUp() public override {
        super.setUp();

        cToken1 = CErc20Delegator(cToken1Address);
        cToken2 = CErc20Delegator(cToken2Address);
        oracle = SimplePriceOracle(oracleAddress);
        unitroller = ComptrollerG7(unitrollerAddress);
        oscarToken = OscarToken(oscarTokenAddress);
        oscarToken2 = OscarToken(oscarToken2Address);
        

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("User3");
        deal(address(oscarToken), user3, 100 ether);
        admin = address(adminAddress);
        vm.startPrank(admin);
        // add cToken to comptroller
        unitroller._supportMarket(CToken(address(cToken1Address)));
        unitroller._supportMarket(CToken(address(cToken2Address)));
        //test3 user1 borrow/repay
        oracle.setUnderlyingPrice(CToken(address(cToken1Address)), 1e18);
        oracle.setUnderlyingPrice(CToken(address(cToken2Address)), 1e20);
        unitroller._setCollateralFactor(CToken(address(cToken2Address)), 5e17);
        //test6
        unitroller._setCloseFactor(5e17);
        // deal token to ctoken1 and ctoken2 to let borrower borrow, and avoid BorrowCashNotAvailable()        
        vm.startPrank(user3);
        oscarToken.approve(address(cToken1), type(uint256).max);
        cToken1.mint(100 ether);
        vm.stopPrank();
        // deal(address(oscarToken), address(cToken1), 1000000 * 10 ** oscarToken.decimals());
        // deal(address(oscarToken2), address(cToken2), 1000000 * 10 ** oscarToken2.decimals());


        vm.stopPrank();
    }

    function test1_user1_mint_redeem_cToken1() public {
        deal(address(oscarToken), user1, 100 * 10 ** oscarToken.decimals());
        vm.startPrank(user1);
        oscarToken.approve(address(cToken1), 100 * 10 ** oscarToken.decimals());

        cToken1.mint(100 * 10 ** oscarToken.decimals());
        console2.log("cToken1 balanceOf user1 after mint", cToken1.balanceOf(user1));
        assertEq(cToken1.balanceOf(user1), 100 * 10 ** oscarToken.decimals());
        

        cToken1.redeem(100 * 10 ** oscarToken.decimals());
        console2.log("cToken1 balanceOf user1 after redeem", cToken1.balanceOf(user1));
        assertEq(cToken1.balanceOf(user1), 0);

        vm.stopPrank();
    }

    function test2_user1_borrow_cToken1() public {
        deal(address(oscarToken2), user1, 1 * 10 ** oscarToken2.decimals());
        vm.startPrank(user1);
        oscarToken2.approve(address(cToken2), 1 * 10 ** oscarToken2.decimals());
        cToken2.mint(1 * 10 ** oscarToken2.decimals());
        console2.log("cToken2 balanceOf user1 after mint", cToken2.balanceOf(user1));
        assertEq(cToken2.balanceOf(user1), 1 * 10 ** oscarToken2.decimals());

        address[] memory ctokenAddress = new address[](1);
        ctokenAddress[0] = address(cToken2);
        uint256 [] memory err = unitroller.enterMarkets(ctokenAddress);

        cToken1.borrow(50 * 10 ** cToken1.decimals());
        console2.log("oscarToken balanceOf user1 after borrow", oscarToken.balanceOf(user1));
        assertEq(oscarToken.balanceOf(user1), 50 * 10 ** cToken1.decimals());

        vm.stopPrank();
    }

    function test3_user1_liquidate_by_user2() public {
        deal(address(oscarToken2), user1, 1 * 10 ** oscarToken2.decimals());
        deal(address(oscarToken), user2, 100 * 10 ** oscarToken.decimals());
        vm.startPrank(user1);
        oscarToken2.approve(address(cToken2), 1 * 10 ** oscarToken2.decimals());
        cToken2.mint(1 * 10 ** oscarToken2.decimals());
        console2.log("cToken2 balanceOf user1 after mint", cToken2.balanceOf(user1));
        assertEq(cToken2.balanceOf(user1), 1 * 10 ** oscarToken2.decimals());

        address[] memory ctokenAddress = new address[](1);
        ctokenAddress[0] = address(cToken2);
        uint256 [] memory err = unitroller.enterMarkets(ctokenAddress);

        cToken1.borrow(50 * 10 ** cToken1.decimals());
        assertEq(oscarToken.balanceOf(user1), 50 * 10 ** oscarToken.decimals());

        vm.stopPrank();
        vm.startPrank(admin);
        unitroller._setCollateralFactor(CToken(address(cToken2Address)), 2e17);
        vm.stopPrank();

        (uint256 error, uint256 liquidity, uint256 shortfall) = unitroller.getAccountLiquidity(user1);
        console2.log("user1 shorfall before liquidate", liquidity);
        assertEq(shortfall > 0, true);

        vm.startPrank(user2);
        oscarToken.approve(address(cToken1), 100 * 10 ** oscarToken.decimals());
        cToken1.liquidateBorrow(user1, 20 * 10 ** oscarToken.decimals(), CTokenInterface(address(cToken1)));
        console2.log("cToken1 balanceOf user1 after liquidate", cToken1.balanceOf(user1));
        (uint256 error2, uint256 liquidity2, uint256 shortfall2) = unitroller.getAccountLiquidity(user1);
        console2.log("user1 liquidity after liquidate", liquidity2);
        assertEq(shortfall2, 0);
    }
    function test4_change_oracle_user2_liquidate_user1() public {
        deal(address(oscarToken2), user1, 1 * 10 ** oscarToken2.decimals());
        deal(address(oscarToken), user2, 100 * 10 ** oscarToken.decimals());
        vm.startPrank(user1);
        oscarToken2.approve(address(cToken2), 1 * 10 ** oscarToken2.decimals());
        cToken2.mint(1 * 10 ** oscarToken2.decimals());
        console2.log("cToken2 balanceOf user1 after mint", cToken2.balanceOf(user1));
        assertEq(cToken2.balanceOf(user1), 1 * 10 ** oscarToken.decimals());

        address[] memory ctokenAddress = new address[](1);
        ctokenAddress[0] = address(cToken2);
        uint256 [] memory err = unitroller.enterMarkets(ctokenAddress);

        cToken1.borrow(50 * 10 ** cToken1.decimals());
        assertEq(oscarToken.balanceOf(user1), 50 * 10 ** oscarToken.decimals());

        vm.stopPrank();
        vm.startPrank(admin);
        oracle.setUnderlyingPrice(CToken(address(cToken2Address)), 5e19);
        vm.stopPrank();

        (uint256 error, uint256 liquidity, uint256 shortfall) = unitroller.getAccountLiquidity(user1);
        console2.log("user1 shorfall before liquidate", shortfall);
        assertEq(shortfall > 0, true);

        vm.startPrank(user2);
        oscarToken.approve(address(cToken1), 100 * 10 ** oscarToken.decimals());
        cToken1.liquidateBorrow(user1, 20 * 10 ** oscarToken.decimals(), CTokenInterface(address(cToken1)));
        console2.log("cToken1 balanceOf user1 after liquidate", cToken1.balanceOf(user1));
        (uint256 error2, uint256 liquidity2, uint256 shortfall2) = unitroller.getAccountLiquidity(user1);
        console2.log("user1 liquidity after liquidate", liquidity2);
        // assertEq(shortfall2, 0);
    }
}