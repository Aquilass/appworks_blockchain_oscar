// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;
import {Test, console2} from "forge-std/Test.sol";
import "forge-std/Test.sol";
import "ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract ERC721AGasOptimizationTest is Test {
    // Owner and users
    address owner = address(0x807a96288A1A408dBC13DE2b1d087d10356395d2);
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    ERC721ATest public erc721a;
    ERC721EnumerableTest public erc721Enumerable;

    function setUp() public {
        erc721a = new ERC721ATest();
        erc721Enumerable = new ERC721EnumerableTest();
    }
    // 嘗試用 test case 比較 Enumerable 和 ERC721A 的各個 function
    // mint
    // transfer
    // approve
    // 請用 gas report 來 print 出比較的結果

    function testERC721AMintCost() public{
        vm.startPrank(user1);
        erc721a.mint(user1, 1);
        vm.stopPrank();
    }
    function testERC721EnumerableMintCost() public{
        vm.startPrank(user1);
        erc721Enumerable.mint(user1);
        vm.stopPrank();
    }
    function testERC721MultipleMintCost() public{
        vm.startPrank(user1);
        erc721a.multipleMint(user1, 30);
        vm.stopPrank();
    }
    function testERC721EnumerableMultipleMintCost() public{
        vm.startPrank(user1);
        erc721Enumerable.multipleMint(user1, 30);
        vm.stopPrank();
    }
    function testERC721ATransferCost() public{
        vm.startPrank(user1);
        erc721a.mint(user1, 1);
        erc721a.transferFrom(user1, user2, 0);
        vm.stopPrank();
    }
    function testERC721EnumerableTransferCost() public{
        vm.startPrank(user1);
        erc721Enumerable.mint(user1);
        erc721Enumerable.transferFrom(user1, user2, 0);
        vm.stopPrank();
    }
    function testERC721AApproveCost() public{
        vm.startPrank(user1);
        erc721a.mint(user1, 1);
        erc721a.approve(user2, 0);
        vm.stopPrank();
    }
    function testERC721EnumerableApproveCost() public{
        vm.startPrank(user1);
        erc721Enumerable.mint(user1);
        erc721Enumerable.approve(user2, 0);
        vm.stopPrank();
    }
}
contract ERC721EnumerableTest is ERC721Enumerable {
    constructor() ERC721("testERC721Eum", "test721Enum") {}

    function mint(address _to) external payable {
        _mint(_to, totalSupply());
    }
    function multipleMint(address _to, uint256 _quantity) external payable {
        for(uint256 i = 0; i < _quantity; i++){
            _mint(_to, totalSupply());
        }
    }
}
contract ERC721ATest is ERC721A{
    constructor() ERC721A("testERC721A", "testERC721A") {}

    function mint(address _to, uint256 _quantity) external payable {
        _mint(_to, _quantity);
    }
    function multipleMint(address _to, uint256 _quantity) external payable {
        _mint(_to, _quantity);
    }
}
