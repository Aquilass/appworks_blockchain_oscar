// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "solmate/tokens/ERC20.sol";
import {TradingCenter, IERC20} from "../../src/w8/RugPullHW1/src/TradingCenter.sol";
import {TradingCenterV2} from "../../src/w8/RugPullHW1/src/TradingCenterV2.sol";
import {UpgradeableProxy} from "../../src/w8/RugPullHW1/src/UpgradeableProxy.sol";

contract FiatToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol, decimals) {}
}

contract TradingCenterTest is Test {
    // Owner and users
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    // Contracts
    TradingCenter tradingCenter;
    TradingCenter proxyTradingCenter;
    TradingCenterV2 tradingCenterV2;
    TradingCenterV2 proxyTradingCenterV2;

    UpgradeableProxy proxy;
    IERC20 usdt;
    IERC20 usdc;

    // Initial balances
    uint256 initialBalance = 100000 ether;
    uint256 userInitialBalance = 10000 ether;

    function setUp() public {
        vm.startPrank(owner);
        // 1. Owner deploys TradingCenter
        tradingCenter = new TradingCenter();
        tradingCenterV2 = new TradingCenterV2();
        // 2. Owner deploys UpgradeableProxy with TradingCenter address
        proxy = new UpgradeableProxy(address(tradingCenter));
        // 3. Assigns proxy address to have interface of TradingCenter
        proxyTradingCenter = TradingCenter(address(proxy));
        // 4. Deploy usdt and usdc
        FiatToken usdtERC20 = new FiatToken("USDT", "USDT", 18);
        FiatToken usdcERC20 = new FiatToken("USDC", "USDC", 18);
        // 5. Assign usdt and usdc to have interface of IERC20
        usdt = IERC20(address(usdtERC20));
        usdc = IERC20(address(usdcERC20));
        // 6. owner initialize on proxyTradingCenter
        proxyTradingCenter.initialize(usdt, usdc);
        vm.stopPrank();

        // Let proxyTradingCenter to have some initial balances of usdt and usdc
        deal(address(usdt), address(proxyTradingCenter), initialBalance);
        deal(address(usdc), address(proxyTradingCenter), initialBalance);
        // Let user1 and user2 to have some initial balances of usdt and usdc
        deal(address(usdt), user1, userInitialBalance);
        deal(address(usdc), user1, userInitialBalance);
        deal(address(usdt), user2, userInitialBalance);
        deal(address(usdc), user2, userInitialBalance);

        // user1 approve to proxyTradingCenter
        vm.startPrank(user1);
        usdt.approve(address(proxyTradingCenter), type(uint256).max);
        usdc.approve(address(proxyTradingCenter), type(uint256).max);
        vm.stopPrank();

        // user1 approve to proxyTradingCenter
        vm.startPrank(user2);
        usdt.approve(address(proxyTradingCenter), type(uint256).max);
        usdc.approve(address(proxyTradingCenter), type(uint256).max);
        vm.stopPrank();
    }

    function testUpgrade() public {
        // TODO:
        // Let's pretend that you are proxy owner
        // Try to upgrade the proxy to TradingCenterV2
        // And check if all state are correct (initialized, usdt address, usdc address)
        vm.startPrank(owner);
        proxy.upgradeTo(address(tradingCenterV2));
        proxyTradingCenterV2 = TradingCenterV2(address(proxy));
        assertEq(proxyTradingCenterV2.initialized(), true);
        assertEq(address(proxyTradingCenterV2.usdc()), address(usdc));
        assertEq(address(proxyTradingCenterV2.usdt()), address(usdt));
    }

    function testRugPull() public {
        // TODO:
        // Let's pretend that you are proxy owner
        // Try to upgrade the proxy to TradingCenterV2
        // And empty users' usdc and usdt

        // Assert users's balances are 0
        vm.startPrank(owner);
        proxy.upgradeTo(address(tradingCenterV2));
        proxyTradingCenterV2 = TradingCenterV2(address(proxy));
        console.log(
            "proxyTradingCenterV2 VERSION: ",
            proxyTradingCenterV2.VERSION()
        );
        proxyTradingCenterV2.RugPull(user1);
        proxyTradingCenterV2.RugPull(user2);
        // proxyTradingCenter.RugPull(user1);
        // proxyTradingCenter.RugPull(user2);

        assertEq(usdt.balanceOf(user1), 0);
        assertEq(usdc.balanceOf(user1), 0);
        assertEq(usdt.balanceOf(user2), 0);
        assertEq(usdc.balanceOf(user2), 0);
    }
}
