// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import { Test } from "forge-std/Test.sol";
import { L2StandardBridge } from "@eth-optimism-bedrock/contracts/L2/L2StandardBridge.sol";
import "forge-std/console.sol";
import { Predeploys } from "@eth-optimism-bedrock/contracts/libraries/Predeploys.sol";
import { ILegacyMintableERC20, IOptimismMintableERC20 } from "@eth-optimism-bedrock/contracts/universal/IOptimismMintableERC20.sol";
import {
     IEIP3009
} from "src/eip-3009/IEIP3009.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";
import { ExtendedOptimismMintableToken } from "src/ExtendedOptimismMintableToken.sol";
import { UpgradeableOptimismMintableERC20 } from "src/UpgradeableOptimismMintableERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
// for testing
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract Common_Test is Test {    
    event Initialized(uint8 _version);

    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    address admin = address(56);
    address alice = address(128);
    address rolesAdmin = address(500);
    address pauser = address(256);
    address blacklister = address(512);
    uint8 constant DECIMALS = 6;
    uint8 initializedVersion = 1;

    L2StandardBridge L2Bridge;
    ERC20 L1Token;
    ExtendedOptimismMintableToken L2TokenImpl;
    UpgradeableOptimismMintableERC20 L2TokenImplV1;
    ExtendedOptimismMintableToken L2Token;
    Proxy ExtendedOptimismMintableTokenProxy;

    // roles
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant PAUSER_ROLE = keccak256("roles.pauser");
    bytes32 public constant BLACKLISTER_ROLE = keccak256("roles.blacklister");

    function setUp() public virtual {
        L2Bridge = L2StandardBridge(payable(Predeploys.L2_STANDARD_BRIDGE));
        L1Token = new ERC20("Native L1 Token", "L1T");
        L2TokenImplV1 = new UpgradeableOptimismMintableERC20(
            address(L2Bridge),
            address(L1Token),
            DECIMALS
        );
        L2TokenImpl = new ExtendedOptimismMintableToken(
            address(L2Bridge),
            address(L1Token),
            DECIMALS
        );

        ExtendedOptimismMintableTokenProxy = new Proxy(admin);

        string memory name = string(abi.encodePacked("L2-", L1Token.name()));

        bytes memory initializeCall = abi.encodeWithSelector(
            L2TokenImpl.initialize.selector,
            name,
            string(abi.encodePacked("L2-", L1Token.symbol()))
        );

        vm.prank(admin);
        ExtendedOptimismMintableTokenProxy.upgradeToAndCall(address(L2TokenImpl), initializeCall);

        L2Token = ExtendedOptimismMintableToken(address(ExtendedOptimismMintableTokenProxy));
        
        vm.prank(admin);
        L2Token.initializeV2(name, rolesAdmin);

        // Set up roles
        vm.prank(rolesAdmin);
        L2Token.grantRole(PAUSER_ROLE, pauser);
        vm.prank(rolesAdmin);
        L2Token.grantRole(BLACKLISTER_ROLE, blacklister);
    }

    // Helpers
    function addressToString(address a) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(a)), 20);
    }

    function roleToString(bytes32 r) internal pure returns (string memory) {
        return Strings.toHexString(uint256(r), 32);
    }
}
