// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BlindBoxNFT is ERC721URIStorage {
    uint256 public constant totalSupply = 500;
    uint256 public currentSupply = 0;
    address private _owner;
    string private baseURI;

    constructor(string memory _baseURI) ERC721("BlindBoxNFT", "BBNFT") {
        _owner = msg.sender;
        baseURI = _baseURI;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function.");
        _;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function randonNumberGenerator() public view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, address(this), msg.sender)
            )
        ) % 500;
        return randomNumber;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function mintToken(address receiver) public returns (uint256) {
        uint256 tokenId = randonNumberGenerator();
        require(_ownerOf(tokenId) == address(0), "Token already minted");
        require(currentSupply < totalSupply, "All tokens minted");
        _safeMint(receiver, tokenId);
        currentSupply++;
        return tokenId;
    }
}
