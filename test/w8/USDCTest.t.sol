// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.1;

import "forge-std/Test.sol";
import "solmate/tokens/ERC20.sol";
import {usdcV2} from "../../src/w8/SecondRugPull/USDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract USDCV2 is Test {
    // Owner and users
    address owner = address(0x807a96288A1A408dBC13DE2b1d087d10356395d2);
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    usdcV2 usdcv2;

    function setUp() public {
        vm.startPrank(owner);
        // 1. Owner deploys TradingCenter

        usdcv2 = new usdcV2();
        vm.stopPrank();
    }

    function testUpgrade() public {
        vm.startPrank(owner);
        (bool success, ) = usdc.call(
            abi.encodeWithSignature("upgradeTo(address)", address(usdcv2))
        );
        require(success, "upgrade failed");
        vm.stopPrank();
        vm.startPrank(user1);
        (bool success_upgrade, bytes memory version) = usdc.call(
            abi.encodeWithSignature("VERSION()", "")
        );
        require(success, "upgrade failed");
        require(success_upgrade == true, "version not match");
        console.log("upgrade success", success);
        console.log("version", abi.decode(version, (string)));
        vm.stopPrank();
    }

    function testUpgradeAndMakeWhitelist() public {
        vm.startPrank(owner);
        (bool success, ) = usdc.call(
            abi.encodeWithSignature("upgradeTo(address)", address(usdcv2))
        );
        require(success, "upgrade failed");
        vm.stopPrank();
        vm.startPrank(user1);
        address[] memory whitelist = new address[](2);
        whitelist[0] = user1;
        whitelist[1] = user2;
        (bool success_init, ) = usdc.call(
            abi.encodeWithSignature("initializeV2(address[])", whitelist)
        );
        require(success_init, "initialize failed");
        (bool success_mint, ) = usdc.call(
            abi.encodeWithSignature("mint(address,uint256)", user1, 100)
        );
        require(success_mint, "mint failed");
        (bool success_check_balance, bytes memory balance) = usdc.call(
            abi.encodeWithSignature("balanceOf(address)", user1)
        );
        require(success_check_balance, "check balance failed");
        console.log("User1 balance", abi.decode(balance, (uint256)));

        vm.stopPrank();
    }

    function testUser3ShouldNotBeAbleToMint() public {
        vm.startPrank(owner);
        (bool success, ) = usdc.call(
            abi.encodeWithSignature("upgradeTo(address)", address(usdcv2))
        );
        require(success, "upgrade failed");
        vm.stopPrank();
        vm.startPrank(user1);
        address[] memory whitelist = new address[](2);
        whitelist[0] = user1;
        whitelist[1] = user2;
        (bool success_init, ) = usdc.call(
            abi.encodeWithSignature("initializeV2(address[])", whitelist)
        );
        require(success_init, "initialize failed");
        vm.stopPrank();
        vm.startPrank(user3);
        (bool success_mint, ) = usdc.call(
            abi.encodeWithSignature("mint(address,uint256)", user3, 100)
        );
        require(success_mint == false, "user3 should not be able to mint");
        (bool success_check_balance, bytes memory balance) = usdc.call(
            abi.encodeWithSignature("balanceOf(address)", user1)
        );
        require(success_check_balance, "check balance failed");
        require(abi.decode(balance, (uint256)) == 0, "balance should be 0");
        console.log("User3 balance", abi.decode(balance, (uint256)));

        vm.stopPrank();
    }

    function testOnlyWhitelistCanTransfer() public {
        vm.startPrank(owner);
        (bool success, ) = usdc.call(
            abi.encodeWithSignature("upgradeTo(address)", address(usdcv2))
        );
        require(success, "upgrade failed");
        vm.stopPrank();
        vm.startPrank(user1);
        address[] memory whitelist = new address[](2);
        whitelist[0] = user1;
        whitelist[1] = user2;
        (bool success_init, ) = usdc.call(
            abi.encodeWithSignature("initializeV2(address[])", whitelist)
        );
        require(success_init, "initialize failed");
        vm.stopPrank();
        vm.startPrank(user1);
        (bool success_mint, ) = usdc.call(
            abi.encodeWithSignature("mint(address,uint256)", user1, 100)
        );
        require(success_mint, "mint failed");
        (bool success_transfer_user2, ) = usdc.call(
            abi.encodeWithSignature("transfer(address,uint256)", user2, 50)
        );
        (bool success_transfer_user3, ) = usdc.call(
            abi.encodeWithSignature("transfer(address,uint256)", user3, 50)
        );
        require(success_transfer_user2, "transfer failed");
        require(success_transfer_user3, "transfer failed");
        (bool success_check_balance, bytes memory balance) = usdc.call(
            abi.encodeWithSignature("balanceOf(address)", user2)
        );
        require(success_check_balance, "check balance failed");
        require(abi.decode(balance, (uint256)) == 50, "balance should be 50");
        console.log("User2 balance", abi.decode(balance, (uint256)));
        vm.stopPrank();
        vm.startPrank(user3);
        (bool success_tranfer_user2, ) = usdc.call(
            abi.encodeWithSignature("transfer(address,uint256)", user2, 50)
        );
        require(success_tranfer_user2 == false, "transfer should fail");
        require(abi.decode(balance, (uint256)) == 50, "balance should be 50");
        console.log("User3 balance", abi.decode(balance, (uint256)));
    }

    function testShouldBeAbleToIntialedV2Once() public {
        vm.startPrank(owner);
        (bool success, ) = usdc.call(
            abi.encodeWithSignature("upgradeTo(address)", address(usdcv2))
        );
        require(success, "upgrade failed");
        vm.stopPrank();
        vm.startPrank(user1);
        address[] memory whitelist = new address[](2);
        whitelist[0] = user1;
        whitelist[1] = user2;
        (bool success_init, ) = usdc.call(
            abi.encodeWithSignature("initializeV2(address[])", whitelist)
        );
        require(success_init, "initialize failed");
        (bool success_init2, ) = usdc.call(
            abi.encodeWithSignature("initializeV2(address[])", whitelist)
        );
        require(success_init2 == false, "initialize should fail");
        vm.stopPrank();
    }
}
