// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Common_Test } from "test/CommonTest.t.sol";
import { UpgradeToExtendedOptimismMintableToken } from "script/UpgradeToExtendedOptimismMintableToken.s.sol";
import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";
import { ExtendedOptimismMintableToken } from "src/ExtendedOptimismMintableToken.sol";
import { UpgradeableOptimismMintableERC20 } from "src/UpgradeableOptimismMintableERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ILegacyMintableERC20, IOptimismMintableERC20 } from "@eth-optimism-bedrock/contracts/universal/IOptimismMintableERC20.sol";
import { IEIP3009 } from "src/eip-3009/IEIP3009.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

contract UpgradeToExtendedOptimismMintableToken_Test is Common_Test {    
    UpgradeToExtendedOptimismMintableToken upgraderImpl;

    function setUp() public virtual override {
        super.setUp();

        ExtendedOptimismMintableTokenProxy = new Proxy(admin);
        L2Token = ExtendedOptimismMintableToken(address(ExtendedOptimismMintableTokenProxy));

        bytes memory initializeCall = abi.encodeCall(
            UpgradeableOptimismMintableERC20.initialize, 
            (
                string(abi.encodePacked("L2-", L1Token.name())),
                string(abi.encodePacked("L2-", L1Token.symbol()))
            )
        );
        vm.prank(admin);
        ExtendedOptimismMintableTokenProxy.upgradeToAndCall(address(L2TokenImplV1), initializeCall);

        vm.setEnv("NEW_IMPLEMENTATION_ADDRESS", vm.toString(address(L2TokenImpl)));
        vm.setEnv("PROXY_ADDRESS", vm.toString(address(L2Token)));
        vm.setEnv("ADMIN_ADDRESS", vm.toString(admin));
        vm.setEnv("DEFAULT_ROLE_ADMIN_ADDRESS", vm.toString(rolesAdmin));
        vm.setEnv("PAUSER_ADDRESS", vm.toString(pauser));
        vm.setEnv("BLACKLISTER_ADDRESS", vm.toString(blacklister));
        
        upgraderImpl = new UpgradeToExtendedOptimismMintableToken();
    }

    function test_upgradeToExtendedOptimismMintableToken_success() external {
        address bridgePriorToUpgrade = L2Token.BRIDGE();
        address remoteTokenPriorToUpgrade = L2Token.REMOTE_TOKEN();
        string memory namePriorToUpgrade = L2Token.name();
        string memory symbolPriorToUpgrade = L2Token.symbol();
        uint8 decimalsPriorToUpgrade = L2Token.decimals();

        upgraderImpl.run();

        // Proxy assertions
        vm.prank(address(0));
        assertEq(ExtendedOptimismMintableTokenProxy.implementation(), address(L2TokenImpl));
        vm.prank(address(0));
        assertEq(ExtendedOptimismMintableTokenProxy.admin(), admin);

        // ExtendedOptimismMintableToken assertions
        // Check initialized version
        uint64 initializedVersion = uint64(uint(vm.load(
            address(L2Token),
             0
        )));
        assertEq(initializedVersion, 2);
        assertEq(L2Token.BRIDGE(), bridgePriorToUpgrade);
        assertEq(L2Token.bridge(), bridgePriorToUpgrade);
        assertEq(L2Token.l2Bridge(), bridgePriorToUpgrade);
        assertEq(L2Token.REMOTE_TOKEN(), remoteTokenPriorToUpgrade);
        assertEq(L2Token.remoteToken(), remoteTokenPriorToUpgrade);
        assertEq(L2Token.l1Token(), remoteTokenPriorToUpgrade);
        assertEq(L2Token.decimals(), decimalsPriorToUpgrade);
        assertEq(L2Token.name(), namePriorToUpgrade);
        assertEq(L2Token.symbol(), symbolPriorToUpgrade);
        assertTrue(L2Token.hasRole(DEFAULT_ADMIN_ROLE, rolesAdmin));
        assertTrue(L2Token.hasRole(PAUSER_ROLE, pauser));
        assertTrue(L2Token.hasRole(BLACKLISTER_ROLE, blacklister));   
        assertFalse(L2Token.paused());
        assertTrue(L2Token.supportsInterface(type(IERC165).interfaceId));
        assertTrue(L2Token.supportsInterface(type(ILegacyMintableERC20).interfaceId));
        assertTrue(L2Token.supportsInterface(type(IOptimismMintableERC20).interfaceId));
        assertTrue(L2Token.supportsInterface(type(IEIP3009).interfaceId));
        assertTrue(L2Token.supportsInterface(type(IERC20Permit).interfaceId));
    }
}
