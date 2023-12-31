// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {BlindBoxNFT} from "../../src/w7/blindBoxNFT.sol";

contract BlindBoxNFTTest is Test {
    BlindBoxNFT public blindBoxNFT;
    address public bob;
    address public alice;
    event Deposit(address indexed to, uint256 value);
    event Withdraw(address indexed from, uint256 value);

    function setUp() public {
        blindBoxNFT = new BlindBoxNFT(
            "ipfs://123/"
        );
        bob = makeAddr("bob");
        alice = makeAddr("alice");
    }

    function test1BlindBoxNFTShouldMintTokenToTokenOwner() public {
        uint256 tokenId = blindBoxNFT.mintToken(bob);
        assertEq(blindBoxNFT.balanceOf(bob), 1);
        assertEq(blindBoxNFT.ownerOf(tokenId), bob);
    }

    function test2BlindBoxNFTShouldChangeBaseURIWhenSetBaseURI() public {
        string
            memory baseURI = "ipfs://123/";
        uint256 tokenId = blindBoxNFT.mintToken(bob);
        assertEq(blindBoxNFT.balanceOf(bob), 1);
        assertEq(
            blindBoxNFT.tokenURI(tokenId),
            string.concat(baseURI, Strings.toString(tokenId))
        );

        assertEq(blindBoxNFT.getBaseURI(), baseURI);
        blindBoxNFT.setBaseURI("ipfs://456/");
        baseURI = "ipfs://456/";
        assertEq(blindBoxNFT.getBaseURI(), baseURI);
        console2.log("tokenURI", blindBoxNFT.tokenURI(tokenId));
        assertEq(
            blindBoxNFT.tokenURI(tokenId),
            string.concat(baseURI, Strings.toString(tokenId))
        );
    }
}
