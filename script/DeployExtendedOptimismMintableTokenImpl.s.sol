// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { console } from "forge-std/console.sol";
import { Script } from "forge-std/Script.sol";
import { UpgradeableOptimismMintableERC20 } from "src/UpgradeableOptimismMintableERC20.sol";
import { ExtendedOptimismMintableToken } from "src/ExtendedOptimismMintableToken.sol";
import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";
import { Predeploys } from "@eth-optimism-bedrock/contracts/libraries/Predeploys.sol";

contract DeployExtendedOptimismMintableTokenImpl is Script {
    address payable public proxy = payable(vm.envAddress("PROXY_ADDRESS"));

    function run()
        public returns(address)
    {
        UpgradeableOptimismMintableERC20 upgradeableOptimismMintableERC20 = UpgradeableOptimismMintableERC20(proxy);
        address remoteToken = upgradeableOptimismMintableERC20.REMOTE_TOKEN();
        uint8 decimals = upgradeableOptimismMintableERC20.decimals();

        console.log("L2 Bridge: %s", Predeploys.L2_STANDARD_BRIDGE);
        console.log("Remote Token: %s", remoteToken);
        console.log("Decimals: %s", decimals);

        vm.broadcast();
        ExtendedOptimismMintableToken extendedOptimismMintableTokenImpl = new ExtendedOptimismMintableToken(
            Predeploys.L2_STANDARD_BRIDGE,
            remoteToken,
            decimals
        );

        require(extendedOptimismMintableTokenImpl.BRIDGE() == Predeploys.L2_STANDARD_BRIDGE, 
            "DeployExtendedOptimismMintableTokenImpl: token l2Bridge incorrect")
        ;
        require(extendedOptimismMintableTokenImpl.REMOTE_TOKEN() == remoteToken, 
            "DeployExtendedOptimismMintableTokenImpl: token remoteToken incorrect"
        );
        require(extendedOptimismMintableTokenImpl.decimals() == decimals, 
            "DeployExtendedOptimismMintableTokenImpl: token decimals incorrect"
        );

        console.log("extendedOptimismMintableToken implementation deployed to %s", address(extendedOptimismMintableTokenImpl));

        return address(extendedOptimismMintableTokenImpl);
    }
}
