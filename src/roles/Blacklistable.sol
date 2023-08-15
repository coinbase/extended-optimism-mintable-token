/**
 * SPDX-License-Identifier: MIT
 *
 * Where this code pulls from the CENTRE codebase, it references
 * this file at this commit: https://github.com/centrehq/centre-tokens/blob/0d3cab14ebd133a83fc834dbd48d0468bdf0b391/contracts/v1/Blacklistable.sol
 * 
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.15;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title Blacklistable
 * @dev Allows accounts to be blacklisted by a "blacklister" role
 * Allows setting and updating this role through role-based access 
 * control logic.
 */
 contract Blacklistable is AccessControlUpgradeable {
    // Role identifier for the blacklister
    bytes32 public constant BLACKLISTER_ROLE = keccak256("roles.blacklister");

    // Mapping of addresses to whether the address is blacklisted or not
    mapping(address => bool) internal blacklisted;

    /**
     * @notice Emitted when an account is blacklisted
     * @param _account  The account blacklisted
     */
    event Blacklisted(address indexed _account);
    
    /**
     * @notice Emitted when an account is unblacklisted
     * @param _account  The account that has been unblacklisted
     */
    event UnBlacklisted(address indexed _account);

    /**
     * @dev Throws if argument account is blacklisted
     * @param _account The address to check
     */
    modifier notBlacklisted(address _account) {
        require(
            !blacklisted[_account],
            "Blacklistable: account is blacklisted"
        );
        _;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
     */
    function isBlacklisted(address _account) external view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
     *
     * Emits a {Blacklisted} event.
     *
     * Requirements:
     * 
     * - Only callable by the blacklister
     */
    function blacklist(address _account) external onlyRole(BLACKLISTER_ROLE) {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
     *
     * Emits an {UnBlacklisted} event.
     *
     * Requirements:
     * 
     * - Only callable by the blacklister
     */
    function unBlacklist(address _account) external onlyRole(BLACKLISTER_ROLE) {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}