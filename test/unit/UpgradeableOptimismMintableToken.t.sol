// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Test } from "forge-std/Test.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { L2StandardBridge } from "@eth-optimism-bedrock/contracts/L2/L2StandardBridge.sol";
import { Predeploys } from "@eth-optimism-bedrock/contracts/libraries/Predeploys.sol";
import { ILegacyMintableERC20, IOptimismMintableERC20 } from "@eth-optimism-bedrock/contracts/universal/IOptimismMintableERC20.sol";
import { UpgradeableOptimismMintableERC20V2 } from "test/fakes/UpgradeableOptimismMintableERC20V2.sol";
import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";
import { UpgradeableOptimismMintableERC20 } from "src/UpgradeableOptimismMintableERC20.sol";

contract UpgradeableOptimismMintableERC20_Test is Test {
    event Initialized(uint8 version);
    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);

    uint8 constant DECIMALS = 6;

    address admin = address(56);
    address alice = address(128);
    L2StandardBridge l2Bridge;
    ERC20 l1Token;
    UpgradeableOptimismMintableERC20 l2TokenImpl;
    UpgradeableOptimismMintableERC20 l2Token;
    Proxy proxy;
    string name;
    string symbol;
    bytes initializeCall;
    uint8 initializedVersion;

    function setUp() public virtual {
        l2Bridge = L2StandardBridge(payable(Predeploys.L2_STANDARD_BRIDGE));
        l1Token = new ERC20("Native L1 Token", "L1T");
        name = string(abi.encodePacked("L2-", l1Token.name()));
        symbol = string(abi.encodePacked("L2-", l1Token.symbol()));
        initializedVersion = 1;
        l2TokenImpl = new UpgradeableOptimismMintableERC20(
            address(l2Bridge),
            address(l1Token),
            DECIMALS
        );

        proxy = new Proxy(admin);

        initializeCall = abi.encodeCall(
            UpgradeableOptimismMintableERC20.initialize, 
            (name, symbol)
        );

        vm.prank(admin);
        proxy.upgradeToAndCall(address(l2TokenImpl), initializeCall);

        l2Token = UpgradeableOptimismMintableERC20(address(proxy));
    }

    function test_upgradeToAndCall_contractUpgrade_succeeds() external {
        UpgradeableOptimismMintableERC20V2 l2TokenImplV2 = new UpgradeableOptimismMintableERC20V2();
        uint8 initializedVersion2 = 2;
        bytes memory initializeV2Call = abi.encodeCall(
            UpgradeableOptimismMintableERC20V2.initialize, 
            (initializedVersion2)
        );

        proxy = new Proxy(admin);
        vm.expectEmit(true, true, true, true, address(proxy));
        emit Initialized(initializedVersion);
        vm.prank(admin);
        proxy.upgradeToAndCall(address(l2TokenImpl), initializeCall);
        vm.expectEmit(true, true, true, true, address(proxy));
        emit Initialized(initializedVersion2);
        vm.prank(admin);
        proxy.upgradeToAndCall(address(l2TokenImplV2), initializeV2Call);

        l2Token = UpgradeableOptimismMintableERC20(address(proxy));
        assertEq(l2Token.name(), name);
        assertEq(l2Token.symbol(), symbol);
    }

    function test_initialize_succeeds() external {
        l2TokenImpl = new UpgradeableOptimismMintableERC20(
            address(l2Bridge),
            address(l1Token),
            DECIMALS
        );

        proxy = new Proxy(admin);

        vm.expectEmit(true, true, true, true, address(proxy));
        emit Initialized(initializedVersion);
        vm.prank(admin);
        proxy.upgradeToAndCall(address(l2TokenImpl), initializeCall);
        l2Token = UpgradeableOptimismMintableERC20(address(proxy));
        
        assertEq(l2Token.name(), name);
        assertEq(l2Token.symbol(), symbol);
    }

    function test_initialize_calledTwice_reverts() external {
        vm.expectRevert(
            "Initializable: contract is already initialized"
        );
        l2Token.initialize(
            name, symbol
        );
    }

    function test_initialize_onImplementation_reverts() external {
        l2TokenImpl = new UpgradeableOptimismMintableERC20(
            address(l2Bridge),
            address(l1Token),
            DECIMALS
        );

        vm.expectRevert(
            "Initializable: contract is already initialized"
        );
        l2Token.initialize(
            name, symbol
        );
    }

     function test_remote_succeeds() external {
        assertEq(l2Token.decimals(), DECIMALS);
    }

    function test_remoteToken_succeeds() external {
        assertEq(l2Token.remoteToken(), address(l1Token));
    }

    function test_bridge_succeeds() external {
        assertEq(l2Token.bridge(), address(l2Bridge));
    }

    function test_l1Token_succeeds() external {
        assertEq(l2Token.l1Token(), address(l1Token));
    }

    function test_l2Bridge_succeeds() external {
        assertEq(l2Token.l2Bridge(), address(l2Bridge));
    }

    function test_legacy_succeeds() external {
        // Getters for the remote token
        assertEq(l2Token.REMOTE_TOKEN(), address(l1Token));
        assertEq(l2Token.remoteToken(), address(l1Token));
        assertEq(l2Token.l1Token(), address(l1Token));
        // Getters for the bridge
        assertEq(l2Token.BRIDGE(), address(l2Bridge));
        assertEq(l2Token.bridge(), address(l2Bridge));
        assertEq(l2Token.l2Bridge(), address(l2Bridge));
    }

    function test_mint_succeeds() external {
        vm.expectEmit(true, true, true, true);
        emit Mint(alice, 100);

        vm.prank(address(l2Bridge));
        l2Token.mint(alice, 100);

        assertEq(l2Token.balanceOf(alice), 100);
    }

    function test_mint_notBridge_reverts() external {
        // NOT the bridge
        vm.expectRevert("OptimismMintableERC20: only bridge can mint and burn");
        vm.prank(address(alice));
        l2Token.mint(alice, 100);
    }

    function test_burn_succeeds() external {
        vm.prank(address(l2Bridge));
        l2Token.mint(alice, 100);

        vm.expectEmit(true, true, true, true);
        emit Burn(alice, 100);

        vm.prank(address(l2Bridge));
        l2Token.burn(alice, 100);

        assertEq(l2Token.balanceOf(alice), 0);
    }

    function test_burn_notBridge_reverts() external {
        // NOT the bridge
        vm.expectRevert("OptimismMintableERC20: only bridge can mint and burn");
        vm.prank(address(alice));
        l2Token.burn(alice, 100);
    }

    function test_erc165_supportsInterface_succeeds() external {
        // The assertEq calls in this test are comparing the manual calculation of the iface,
        // with what is returned by the solidity's type().interfaceId, just to be safe.
        bytes4 iface1 = bytes4(keccak256("supportsInterface(bytes4)"));
        assertEq(iface1, type(IERC165Upgradeable).interfaceId);
        assert(l2Token.supportsInterface(iface1));

        bytes4 iface2 = l2Token.l1Token.selector ^ l2Token.mint.selector ^ l2Token.burn.selector;
        assertEq(iface2, type(ILegacyMintableERC20).interfaceId);
        assert(l2Token.supportsInterface(iface2));

        bytes4 iface3 = l2Token.remoteToken.selector ^
            l2Token.bridge.selector ^
            l2Token.mint.selector ^
            l2Token.burn.selector;
        assertEq(iface3, type(IOptimismMintableERC20).interfaceId);
        assert(l2Token.supportsInterface(iface3));
    }
}
