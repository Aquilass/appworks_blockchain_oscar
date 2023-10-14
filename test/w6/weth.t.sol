// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import {Test, console2} from "forge-std/Test.sol";
import {WETH} from "../../src/w6/WETH.sol";

contract WETHTest is Test {
    WETH public weth;
    address public bob;
    address public alice;
    event Deposit(address indexed to, uint256 value);
    event Withdraw(address indexed from, uint256 value);

    function setUp() public {
        weth = new WETH();
        bob = makeAddr("bob");
        alice = makeAddr("alice");
    }

    function test1DepositEQTokenMint() public {
        weth.deposit{value: 100}();
        assertEq(weth.balanceOf(address(this)), 100);
        //log the balance of the contract
        console2.log("balanceOf(address(this))", weth.balanceOf(address(this)));
    }

    function test2DepositEqEtherInWETH() public {
        uint256 amount = 100;
        weth.deposit{value: amount}();
        assertEq(amount, weth.totalSupply());
        console2.log(weth.totalSupply());
    }

    function test3DepositShouldEmitEvent() public {
        uint256 amount = 100;
        // deal(address(this), amount);
        vm.expectEmit(true, false, false, true);
        // this is an error in foundry solidity 0.8.21
        //this will be fix in 0.8.22
        // reference: https://github.com/ethereum/solidity/issues/14430
        // emit WETH.Deposit(address(this), amount);
        emit Deposit(address(this), amount);
        // weth.deposit{value: amount}();
        (bool success, ) = address(weth).call{value: 100}(
            abi.encodeWithSignature("deposit()")
        );
        require(success, "deposit successfully");
    }

    function test4WithdrawWillBurnToken() public {
        deal(bob, 1000);
        vm.startPrank(bob);
        uint256 amount = 100;
        weth.deposit{value: amount}();
        assertEq(weth.totalSupply(), amount);
        console2.log(weth.balanceOf(address(bob)));
        (bool success, ) = address(weth).call(
            abi.encodeWithSignature("withdraw(uint256)", amount)
        );
        require(success, "withdraw successfully");
        assertEq(weth.totalSupply(), 0);
        assertEq(weth.balanceOf(address(bob)), 0);
        vm.stopPrank();
    }

    function test5WithdrawWillTransferEther() public {
        deal(bob, 100);
        vm.startPrank(bob);
        uint256 amount = 100;
        weth.deposit{value: amount}();
        assertEq(weth.totalSupply(), amount);
        console2.log(weth.balanceOf(address(bob)));
        (bool success, ) = address(weth).call(
            abi.encodeWithSignature("withdraw(uint256)", amount)
        );
        require(success, "withdraw successfully");
        assertEq(weth.totalSupply(), 0);
        assertEq(bob.balance, 100);
        vm.stopPrank();
    }

    function test6WithdrawShouldEmitEvent() public {
        deal(bob, 100);
        vm.startPrank(bob);
        uint256 amount = 100;
        weth.deposit{value: amount}();
        vm.expectEmit(true, false, false, true);
        emit Withdraw(address(bob), amount);
        (bool success, ) = address(weth).call(
            abi.encodeWithSignature("withdraw(uint256)", amount)
        );
        require(success, "withdraw successfully");
        vm.stopPrank();
    }

    function test7TransferShouldSendERC20ToAnotherUser() public {
        deal(bob, 100);
        vm.startPrank(bob);
        uint256 amount = 100;
        weth.deposit{value: amount}();
        assertEq(weth.totalSupply(), 100);
        assertEq(weth.balanceOf(address(bob)), 100);
        assertEq(weth.balanceOf(address(alice)), 0);
        (bool success, ) = address(weth).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                address(alice),
                amount
            )
        );
        require(success, "transfer successfully");
        assertEq(weth.totalSupply(), 100);
        assertEq(weth.balanceOf(address(bob)), 0);
        assertEq(weth.balanceOf(address(alice)), 100);
        vm.stopPrank();
    }

    function test8ApproveShouldGiveOtherAlowance() public {
        deal(bob, 100);
        vm.startPrank(bob);
        uint256 amount = 100;
        weth.deposit{value: amount}();
        (bool success, ) = address(weth).call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(alice),
                amount
            )
        );
        require(success, "approve successfully");
        assertEq(weth.allowance(address(bob), address(alice)), 100);
        console2.log(weth.allowance(address(bob), address(alice)));
        vm.stopPrank();
    }

    function test9TransferFromShouldAbleToUseOthersToken() public {
        deal(bob, 100);
        vm.startPrank(bob);
        uint256 amount = 100;
        weth.deposit{value: amount}();
        (bool success, ) = address(weth).call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(alice),
                amount
            )
        );
        require(success, "approve successfully");
        assertEq(weth.allowance(address(bob), address(alice)), 100);
        console2.log(
            "alice allowance =",
            weth.allowance(address(bob), address(alice))
        );
        assertEq(weth.balanceOf(address(bob)), 100);
        assertEq(weth.balanceOf(address(alice)), 0);
        vm.stopPrank();
        vm.startPrank(alice);
        console2.log("balance of alice", weth.balanceOf(alice));
        (success, ) = address(weth).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                address(bob),
                address(alice),
                amount
            )
        );
        require(success, "transferFrom successfully");
        assertEq(weth.balanceOf(address(bob)), 0);
        assertEq(weth.balanceOf(address(alice)), 100);
        console2.log("balance of alice", weth.balanceOf(alice));
        vm.stopPrank();
    }

    function test10TransferFromShouldAbleToUseOthersToken() public {
        deal(bob, 100);
        vm.startPrank(bob);
        uint256 amount = 100;
        weth.deposit{value: amount}();
        (bool success, ) = address(weth).call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(alice),
                amount
            )
        );
        require(success, "approve successfully");
        assertEq(weth.allowance(address(bob), address(alice)), 100);
        console2.log(
            "alice allowance =",
            weth.allowance(address(bob), address(alice))
        );
        assertEq(weth.balanceOf(address(bob)), 100);
        assertEq(weth.balanceOf(address(alice)), 0);
        vm.stopPrank();
        vm.startPrank(alice);
        console2.log("balance of alice", weth.balanceOf(alice));
        (success, ) = address(weth).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                address(bob),
                address(alice),
                50
            )
        );
        require(success, "transferFrom successfully");
        assertEq(weth.balanceOf(address(bob)), 50);
        assertEq(weth.balanceOf(address(alice)), 50);
        console2.log("balance of alice", weth.balanceOf(alice));
        console2.log("left approve amount", weth.allowance(bob, alice));
        vm.stopPrank();
    }
}
