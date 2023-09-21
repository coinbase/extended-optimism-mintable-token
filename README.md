# ExtendedOptimismMintableToken
This repository implements the [`ExtendedOptimismMintableToken.sol`](./src/ExtendedOptimismMintableToken.sol). The Extended Optimism Mintable Token contract is an ERC-20 compatible token, 
and is based on Optimism's [`OptimismMintableERC20`](https://github.com/ethereum-optimism/optimism/blob/0f07717bf06c2278bbccc9c62cad30731beeb322/packages/contracts-bedrock/contracts/universal/OptimismMintableERC20.sol) contract. It allows minting/burning of tokens by a specified bridge, pausing all activity, freezing of individual
addresses ("blacklisting"), and a way to upgrade the contract so that bugs can be fixed or features added. It also supports gas abstraction functionality by implementing [EIP-3009](https://eips.ethereum.org/EIPS/eip-3009) and using OpenZeppelin's upgradeable [EIP-2612](https://eips.ethereum.org/EIPS/eip-2612) implementation. We describe this functionality further under [Functionality](#functionality). Finally, it uses OpenZeppelin's [AccessControl](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.3/contracts/access/AccessControlUpgradeable.sol) pattern to use role-based access control for the pausing and blacklisting capabilities, designating a role to manage each, along with a `DEFAULT_ROLE_ADMIN`  role to manage those roles (detailed further below).

### UpgradeableOptimismMintableERC20
The `ExtendedOptimismMintableToken` inherits from the `UpgradeableOptimismMintableERC20` contract, which itself is based off of Optimism's [OptimismMintableERC20](https://github.com/ethereum-optimism/optimism/blob/0f07717bf06c2278bbccc9c62cad30731beeb322/packages/contracts-bedrock/contracts/universal/OptimismMintableERC20.sol) contract. The `UpgradeableOptimismMintableERC20` contains the following changes from Optimism's `OptimismMintableERC20`:
 * OpenZeppelin's [`ERC20Upgradeable`](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.3/contracts/token/ERC20/ERC20Upgradeable.sol) contract is used in place of their [`ERC20`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC20/ERC20.sol) contract to support upgradeability.
 * OpenZeppelin's [`IERC165Upgradeable`](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.3/contracts/utils/introspection/IERC165Upgradeable.sol) contract is used in place of their [`IERC165`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/utils/introspection/IERC165.sol) contract to support upgradeability.
 * `supportsInterface` is marked as `public virtual` to allow inheriting contracts to both override and call it.
 * Marks `mint` and `burn` as `public` instead of `external` to allow inheriting contracts to call them.
* An `initialize` initializer function was added to support the initialization of `ERC20Upgradeable` configuration.
* A `decimals` variable was added to the constructor.
* A storage gap was added to simplify state management in the event that state variables are added to `UpgradeableOptimismMintableERC20` in the future.

### Commands and Setup
Requirements:
- Node >= v12
- Yarn
- The required versions of the Optimism repo and Foundry are specified in the .env file

* Run `make install-foundry` to install [`Foundry` at this linked commit](https://github.com/foundry-rs/foundry/commit/3b1129b5bc43ba22a9bcf4e4323c5a9df0023140). 
* Run `make build` to install dependencies.
* Run `make tests` to run tests.
* Run `make coverage` to get code coverage.
* Set the required .env variables and run `make deploy` to simulate Base Mainnet token deployment locally.

### Deployment
* **Note**: To initialize the `ExtendedOptimismMintableToken` contract, you need to call the `initialize` method inherited from `UpgradeableOptimismMintableERC20`, and then  `ExtendedOptimismMintableToken`'s `initializeV2` method.
* Configure the following variables in `.env`:
    * `DEPLOYER` - the address deploying the token implementation and proxy contract.
    * `ADMIN` - the address to be the `admin` of the token's proxy contract. Not to be confused with the `DEFAULT_ROLE_ADMIN` env variable and role specified below, which administrates the `blacklister` and `pauser` roles along with itself.
    * `L2_BRIDGE` - the address of the [`L2StandardBridge`](https://github.com/ethereum-optimism/optimism/blob/0f07717bf06c2278bbccc9c62cad30731beeb322/packages/contracts-bedrock/contracts/L2/L2StandardBridge.sol) contract which is able to mint and burn the token being deployed.
    * `REMOTE_TOKEN` - the L1 address of the L2 bridged token being deployed.
    * `NAME` - the `ERC20` [`name`](https://eips.ethereum.org/EIPS/eip-20#name) of the bridged token. This is also used for the `EIP-712` domain separator [`name`](https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator).
    * `SYMBOL` - the `ERC20` [`symbol`](https://eips.ethereum.org/EIPS/eip-20#symbol) of the bridged token.
    * `DECIMALS` - the `ERC20` [`decimals`](https://eips.ethereum.org/EIPS/eip-20#decimals) of the bridged token.
    * `PAUSER` - the only address for the role that can pause the contract, which prevents all transfers, minting, and burning
    * `BLACKLISTER` - the only address for the role that can call `blacklist(address)`, which prevents all transfers to or from that address, and `unBlacklist(address)`
    * `DEFAULT_ROLE_ADMIN` - the address for the role which can re-assign itself and the `PAUSER` and `BLACKLISTER` roles. This role can NOT change the `ADMIN` address, which administrates the proxy contract.
* Run `make deploy` to simulate Base Mainnet token deployment locally.


## Functionality 

### Issuing and Destroying tokens
The `ExtendedOptimismMintableToken` allows the `BRIDGE` address to create (`mint`) and destroy (`burn``) tokens.

#### Minting
As on Optimism's `OptimismMintableERC20` contract, the `BRIDGE` mints tokens via the `mint` method. It specifies the
`amount` of tokens to create, and a `_to` address which will own the newly
created tokens. The balance of the `_to` address and `totalSupply` will each
increase by `amount`. 

- Only the `BRIDGE` may call `mint`.
- Minting fails when the contract is `paused`.
- Minting fails when the `BRIDGE` or `_to` address is blacklisted.
- Minting emits a `Mint(_to, amount)` event and a
  `Transfer(0x00, _to, amount)` event.

#### Burning
As on Optimism's `OptimismMintableERC20` contract, the `BRIDGE` burns tokens via the `burn` method. It specifies the
The `BRIDGE` specifies the address `_from` whose tokens are burned (i.e. whose balance of the token, along with the `totalSupply` of the token, are reduced by `amount`) and the 
`amount` of tokens to burn. The `_from` address must have a `balance` greater than
or equal to the `amount`. The abillity to burn tokens is restricted to the `BRIDGE` address.

- Only the `BRIDGE` address may call burn.

- Burning fails when the contract is paused.
- Burning fails when the calling address is blacklisted.
- Burning fails when the `_from` address is blacklisted.

- Burning emits a `Burn(_from_, amount)` event, and a
  `Transfer(_from_, 0x00, amount)` event.

### Blacklisting

Addresses can be blacklisted. A blacklisted address will be unable to participate in the approval, 
increase or decrease of allowances and will be unable to transfer, mint, or burn tokens.

#### Adding a blacklisted address

Coinbase blacklists an address via the `blacklist` method. The specified `account`
will be added to the blacklist.

- Only the `blacklister` role may call `blacklist`.
- Blacklisting emits a `Blacklist(account)` event

#### Removing a blacklisted address

Coinbase removes an address from the blacklist via the `unblacklist` method. The
specified `account` will be removed from the blacklist.

- Only the `blacklister` role may call `unblacklist`.
- Unblacklisting emits an `UnBlacklist(account)` event.

### Pausing

The entire contract can be paused in case a serious bug is found or there is a
serious key compromise. All transfers, minting, and burning will
be prevented while the contract is paused. Other functionality, such as
modifying the blacklist, changing roles, and upgrading will
remain operational as those methods may be required to fix or mitigate the issue
that caused Coinbase to pause the contract.

#### Pause

Coinbase will pause the contract via the `pause` method. This method will set the
paused flag to true.

- Only the `pauser` role may call pause.

- Pausing emits a `Pause()` event

#### Unpause

Coinbase will unpause the contract via the `unpause` method. This method will set
the `paused` flag to false. All functionality will be restored when the contract
is unpaused.

- Only the `pauser` role may call unpause.

- Unpausing emits an `Unpause()` event

### Gas Abstraction

#### EIP-3009
The `ExtendedOptimismMintableToken` implements [EIP-3009](https://eips.ethereum.org/EIPS/eip-3009), with the additional requirement that transfers via this functionality not be called with blacklisted `from` or `to` addresses, nor while the contract is paused.

#### EIP-2612
The `ExtendedOptimismMintableToken` uses OpenZeppelin's [EIP-2612](https://eips.ethereum.org/EIPS/eip-2612) upgradeable implementation, and adds the requirement that `permit` not be called with blacklisted `owner` or `spender` addresses, nor while the contract is paused.

### Upgrading

The Extended OptimismMintable Token uses the  Unstructured-Storage Proxy pattern
[https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies]. The contracts use storage gaps to simplify state management in the event that state variables are added to in future upgrades. [`ExtendedOptimismMintableToken.sol`](./src/ExtendedOptimismMintableToken.sol) is the implementation, the
actual token address will be a Proxy contract
(using the code from Optimism's [Proxy.sol](https://github.com/ethereum-optimism/optimism/blob/0f07717bf06c2278bbccc9c62cad30731beeb322/packages/contracts-bedrock/contracts/universal/Proxy.sol)) which will forward all
calls to `ExtendedOptimismMintableToken` via delegatecall. This pattern allows Coinbase to upgrade the
logic of any deployed tokens seamlessly.

- Coinbase will upgrade the token via a call to `upgradeTo` or `upgradeToAndCall`
  if initialization is required for the new version.
- Only the Proxy contract's `admin` role may call `upgradeTo` or `upgradeToAndCall`.
- For upgrades, if an initializer method is used, set a constant version in the `reinitializer` modifier that is incremented from the previous upgrade's version. This prevents the initializer method from being called multiple times. Failing to follow this guidance could introduce vulnerabilities. Additionally, note subsequently introduced `reinitializer` methods are not meant to re-execute the same initialization code used in previous versions.

### Reassigning Roles

The roles (`blacklister`, `pauser`) described above may be reassigned. The `DEFAULT_ROLE_ADMIN` role has the ability to
reassign itself and the `blacklister` and `pauser` roles. It cannot re-assign the Proxy contract's `admin` role. The `BRIDGE` address is immutable, in keeping with the `OptimismMintableERC20` contract.

- `changeRolesAdmin` updates the `DEFAULT_ROLE_ADMIN` role to a new address.
- `changeRolesAdmin` may only be called by the `DEFAULT_ROLE_ADMIN` role.

### Convention for function parameters


### Optimism Citation
This work uses software from The Optimism Monorepo:
```
title: The Optimism Monorepo
authors:
- name: The Optimism Collective
version: 1.0.0
year: 2020
url: https://github.com/ethereum-optimism/optimism
repository: https://github.com/ethereum-optimism/optimism
license: MIT
```

### CENTRE code references
Where this code indicates it uses code from the CENTRE codebase, it references
this commit [https://github.com/centrehq/centre-tokens/commit/0d3cab14ebd133a83fc834dbd48d0468bdf0b391](https://github.com/centrehq/centre-tokens/commit/0d3cab14ebd133a83fc834dbd48d0468bdf0b391)

I.e. from the CENTRE Fiat Token codebase, we specifically reference:
* [Blacklistable.sol](https://github.com/centrehq/centre-tokens/blob/0d3cab14ebd133a83fc834dbd48d0468bdf0b391/contracts/v1/Blacklistable.sol)
* [EIP3009.sol](https://github.com/centrehq/centre-tokens/blob/0d3cab14ebd133a83fc834dbd48d0468bdf0b391/contracts/v2/EIP3009.sol) 
* [AbstractFiatTokenV1.sol](https://github.com/centrehq/centre-tokens/blob/0d3cab14ebd133a83fc834dbd48d0468bdf0b391/contracts/v1/AbstractFiatTokenV1.sol) 