// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Common_Test } from "test/CommonTest.t.sol";
import { DeployExtendedOptimismMintableTokenImpl } from "script/DeployExtendedOptimismMintableTokenImpl.s.sol";
import { ExtendedOptimismMintableToken } from "src/ExtendedOptimismMintableToken.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ILegacyMintableERC20, IOptimismMintableERC20 } from "@eth-optimism-bedrock/contracts/universal/IOptimismMintableERC20.sol";
import { IEIP3009 } from "src/eip-3009/IEIP3009.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

contract DeployExtendedOptimismMintableTokenImpl_Test is Common_Test {    
    DeployExtendedOptimismMintableTokenImpl deployerImpl;

    function setUp() public virtual override {
        super.setUp();

        vm.setEnv("PROXY_ADDRESS", vm.toString(address(L2Token)));
        vm.setEnv("NAME", L2Token.name());
        vm.setEnv("SYMBOL", L2Token.symbol());
        vm.setEnv("REMOTE_TOKEN", vm.toString(address(L1Token)));
        deployerImpl = new DeployExtendedOptimismMintableTokenImpl();
    }

    function test_deployExtendedOptimismMintableTokenImpl_success() external {
        L2TokenImpl = ExtendedOptimismMintableToken(deployerImpl.run());

        // Check initialized version
        uint64 initializedVersion = uint64(uint(vm.load(
            address(L2Token),
             0
        )));
        assertEq(initializedVersion, 2);

        assertEq(L2TokenImpl.BRIDGE(), L2Token.BRIDGE());
        assertEq(L2TokenImpl.bridge(), L2Token.bridge());
        assertEq(L2TokenImpl.l2Bridge(), L2Token.l2Bridge());
        assertEq(L2TokenImpl.REMOTE_TOKEN(), L2Token.REMOTE_TOKEN());
        assertEq(L2TokenImpl.remoteToken(), L2Token.remoteToken());
        assertEq(L2TokenImpl.l1Token(), L2Token.l1Token());
        assertEq(L2TokenImpl.decimals(), L2Token.decimals());      
        assertTrue(L2TokenImpl.supportsInterface(type(IERC165).interfaceId));
        assertTrue(L2TokenImpl.supportsInterface(type(ILegacyMintableERC20).interfaceId));
        assertTrue(L2TokenImpl.supportsInterface(type(IOptimismMintableERC20).interfaceId));
        assertTrue(L2TokenImpl.supportsInterface(type(IEIP3009).interfaceId));
        assertTrue(L2TokenImpl.supportsInterface(type(IERC20Permit).interfaceId));
    }
}
