// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { ILegacyMintableERC20, IOptimismMintableERC20 } from "@eth-optimism-bedrock/contracts/universal/IOptimismMintableERC20.sol";

/// @title UpgradeableOptimismMintableERC20
/// @notice UpgradeableOptimismMintableERC20 is a modified version of the OptimismMintableERC20 contract 
///         (https://github.com/ethereum-optimism/optimism/blob/0f07717bf06c2278bbccc9c62cad30731beeb322/packages/contracts-bedrock/contracts/universal/OptimismMintableERC20.sol)
///         with the following code changes:
///         * OpenZeppelin's `ERC20Upgradeable` contract is used in place of their `ERC20` contract to support upgradeability.
///           - ERC20 contract: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC20/ERC20.sol
///           - ERC20Upgradeable contract: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.3/contracts/token/ERC20/ERC20Upgradeable.sol
///         * OpenZeppelin's `IERC165Upgradeable` contract is used in place of their `IERC165` contract to support upgradeability.
///           - IERC165 contract: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/utils/introspection/IERC165.sol
///           - IERC165Upgradeable contract: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.3/contracts/utils/introspection/IERC165Upgradeable.sol
///         * `supportsInterface` is marked as `virtual` to allow inheriting contracts to override it.
///         * An `initialize` function was added to support:
///           - The initialization of `ERC20Upgradeable` behind a proxy contract.
///         * A storage gap was added to simplify state management in the event that state variables
///           are added to `UpgradeableOptimismMintableERC20` in the future.
contract UpgradeableOptimismMintableERC20 is IOptimismMintableERC20, ILegacyMintableERC20, ERC20Upgradeable {
    /// @notice Address of the corresponding version of this token on the remote chain.
    address public immutable REMOTE_TOKEN;

    /// @notice Address of the StandardBridge on this network.
    address public immutable BRIDGE;

    /// @notice Decimal user representation.
    uint8 internal immutable _DECIMALS;

    /// @notice Emitted whenever tokens are minted for an account.
    /// @param account Address of the account tokens are being minted for.
    /// @param amount  Amount of tokens minted.
    event Mint(address indexed account, uint256 amount);

    /// @notice Emitted whenever tokens are burned from an account.
    /// @param account Address of the account tokens are being burned from.
    /// @param amount  Amount of tokens burned.
    event Burn(address indexed account, uint256 amount);

    /// @notice A modifier that only allows the bridge to call
    modifier onlyBridge() {
        require(msg.sender == BRIDGE, "OptimismMintableERC20: only bridge can mint and burn");
        _;
    }

    /// @param _bridge      Address of the L2 standard bridge.
    /// @param _remoteToken Address of the corresponding L1 token.
    /// @param _decimals    User decimal place representation.
    constructor(
        address _bridge,
        address _remoteToken,
        uint8 _decimals
    ) {
        REMOTE_TOKEN = _remoteToken;
        BRIDGE = _bridge;
        _DECIMALS = _decimals;

        _disableInitializers();
    }

    /// @notice Initializes the UpgradeableOptimismMintableERC20 contract.
    /// @param _name   ERC20 name.
    /// @param _symbol ERC20 symbol.
    function initialize(
        string memory _name,
        string memory _symbol
    ) external virtual initializer {
        ERC20Upgradeable.__ERC20_init(_name, _symbol);
    }

    /// @notice Allows the StandardBridge on this network to mint tokens.
    /// @param _to     Address to mint tokens to.
    /// @param _amount Amount of tokens to mint.
    function mint(address _to, uint256 _amount)
        public
        virtual
        override(IOptimismMintableERC20, ILegacyMintableERC20)
        onlyBridge
    {
        _mint(_to, _amount);
        emit Mint(_to, _amount);
    }

    /// @notice Allows the StandardBridge on this network to burn tokens.
    /// @param _from   Address to burn tokens from.
    /// @param _amount Amount of tokens to burn.
    function burn(address _from, uint256 _amount)
        public
        virtual
        override(IOptimismMintableERC20, ILegacyMintableERC20)
        onlyBridge
    {
        _burn(_from, _amount);
        emit Burn(_from, _amount);
    }

    /// @notice ERC165 interface check function.
    /// @param _interfaceId Interface ID to check.
    /// @return Whether or not the interface is supported by this contract.
    function supportsInterface(bytes4 _interfaceId) public pure virtual returns (bool) {
        bytes4 iface1 = type(IERC165Upgradeable).interfaceId;
        // Interface corresponding to the legacy L2StandardERC20.
        bytes4 iface2 = type(ILegacyMintableERC20).interfaceId;
        // Interface corresponding to the updated OptimismMintableERC20 (this contract).
        bytes4 iface3 = type(IOptimismMintableERC20).interfaceId;
        return _interfaceId == iface1 || _interfaceId == iface2 || _interfaceId == iface3;
    }

    /// @custom:legacy
    /// @notice Legacy getter for the remote token. Use REMOTE_TOKEN going forward.
    function l1Token() public view returns (address) {
        return REMOTE_TOKEN;
    }

    /// @custom:legacy
    /// @notice Legacy getter for the bridge. Use BRIDGE going forward.
    function l2Bridge() public view returns (address) {
        return BRIDGE;
    }

    /// @custom:legacy
    /// @notice Legacy getter for REMOTE_TOKEN.
    function remoteToken() public view returns (address) {
        return REMOTE_TOKEN;
    }

    /// @custom:legacy
    /// @notice Legacy getter for BRIDGE.
    function bridge() public view returns (address) {
        return BRIDGE;
    }

    /// @notice Returns the number of decimals used to get its user representation.
    ///         For example, if `decimals` equals `2`, a balance of `505` tokens should
    ///         be displayed to a user as `5.05` (`505 / 10 ** 2`).
    ///
    ///         NOTE: This information is only used for _display_ purposes: it in
    ///         no way affects any of the arithmetic of the contract.
    function decimals() public view override virtual returns (uint8) {
        return _DECIMALS;
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    ///      variables without shifting down storage in the inheritance chain.
    ///      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[50] private __gap;
}