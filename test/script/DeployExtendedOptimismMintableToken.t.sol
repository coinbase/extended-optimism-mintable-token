// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Common_Test } from "test/CommonTest.t.sol";
import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";
import { ExtendedOptimismMintableToken } from "src/ExtendedOptimismMintableToken.sol";
import { DeployExtendedOptimismMintableToken } from "script/DeployExtendedOptimismMintableToken.s.sol";
import { Predeploys } from "@eth-optimism-bedrock/contracts/libraries/Predeploys.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ILegacyMintableERC20, IOptimismMintableERC20 } from "@eth-optimism-bedrock/contracts/universal/IOptimismMintableERC20.sol";
import { IEIP3009 } from "src/eip-3009/IEIP3009.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

contract DeployExtendedOptimismMintableToken_Test is Common_Test {    
    DeployExtendedOptimismMintableToken deployer;

    function setUp() public virtual override {
        super.setUp();

        ExtendedOptimismMintableTokenProxy = new Proxy(admin);
        L2Token = ExtendedOptimismMintableToken(address(ExtendedOptimismMintableTokenProxy));

        vm.setEnv("ADMIN", vm.toString(admin));
        vm.setEnv("PAUSER", vm.toString(pauser));
        vm.setEnv("BLACKLISTER", vm.toString(blacklister));
        vm.setEnv("REMOTE_TOKEN", vm.toString(address(99)));
        vm.setEnv("NAME", "Test");
        vm.setEnv("SYMBOL", "TST");
        vm.setEnv("DEFAULT_ROLE_ADMIN", vm.toString(rolesAdmin));
        vm.setEnv("DECIMALS", vm.toString(DECIMALS));

        deployer = new DeployExtendedOptimismMintableToken();
    }

    function test_deployExtendedOptimismMintableToken_success() external {
        L2Token = ExtendedOptimismMintableToken(deployer.run());

        // Proxy assertions
        // Check admin
        bytes32 adminSlot = vm.load(
            address(L2Token),
            // Encoding of admin address https://eips.ethereum.org/EIPS/eip-1967#admin-address
            bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
        );
        assertEq(adminSlot, bytes32(uint256(uint160(address(admin)))));
        
        // ExtendedOptimismMintableToken assertions
        // Check initialized version
        uint64 initializedVersion = uint64(uint(vm.load(
            address(L2Token),
             0
        )));
        assertEq(initializedVersion, 2);
        assertEq(L2Token.BRIDGE(), Predeploys.L2_STANDARD_BRIDGE);
        assertEq(L2Token.REMOTE_TOKEN(), vm.envAddress("REMOTE_TOKEN"));
        assertEq(L2Token.decimals(), DECIMALS);
        assertEq(L2Token.name(), vm.envString("NAME"));
        assertEq(L2Token.symbol(), vm.envString("SYMBOL"));
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
