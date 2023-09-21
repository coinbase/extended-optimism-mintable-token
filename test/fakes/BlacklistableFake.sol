/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.15;

import { Blacklistable } from "src/roles/Blacklistable.sol";

contract BlacklistableFake is Blacklistable {
    
    constructor(address _rolesAdmin){
        _grantRole(DEFAULT_ADMIN_ROLE, _rolesAdmin);
    }
}