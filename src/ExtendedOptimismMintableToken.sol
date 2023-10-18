// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { ILegacyMintableERC20, IOptimismMintableERC20 } from "@eth-optimism-bedrock/contracts/universal/IOptimismMintableERC20.sol";
import { Semver } from "@eth-optimism-bedrock/contracts/universal/Semver.sol";
import { UpgradeableOptimismMintableERC20 } from "src/UpgradeableOptimismMintableERC20.sol";
import { EIP3009 } from "src/eip-3009/EIP3009.sol";
import { IEIP3009 } from "src/eip-3009/IEIP3009.sol";
import { IERC20Internal } from "src/IERC20Internal.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import { PausableWithAccess } from "src/roles/PausableWithAccess.sol";
import { Blacklistable } from "src/roles/Blacklistable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title ExtendedOptimismMintableToken
 * @notice ExtendedOptimismMintableToken is an EIP-3009 and EIP2612 compliant extension of the  
 *         UpgradeableOptimismMintableERC20 token contract with additional blacklisting and
 *         pausing capabilities, implemented with role based access control.
 */
contract ExtendedOptimismMintableToken is Semver, UpgradeableOptimismMintableERC20, EIP3009, ERC20PermitUpgradeable, PausableWithAccess, Blacklistable {
    /**
     * @custom:semver 1.0.0
     * @notice Constructor method 
     * @param _bridge      Address of the L2 standard bridge.
     * @param _remoteToken Address of the corresponding L1 token.
     * @param _decimals    Number of decimals for user representation for display purposes. 
     */
    constructor(
        address _bridge,
        address _remoteToken,
        uint8 _decimals
    )
        Semver(1, 0, 0)
        UpgradeableOptimismMintableERC20(_bridge, _remoteToken, _decimals) 
    {
        _disableInitializers();
    }

    /**
     * @notice Initializer method 
     * @param _name         EIP-712 name. Suggested convention is to use the ERC20 name.
     * @param _rolesAdmin        Address designated for the rolesAdmin role.
     */
    function initializeV2(
        string memory _name,
        address _rolesAdmin
    ) external virtual reinitializer(2) {
        EIP712Upgradeable.__EIP712_init(_name, "1");
        _grantRole(DEFAULT_ADMIN_ROLE, _rolesAdmin);
        __Pausable_init();
        // No-op initializations are called so as to make all inherited contract's initialization explicit
        __AccessControl_init();
        blacklisted[address(this)] = true;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract.
     */
    function decimals() public view override(ERC20Upgradeable, UpgradeableOptimismMintableERC20) virtual returns (uint8) {
        return UpgradeableOptimismMintableERC20.decimals();
    }

    /**
     * @notice ERC165 interface check function.
     * @param _interfaceId Interface ID to check.
     * @return Whether or not the interface is supported by this contract.
     */
    function supportsInterface(bytes4 _interfaceId) 
        public 
        pure 
        virtual 
        override(AccessControlUpgradeable, UpgradeableOptimismMintableERC20) 
        returns (bool) 
    {
        return UpgradeableOptimismMintableERC20.supportsInterface(_interfaceId) || 
                // Interface corresponding to EIP-3009 
                _interfaceId == type(IEIP3009).interfaceId ||
                // Interface corresponding to EIP-2612 
                _interfaceId == type(IERC20Permit).interfaceId;
    }

    /**
     * @notice Execute a transfer with a signed authorization
     * @param from          Payer's address (Authorizer)
     * @param to            Payee's address
     * @param value         Amount to be transferred
     * @param validAfter    The time after which this is valid (unix time)
     * @param validBefore   The time before which this is valid (unix time)
     * @param nonce         Unique nonce
     * @param v             v of the signature
     * @param r             r of the signature
     * @param s             s of the signature
     * 
     * Requirements:
     * 
     * - contract is not paused
     * - `from` cannot be blacklisted
     * - `to` cannot be blacklisted
     */
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        external
        virtual
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(from)
        notBlacklisted(to)
    {
        _transferWithAuthorization(from, to, value, validAfter, validBefore, nonce, v, r, s); 
    }

    /**
     * @notice Receive a transfer with a signed authorization from the payer
     * @dev This has an additional check to ensure that the payee's address
     * matches the caller of this function to prevent front-running attacks.
     * @param from          Payer's address (Authorizer)
     * @param to            Payee's address
     * @param value         Amount to be transferred
     * @param validAfter    The time after which this is valid (unix time)
     * @param validBefore   The time before which this is valid (unix time)
     * @param nonce         Unique nonce
     * @param v             v of the signature
     * @param r             r of the signature
     * @param s             s of the signature
     *
     * Requirements:
     * 
     * - contract is not paused
     * - `from` cannot be blacklisted
     * - `to` cannot be blacklisted
     */
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual whenNotPaused notBlacklisted(from) notBlacklisted(to) {
        _receiveWithAuthorization(from, to, value, validAfter, validBefore, nonce, v, r, s);
    }

    /**
     * @notice Attempt to cancel an authorization
     * @param authorizer    Authorizer's address
     * @param nonce         Nonce of the authorization
     * @param v             v of the signature
     * @param r             r of the signature
     * @param s             s of the signature
     * 
     * Requirements:
     * 
     * - contract is not paused
     */
    function cancelAuthorization(
        address authorizer,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual whenNotPaused notBlacklisted(_msgSender()) notBlacklisted(authorizer) {
        _cancelAuthorization(authorizer, nonce, v, r, s);
    }

    /**
     * @notice Update allowance with a signed permit
     * @param owner       Token owner's address (Authorizer)
     * @param spender     Spender's address
     * @param value       Amount of allowance
     * @param deadline    Expiration time, seconds since the epoch
     * @param v           v of the signature
     * @param r           r of the signature
     * @param s           s of the signature
     * 
     * Requirements:
     * 
     * - contract is not paused
     * - `owner` cannot be blacklisted
     * - `spender` cannot be blacklisted
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
        virtual
        override
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(owner)
        notBlacklisted(spender)
    {
        ERC20PermitUpgradeable.permit(owner, spender, value, deadline, v, r, s);
    }

    /** 
     * @dev See {ERC20Upgradeable-increaseAllowance.}
     *  
     * Additionally, requires that:
     * - contract is not paused
     * - `_msgSender()` cannot be blacklisted
     * - `spender` cannot be blacklisted
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        override
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(spender)
        returns (bool)
    {
        return ERC20Upgradeable.increaseAllowance(spender, addedValue);
    }

    /** 
     * @dev See {ERC20Upgradeable-decreaseAllowance.}
     *  
     * Additionally, requires that:
     * - contract is not paused
     * - `_msgSender()` cannot be blacklisted
     * - `spender` cannot be blacklisted
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override
        whenNotPaused 
        notBlacklisted(_msgSender())
        notBlacklisted(spender)
        returns (bool)
    {
        return ERC20Upgradeable.decreaseAllowance(spender, subtractedValue);
    }

    /** 
     * @dev See {ERC20Upgradeable-transfer.}
     *  
     * Additionally, requires that:
     * - contract is not paused
     * - `_msgSender()` cannot be blacklisted
     * - `to` cannot be blacklisted
     */
    function transfer(address to, uint256 amount) 
        public
        virtual
        override
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(to)
        returns (bool) 
    {
        return ERC20Upgradeable.transfer(to, amount);
    }

    /** 
     * @dev See {ERC20Upgradeable-approve.}
     * 
     * Additionally, requires that:
     * - contract is not paused
     * - `_msgSender()` cannot be blacklisted
     * - `spender` cannot be blacklisted
     */
    function approve(address spender, uint256 amount) 
        public
        virtual
        override
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(spender)
        returns (bool)
    {
        return ERC20Upgradeable.approve(spender, amount);
    }

    /** 
     * @dev See {ERC20Upgradeable-transferFrom.}
     *  
     * Additionally, requires that:
     * - contract is not paused
     * - `_msgSender()` cannot be blacklisted
     * - `from` cannot be blacklisted
     * - `to` cannot be blacklisted
     */
    function transferFrom(address from, address to, uint256 amount) 
        public 
        virtual
        override
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(from)
        notBlacklisted(to)
        returns (bool)
    {
        return ERC20Upgradeable.transferFrom(from, to, amount);
    }

    /** 
     * @notice Allows the StandardBridge on this network to mint tokens.
     * @param _to     Address to mint tokens to.
     * @param _amount Amount of tokens to mint.
     * 
     * Emits a {Mint} event.
     * 
     * Requirements:
     * 
     * - contract is not paused
     * - `_msgSender()` cannot be blacklisted
     * - `to` cannot be blacklisted
     * - Only callable by the `BRIDGE` address
     */
    function mint(address _to, uint256 _amount)
        public
        virtual
        override
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(_to)
    {
        UpgradeableOptimismMintableERC20.mint(_to, _amount);
    }

    /**
     * @notice Allows the StandardBridge on this network to burn tokens.
     * @param _from   Address to burn tokens from.
     * @param _amount Amount of tokens to burn.
     * 
     * Emits a {Burn} event.
     * 
     * Requirements:
     * 
     * - contract is not paused
     * - `_msgSender()` cannot be blacklisted
     * - `from` cannot be blacklisted
     * - Only callable by the `BRIDGE` address
     */
    function burn(address _from, uint256 _amount)
        public
        virtual
        override
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(_from)
    {
        UpgradeableOptimismMintableERC20.burn(_from, _amount);
    }

    /**
     * @dev Overrides function used to revoke role from a calling account
     * so that this is not possible.
     */
    function renounceRole(bytes32, address) public pure virtual override {
        revert("ExtendedOptimismMintableToken: Cannot renounce role");
    }

    /**
    * @dev Allows the current rolesAdmin to transfer control of the roles to a new rolesAdmin.
    * @param newRolesAdmin The address to transfer the role administration capability (i.e. role of `DEFAULT_ADMIN_ROLE`) to.
    */
    function changeRolesAdmin(address newRolesAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, newRolesAdmin);
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Internal function to process transfers
     * @param from  Payer's address
     * @param to    Payee's address
     * @param value Transfer amount
     */ 
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override(IERC20Internal, ERC20Upgradeable) {
        ERC20Upgradeable._transfer(from, to, value);
    }

    /**
     * @notice Internal function to process approvals
     * @param owner  Payer's address
     * @param spender Payee's address
     * @param value Transfer amount
     */ 
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual override(IERC20Internal, ERC20Upgradeable) {
        ERC20Upgradeable._approve(owner, spender, value);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}