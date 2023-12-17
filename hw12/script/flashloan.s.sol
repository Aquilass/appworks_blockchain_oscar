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
import {CToken} from "compound-protocol/CToken.sol";

// script usage:
// deploy local fork of mainnet
// forge script script/compound.s.sol:DeployCompound
// deploy to sepolia ( need to set SEPOLIA_RPC_URL and PRIVATE_KEY and ADMIN_ACCOUNT and Etherscan API key in env )
// forge script script/compound.s.sol:DeployCompound --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
contract DeployCompound is Script {
    address oscarToken2Address;
    address oscarTokenAddress;
    address adminAddress;
    address oracleAddress;
    address payable cUSDCAddress;
    address payable cUNIAddress;
    address unitrollerAddress;

    // address public USDC;
    // ERC20 public usdc;
    // address public UNI;
    // ERC20 public uni;

    function setUp() public virtual {
        //create a new fork from mainnet
        //Fork Ethereum mainnet at block 17465000(Reference)
        uint256 forkId = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 17465000);
        
        //create a new fork from sepolia
        // uint256 forkId = vm.createFork(vm.envString("SEPOLIA_RPC_URL"));
        vm.selectFork(forkId);
        // vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        

        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        ERC20 usdc = ERC20(USDC);
        address UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
        ERC20 uni = ERC20(UNI);

        // local admin account
        address _admin = makeAddr("admin");
        address payable admin = payable(_admin);
        adminAddress = admin;
        // sepolia admin account
        // string memory _admin = vm.envString("ADMIN_ACCOUNT");
        // address payable admin = payable(vm.parseAddress(_admin));
        vm.startPrank(admin);

        // oracle
        SimplePriceOracle oracle = new SimplePriceOracle();
        oracleAddress = address(oracle);
        // comptroller
        ComptrollerG7 comptroller = new ComptrollerG7();
        comptroller._setPriceOracle(oracle);
        ComptrollerInterface comptrollerInterface = ComptrollerInterface(address(comptroller));
        // unitroller
        Unitroller unitroller = new Unitroller();
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);
        ComptrollerG7(address(unitroller))._setPriceOracle(oracle);
        unitrollerAddress = address(unitroller);
        // interest rate model
        WhitePaperInterestRateModel whiteInterestRateModel = new WhitePaperInterestRateModel(0, 0);
        InterestRateModel interestRateModel = InterestRateModel(address(whiteInterestRateModel));
        // oscarToken underlying token
        OscarToken oscarToken = new OscarToken("OscarToken", "OTK");
        OscarToken oscarToken2 = new OscarToken("OscarToken2", "OTK2");
        oscarTokenAddress = address(oscarToken);
        oscarToken2Address = address(oscarToken2);
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
        CErc20Delegator cUSDC = new CErc20Delegator(
            address(USDC),
            ComptrollerG7(address(unitroller)),
            interestRateModel,
            1e6, // initialExchangeRateMantissa 1:1
            "USDC Compound",
            "cUSDC",
            18,
            admin,
            address(cErc20Delegate),
            ""
        );
        CErc20Delegator cUNI = new CErc20Delegator(
            address(UNI),
            ComptrollerG7(address(unitroller)),
            interestRateModel,
            1e18, // initialExchangeRateMantissa 1:1
            "UNI Compound",
            "cUNI",
            18,
            admin,
            address(cErc20Delegate),
            ""
        );
        // add underlying token to oracle
        cUSDCAddress = payable(address(cUSDC));
        cUNIAddress = payable(address(cUNI));
        vm.stopPrank();
        // vm.stopBroadcast();
    }
    // function run() external {
    //     //create a new fork from mainnet
    //     uint256 forkId = vm.createFork(vm.envString("MAINNET_RPC_URL"));
    //     //create a new fork from sepolia
    //     // uint256 forkId = vm.createFork(vm.envString("SEPOLIA_RPC_URL"));
    //     vm.selectFork(forkId);
    //     vm.startBroadcast(vm.envUint("PRIVATE_KEY"));


    //     // local admin account
    //     address _admin = makeAddr("admin");
    //     address payable admin = payable(_admin);
    //     // sepolia admin account
    //     // string memory _admin = vm.envString("ADMIN_ACCOUNT");
    //     // address payable admin = payable(vm.parseAddress(_admin));

    //     // oracle
    //     SimplePriceOracle oracle = new SimplePriceOracle();
    //     // comptroller
    //     ComptrollerG7 comptroller = new ComptrollerG7();
    //     comptroller._setPriceOracle(oracle);
    //     ComptrollerInterface comptrollerInterface = ComptrollerInterface(address(comptroller));
    //     // unitroller
    //     Unitroller unitroller = new Unitroller();
    //     unitroller._setPendingImplementation(address(comptroller));
    //     comptroller._become(unitroller);
    //     ComptrollerG7(address(unitroller))._setPriceOracle(oracle);
    //     // interest rate model
    //     WhitePaperInterestRateModel whiteInterestRateModel = new WhitePaperInterestRateModel(0, 0);
    //     InterestRateModel interestRateModel = InterestRateModel(address(whiteInterestRateModel));
    //     // oscarToken underlying token
    //     OscarToken oscarToken = new OscarToken("OscarToken", "OTK");
    //     OscarToken oscarToken2 = new OscarToken("OscarToken2", "OTK2");
    //     // cErc20Delegate
    //     CErc20Delegate cErc20Delegate = new CErc20Delegate();
    //     // cErc20Delegator constructor arguments
    //     // address underlying_,
    //     // ComptrollerInterface comptroller_,
    //     // InterestRateModel interestRateModel_,
    //     // uint initialExchangeRateMantissa_,
    //     // string memory name_,
    //     // string memory symbol_,
    //     // uint8 decimals_,
    //     // address payable admin_,
    //     // address implementation_,
    //     // bytes memory becomeImplementationData
    //     CErc20Delegator cUSDC = new CErc20Delegator(
    //         address(oscarToken),
    //         ComptrollerG7(address(unitroller)),
    //         interestRateModel,
    //         1, // initialExchangeRateMantissa 1:1
    //         "OscarCompound",
    //         "OCD",
    //         18,
    //         admin,
    //         address(cErc20Delegate),
    //         ""
    //     );
    //     CErc20Delegator cUNI = new CErc20Delegator(
    //         address(oscarToken2),
    //         ComptrollerG7(address(unitroller)),
    //         interestRateModel,
    //         1, // initialExchangeRateMantissa 1:1
    //         "OscarCompound",
    //         "OCD",
    //         18,
    //         admin,
    //         address(cErc20Delegate),
    //         ""
    //     );
    //     vm.stopBroadcast();
    // }
}