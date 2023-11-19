// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTReceiver is IERC721Receiver{
    address public NOFNT;
    constructor(address _NOFNT){
        NOFNT = _NOFNT;
    }
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public override returns (bytes4){
        if (msg.sender == NOFNT){
            return this.onERC721Received.selector;
        } else {
            (bool success1,) = address(NOFNT).call(abi.encodeWithSignature("mintToken(address)", from));
            require(success1, "mintToken to token owner successfully");
            (bool success2,) = address(msg.sender).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), from, tokenId));
            require(success2, "transferFrom to token owner successfully");
            return this.onERC721Received.selector;
        }
    }
}