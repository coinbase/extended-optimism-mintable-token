// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Common_Test } from "test/CommonTest.t.sol";
import { DeployExtendedOptimismMintableTokenImpl } from "script/DeployExtendedOptimismMintableTokenImpl.s.sol";
import { ExtendedOptimismMintableToken } from "src/ExtendedOptimismMintableToken.sol";

contract DeployExtendedOptimismMintableTokenImpl_Test is Common_Test {    
    DeployExtendedOptimismMintableTokenImpl deployerImpl;

    function setUp() public virtual override {
        super.setUp();

        vm.setEnv("PROXY_ADDRESS", vm.toString(address(L2Token)));
        deployerImpl = new DeployExtendedOptimismMintableTokenImpl();
    }

    function test_deployExtendedOptimismMintableTokenImpl_sucess() external {
        L2TokenImpl = ExtendedOptimismMintableToken(deployerImpl.run());

        assertEq(L2TokenImpl.BRIDGE(), L2Token.BRIDGE());
        assertEq(L2TokenImpl.REMOTE_TOKEN(), L2Token.REMOTE_TOKEN());
        assertEq(L2TokenImpl.decimals(), L2Token.decimals());      
    }
}
