// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Test } from "forge-std/Test.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { L2CrossDomainMessenger } from "@eth-optimism-bedrock/contracts/L2/L2CrossDomainMessenger.sol";
import { CrossDomainMessenger } from "@eth-optimism-bedrock/contracts/universal/CrossDomainMessenger.sol";
import { L2StandardBridge } from "@eth-optimism-bedrock/contracts/L2/L2StandardBridge.sol";
import { StandardBridge } from "@eth-optimism-bedrock/contracts/universal/StandardBridge.sol";
import { Predeploys } from "@eth-optimism-bedrock/contracts/libraries/Predeploys.sol";
import { ILegacyMintableERC20, IOptimismMintableERC20 } from "@eth-optimism-bedrock/contracts/universal/IOptimismMintableERC20.sol";
import { AddressAliasHelper } from "@eth-optimism-bedrock/contracts/vendor/AddressAliasHelper.sol";
import { Encoding } from "@eth-optimism-bedrock/contracts/libraries/Encoding.sol";
import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";
import { UpgradeableOptimismMintableERC20 } from "src/UpgradeableOptimismMintableERC20.sol";

contract UpgradeableOptimismMintableERC20_Test is Test {
    event Initialized(uint8 version);
    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);

    uint8 constant DECIMALS = 6;
    uint256 constant BASE_MAINNET_BLOCK = 100;
    address constant L1_STANDARD_BRIDGE = 0x3154Cf16ccdb4C6d922629664174b904d80F2C35;
    address constant L1_CROSS_DOMAIN_MESSENGER = 0x866E82a600A1414e583f7F13623F1aC5d58b0Afa;
    uint32 constant MIN_GAS_LIMIT = 100_000;
    uint256 constant ZERO_VALUE = 0;

    address L2_ALIASED_L1_CROSS_DOMAIN_MESSENGER = AddressAliasHelper.applyL1ToL2Alias(L1_CROSS_DOMAIN_MESSENGER);
    string BASE_MAINNET_URL = vm.envString("BASE_MAINNET_URL");

    address admin = address(56);
    address alice = address(128);
    address bob = address(256);
    L2StandardBridge l2Bridge;
    ERC20 l1Token;
    UpgradeableOptimismMintableERC20 l2TokenImpl;
    UpgradeableOptimismMintableERC20 l2Token;
    Proxy proxy;
    string name;
    string symbol;
    bytes initializeCall;

    function setUp() public virtual {
        vm.createSelectFork(BASE_MAINNET_URL, BASE_MAINNET_BLOCK);

        l2Bridge = L2StandardBridge(payable(Predeploys.L2_STANDARD_BRIDGE));
        l1Token = new ERC20("Native L1 Token", "L1T");
        name = string(abi.encodePacked("L2-", l1Token.name()));
        symbol = string(abi.encodePacked("L2-", l1Token.symbol()));
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

    function test_bridgeDeposit_success(uint256 _transferAmount) external {
        uint256 nonce = Encoding.encodeVersionedNonce(0, 1);

        bytes memory message = abi.encodeWithSelector(
                StandardBridge.finalizeBridgeERC20.selector,
                l2Token,
                l1Token,
                alice,
                alice,
                _transferAmount,
                bytes("")
        );

        assertEq(l2Token.balanceOf(alice), 0);
        vm.prank(L2_ALIASED_L1_CROSS_DOMAIN_MESSENGER);
        L2CrossDomainMessenger(Predeploys.L2_CROSS_DOMAIN_MESSENGER).relayMessage(
            nonce,
            L1_STANDARD_BRIDGE,
            Predeploys.L2_STANDARD_BRIDGE,
            ZERO_VALUE,
            MIN_GAS_LIMIT,
            message
        );

        assertEq(l2Token.balanceOf(alice), _transferAmount);
    }

    function test_bridgeWithdraw_success(uint256 _transferAmount) external {
        bytes memory withdrawalMessage = abi.encodeWithSelector(
                StandardBridge.finalizeBridgeERC20.selector,
                l1Token,
                l2Token,
                alice,
                alice,
                _transferAmount,
                bytes("")
        );
        bytes memory crossDomainMessage = abi.encodeWithSelector(
            CrossDomainMessenger.sendMessage.selector,
            L1_STANDARD_BRIDGE,
            withdrawalMessage,
            MIN_GAS_LIMIT
        );

        vm.prank(payable(Predeploys.L2_STANDARD_BRIDGE));
        l2Token.mint(alice, _transferAmount);
     
        assertEq(l2Token.balanceOf(alice), _transferAmount);
        vm.expectCall(
            Predeploys.L2_CROSS_DOMAIN_MESSENGER,
            ZERO_VALUE,
            crossDomainMessage
        );
        vm.prank(alice);
        L2StandardBridge(payable(Predeploys.L2_STANDARD_BRIDGE)).withdraw(
            address(l2Token),
            _transferAmount,
            MIN_GAS_LIMIT,
            bytes("")
        );
        assertEq(l2Token.balanceOf(alice), 0);
    }
}
