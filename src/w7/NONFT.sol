// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NONFT is ERC721URIStorage {
    uint256 private _nextTokenId;

    constructor() ERC721("Dont send NFT to me", "NONFT") {}

    function mintToken(address receiver) public returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _setTokenURI(
            tokenId,
            "ipfs://Qmatro4y1HKUypWMuVWnn6fAzFk2oadAkBZHPmzowK8epN"
        );
        _mint(receiver, tokenId);
        return tokenId;
    }
}
