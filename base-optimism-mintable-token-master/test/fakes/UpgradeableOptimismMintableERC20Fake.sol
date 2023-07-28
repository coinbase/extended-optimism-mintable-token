// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { UpgradeableOptimismMintableERC20 } from "src/UpgradeableOptimismMintableERC20.sol";

contract UpgradeableOptimismMintableERC20Fake is UpgradeableOptimismMintableERC20 {

    constructor(
        address _bridge,
        address _remoteToken,
        uint8 _decimals
    ) UpgradeableOptimismMintableERC20(_bridge, _remoteToken, _decimals) {}

    function initialize(string memory _name, string memory _symbol) external initializer {
        UpgradeableOptimismMintableERC20.__UpgradeableOptimismMintableERC20__init(
            _name,
            _symbol
        );
    }
}
