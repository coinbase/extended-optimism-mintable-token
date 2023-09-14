// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Common_Test } from "test/CommonTest.t.sol";
import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";
import { ExtendedOptimismMintableToken } from "src/ExtendedOptimismMintableToken.sol";
import { DeployExtendedOptimismMintableToken } from "script/DeployExtendedOptimismMintableToken.s.sol";
import { Predeploys } from "@eth-optimism-bedrock/contracts/libraries/Predeploys.sol";

contract DeployExtendedOptimismMintableToken_Test is Common_Test {    
    DeployExtendedOptimismMintableToken deployer;

    function setUp() public virtual override {
        super.setUp();

        ExtendedOptimismMintableTokenProxy = new Proxy(admin);
        L2Token = ExtendedOptimismMintableToken(address(ExtendedOptimismMintableTokenProxy));

        vm.setEnv("ADMIN", vm.toString(admin));
        vm.setEnv("OWNER", vm.toString(owner));
        vm.setEnv("PAUSER", vm.toString(pauser));
        vm.setEnv("BLACKLISTER", vm.toString(blacklister));
        vm.setEnv("DECIMALS", vm.toString(DECIMALS));

        deployer = new DeployExtendedOptimismMintableToken();
    }

    function test_deployExtendedOptimismMintableToken_sucess() external {
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
        assertEq(L2Token.BRIDGE(), Predeploys.L2_STANDARD_BRIDGE);
        assertEq(L2Token.REMOTE_TOKEN(), vm.envAddress("REMOTE_TOKEN"));
        assertEq(L2Token.decimals(), DECIMALS);
        assertEq(L2Token.name(), vm.envString("NAME"));
        assertEq(L2Token.symbol(), vm.envString("SYMBOL"));
        assertTrue(L2Token.hasRole(DEFAULT_ADMIN_ROLE, owner));
        assertTrue(L2Token.hasRole(PAUSER_ROLE, pauser));
        assertTrue(L2Token.hasRole(BLACKLISTER_ROLE, blacklister));   
        assertFalse(L2Token.paused());

    }
}
