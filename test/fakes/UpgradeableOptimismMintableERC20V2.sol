// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { UpgradeableOptimismMintableERC20 } from "src/UpgradeableOptimismMintableERC20.sol";

contract UpgradeableOptimismMintableERC20V2 is UpgradeableOptimismMintableERC20 {

    constructor() UpgradeableOptimismMintableERC20(address(0), address(0), 18) {}

    function initialize(uint8 _version) external reinitializer(_version) {}
}
