// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract usdcV2 is ERC20 {
    function VERSION() public pure returns (string memory) {
        return "usdcV2";
    }
}
