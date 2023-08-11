/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.15;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @dev Contract which implements an emergency stop mechanism that
 * can be triggered by an authorized account, the pauser. Allows setting and
 * updating this role through role-based access control logic.
 */
contract PausableWithAccess is AccessControlUpgradeable, PausableUpgradeable {
    // Role identifier for the pauser
    bytes32 public constant PAUSER_ROLE = keccak256("roles.pauser");

    /**
     * @dev called by the pauser to unpause, returns to normal state
     *
     * May emit an {Unpaused} event.
     *
     * Requirements:
     * 
     * - Only callable by the pauser
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev called by the pauser to pause
     *
     * May emit a {Paused} event.
     *
     * Requirements:
     * 
     * - Only callable by the pauser
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
