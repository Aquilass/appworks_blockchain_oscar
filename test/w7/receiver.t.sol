// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import {Test, console2} from "forge-std/Test.sol";

import {YESNFT} from "../../src/w7/YESNFT.sol";
import {NONFT} from "../../src/w7/NONFT.sol";
import {NFTReceiver} from "../../src/w7/Receiver.sol";

contract NFTReceiverTest is Test {
    YESNFT public yesnft;
    NONFT public nonft;
    NFTReceiver public nftReceiver;
    address public bob;
    address public alice;
    event Deposit(address indexed to, uint256 value);
    event Withdraw(address indexed from, uint256 value);

    function setUp() public {
        yesnft = new YESNFT();
        nonft = new NONFT();
        nftReceiver = new NFTReceiver(address(nonft));
        bob = makeAddr("bob");
        alice = makeAddr("alice");
    }

    function test1NOFNTShouldMintTokenToTokenOwner() public {
        uint256 tokenId = nonft.mintToken(bob);
        assertEq(nonft.balanceOf(bob), 1);
        assertEq(nonft.ownerOf(tokenId), bob);
    }

    function test2ReceiverShouldMintTokenToTokenOwner() public {
        uint256 tokenId = yesnft.mintToken(bob);
        assertEq(yesnft.balanceOf(bob), 1);
        assertEq(yesnft.ownerOf(tokenId), bob);
    }

    function test3ShouldMintNONFTToTokenOwnerWhenTransferYESNFT() public {
        vm.startPrank(bob);
        uint256 tokenId = yesnft.mintToken(bob);
        assertEq(yesnft.balanceOf(bob), 1);
        assertEq(yesnft.ownerOf(tokenId), bob);
        (bool success, ) = address(yesnft).call(
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", bob, address(nftReceiver), tokenId)
        );
        require(success, "transferFrom successfully");
        assertEq(yesnft.balanceOf(bob), 1);
        assertEq(yesnft.ownerOf(tokenId), bob);
        assertEq(nonft.balanceOf(bob), 1);
        vm.stopPrank(); 
        }
    function test4ShouldAcceptNONFT() public{
        vm.startPrank(bob);
        uint256 tokenId = nonft.mintToken(bob);
        assertEq(nonft.balanceOf(bob), 1);
        assertEq(nonft.ownerOf(tokenId), bob);
        (bool success, ) = address(nonft).call(
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", bob, address(nftReceiver), tokenId)
        );
        require(success, "transferFrom successfully");
        assertEq(nonft.balanceOf(bob), 0);
        assertEq(nonft.ownerOf(tokenId), address(nftReceiver));
        assertEq(yesnft.balanceOf(bob), 0);
        vm.stopPrank();
    }
}