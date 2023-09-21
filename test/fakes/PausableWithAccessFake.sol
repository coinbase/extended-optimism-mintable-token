/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.15;

import { PausableWithAccess } from "src/roles/PausableWithAccess.sol";

contract PausableWithAccessFake is PausableWithAccess {
    
    constructor(address _rolesAdmin){
        _grantRole(DEFAULT_ADMIN_ROLE, _rolesAdmin);
    }
}