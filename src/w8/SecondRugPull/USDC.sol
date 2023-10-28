// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;
import "forge-std/Test.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract usdcV2 {
    string public name;
    string public symbol;
    uint8 public decimals;
    string public currency;
    address public masterMinter;
    bool internal initialized;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal totalSupply_ = 0;
    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;
    uint256[50] internal _gap;

    mapping(address => bool) internal whitelist;
    bool public initializedV2 = false;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed oldMinter);
    event MasterMinterChanged(address indexed newMasterMinter);
    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier inWhitelist() {
        require(whitelist[msg.sender], "only in whitelist can perform action");
        _;
    }

    function initializeV2(address[] memory _whitelist) public {
        require(!initializedV2, "already initialized");
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
        }
        initializedV2 = true;
    }

    function mint(address _to, uint256 _amount) public inWhitelist {
        (, uint256 totalSupplyNum) = Math.tryAdd(totalSupply_, _amount);
        totalSupply_ = totalSupplyNum;
        (, uint256 balancesNum) = Math.tryAdd(balances[_to], _amount);
        balances[_to] = balancesNum;
        emit Mint(msg.sender, _to, _amount);
    }

    function burn(uint256 _amount) public inWhitelist {
        (, uint256 totalSupplyNum) = Math.trySub(totalSupply_, _amount);
        totalSupply_ = totalSupplyNum;
        (, uint256 balancesNum) = Math.trySub(balances[msg.sender], _amount);
        balances[msg.sender] = balancesNum;
        // totalSupply_ = Math.trySub(totalSupply_, _amount);
        // balances[msg.sender] = Math.trySub(balances[msg.sender], _amount);
        emit Burn(msg.sender, _amount);
    }

    function transfer(
        address _to,
        uint256 _value
    ) public inWhitelist returns (bool success) {
        require(_to != address(0), "cannot transfer to zero address");
        require(_value <= balances[msg.sender], "not enough balance");
        (, uint256 balancesNum) = Math.trySub(balances[msg.sender], _value);
        balances[msg.sender] = balancesNum;
        (, uint256 balancesNum2) = Math.tryAdd(balances[_to], _value);
        balances[_to] = balancesNum2;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public inWhitelist returns (bool success) {
        require(_to != address(0), "cannot transfer to zero address");
        require(_value <= balances[_from], "not enough balance");
        require(_value <= allowed[_from][msg.sender], "not enough allowance");
        (, uint256 balancesNum) = Math.trySub(balances[_from], _value);
        balances[_from] = balancesNum;
        (, uint256 balancesNum2) = Math.tryAdd(balances[_to], _value);
        balances[_to] = balancesNum2;
        (, uint256 allowedNum) = Math.trySub(
            allowed[_from][msg.sender],
            _value
        );
        allowed[_from][msg.sender] = allowedNum;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function VERSION() public pure returns (string memory) {
        return "usdcV2";
    }
}
