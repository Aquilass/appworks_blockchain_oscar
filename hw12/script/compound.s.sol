pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT

import "forge-std/Script.sol";
import { ComptrollerG7 } from "compound-protocol/ComptrollerG7.sol";
import {SimplePriceOracle} from "compound-protocol/SimplePriceOracle.sol";
import {Unitroller} from "compound-protocol/Unitroller.sol";
import {WhitePaperInterestRateModel} from "compound-protocol/WhitePaperInterestRateModel.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {CErc20Delegate} from "compound-protocol/CErc20Delegate.sol";
import {OscarToken} from "../src/OscarToken.sol";
import {ComptrollerInterface} from "compound-protocol/ComptrollerInterface.sol";
import {InterestRateModel} from "compound-protocol/InterestRateModel.sol";
import {CErc20Delegator} from "compound-protocol/CErc20Delegator.sol";
contract DeployCompound is Script {
    function run() external {
        //create a new fork from mainnet
        uint256 forkId = vm.createFork(vm.envString("MAINNET_RPC_URL"));
        vm.selectFork(forkId);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));


        // admin
        address _admin = makeAddr("admin");
        address payable admin = payable(_admin);

        // oracle
        SimplePriceOracle oracle = new SimplePriceOracle();
        // comptroller
        ComptrollerG7 comptroller = new ComptrollerG7();
        comptroller._setPriceOracle(oracle);
        ComptrollerInterface comptrollerInterface = ComptrollerInterface(address(comptroller));
        // unitroller
        Unitroller unitroller = new Unitroller();
        unitroller._setPendingImplementation(address(comptroller));
        unitroller._acceptImplementation();
        // interest rate model
        WhitePaperInterestRateModel whiteInterestRateModel = new WhitePaperInterestRateModel(0, 0);
        InterestRateModel interestRateModel = InterestRateModel(address(whiteInterestRateModel));
        // oscarToken underlying token
        OscarToken oscarToken = new OscarToken();
        // cErc20Delegate
        CErc20Delegate cErc20Delegate = new CErc20Delegate();
        // cErc20Delegator constructor arguments
        // address underlying_,
        // ComptrollerInterface comptroller_,
        // InterestRateModel interestRateModel_,
        // uint initialExchangeRateMantissa_,
        // string memory name_,
        // string memory symbol_,
        // uint8 decimals_,
        // address payable admin_,
        // address implementation_,
        // bytes memory becomeImplementationData
        CErc20Delegator cErc20Delegator = new CErc20Delegator(
            address(oscarToken),
            comptrollerInterface,
            interestRateModel,
            1, // initialExchangeRateMantissa 1:1
            "OscarCompound",
            "OCD",
            18,
            admin,
            address(cErc20Delegate),
            ""
        );
        vm.stopBroadcast();
    }

}