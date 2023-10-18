// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import { Common_Test } from "test/CommonTest.t.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ILegacyMintableERC20, IOptimismMintableERC20 } from "@eth-optimism-bedrock/contracts/universal/IOptimismMintableERC20.sol";
import { IEIP3009 } from "src/eip-3009/IEIP3009.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import { ExtendedOptimismMintableToken } from "src/ExtendedOptimismMintableToken.sol";

contract ExtendedOptimismMintableToken_Test is Common_Test {
    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);

    function setUp() public virtual override {
        super.setUp();
    }

    // Tests begin
    function test_remoteToken_succeeds() external {
        assertEq(L2Token.remoteToken(), address(L1Token));
    }

    function test_bridge_succeeds() external {
        assertEq(L2Token.bridge(), address(L2Bridge));
    }

    function test_l1Token_succeeds() external {
        assertEq(L2Token.l1Token(), address(L1Token));
    }

    function test_l2Bridge_succeeds() external {
        assertEq(L2Token.l2Bridge(), address(L2Bridge));
    }

    function test_legacy_succeeds() external {
        // Getters for the remote token
        assertEq(L2Token.REMOTE_TOKEN(), address(L1Token));
        assertEq(L2Token.remoteToken(), address(L1Token));
        assertEq(L2Token.l1Token(), address(L1Token));
        // Getters for the bridge
        assertEq(L2Token.BRIDGE(), address(L2Bridge));
        assertEq(L2Token.bridge(), address(L2Bridge));
        assertEq(L2Token.l2Bridge(), address(L2Bridge));
    }

    function test_mint_succeeds() external {
        vm.expectEmit(true, true, true, true);
        emit Mint(alice, 100);

        vm.prank(address(L2Bridge));
        L2Token.mint(alice, 100);

        assertEq(L2Token.balanceOf(alice), 100);
    }

    function test_mint_notBridge_reverts() external {
        // NOT the bridge
        vm.expectRevert("OptimismMintableERC20: only bridge can mint and burn");
        vm.prank(alice);
        L2Token.mint(alice, 100);
    }

    function test_burn_succeeds() external {
        vm.prank(address(L2Bridge));
        L2Token.mint(alice, 100);

        vm.expectEmit(true, true, true, true);
        emit Burn(alice, 100);

        vm.prank(address(L2Bridge));
        L2Token.burn(alice, 100);

        assertEq(L2Token.balanceOf(alice), 0);
    }

    function test_burn_notBridge_reverts() external {
        // NOT the bridge
        vm.expectRevert("OptimismMintableERC20: only bridge can mint and burn");
        vm.prank(alice);
        L2Token.burn(alice, 100);
    }

    function test_erc165_supportsInterface_succeeds() external {
        // The assertEq calls in this test are comparing the manual calculation of the iface,
        // with what is returned by the solidity's type().interfaceId, just to be safe.
        bytes4 iface1 = bytes4(keccak256("supportsInterface(bytes4)"));
        assertEq(iface1, type(IERC165).interfaceId);
        assert(L2Token.supportsInterface(iface1));

        bytes4 iface2 = L2Token.l1Token.selector ^ L2Token.mint.selector ^ L2Token.burn.selector;
        assertEq(iface2, type(ILegacyMintableERC20).interfaceId);
        assert(L2Token.supportsInterface(iface2));

        bytes4 iface3 = L2Token.remoteToken.selector ^
            L2Token.bridge.selector ^
            L2Token.mint.selector ^
            L2Token.burn.selector;
        assertEq(iface3, type(IOptimismMintableERC20).interfaceId);
        assert(L2Token.supportsInterface(iface3));

        bytes4 iface4 = L2Token.authorizationState.selector^
            L2Token.transferWithAuthorization.selector^
            L2Token.receiveWithAuthorization.selector;
        assertEq(iface4, type(IEIP3009).interfaceId);
        assert(L2Token.supportsInterface(iface4));

        bytes4 iface5 = L2Token.permit.selector^
            L2Token.nonces.selector^
            L2Token.DOMAIN_SEPARATOR.selector;
        assertEq(iface5, type(IERC20Permit).interfaceId);
        assert(L2Token.supportsInterface(iface5));
    }

    function test_initializeV2CalledTwice_reverts() external {
        vm.expectRevert("Initializable: contract is already initialized");
        L2Token.initializeV2("L2 Token Name", rolesAdmin);
    }

    function test_initializeCalledTwice_reverts() external {
        vm.expectRevert("Initializable: contract is already initialized");
        L2Token.initialize("L2 Token Name", "SYM");
    }

    function test_userSendingFundsToTokenContract_reverts() external {
        hoax(alice, 2 ether);
        vm.expectRevert("Blacklistable: account is blacklisted");
        address(L2Token).call{value: 2 ether}("");
    }

    function test_mintWhenPaused_reverts() external {
        vm.prank(pauser);
        L2Token.pause();
        
        vm.expectRevert("Pausable: paused");
        vm.prank(address(L2Bridge));
        L2Token.mint(alice, 100);
    }

    function test_burnWhenPaused_reverts() external {
        vm.prank(pauser);
        L2Token.pause();
        
        vm.expectRevert("Pausable: paused");
        vm.prank(address(L2Bridge));
        L2Token.burn(alice, 100);
    }

    function test_transfer_succeeds() external {
        vm.prank(address(L2Bridge));
        L2Token.mint(alice, 100);

        vm.prank(address(alice));
        L2Token.transfer(rolesAdmin, 100);

        assertEq(L2Token.balanceOf(alice), 0);
        assertEq(L2Token.balanceOf(rolesAdmin), 100);
    }

    function test_transferWhenPaused_reverts() external {
        vm.prank(pauser);
        L2Token.pause();

        vm.expectRevert("Pausable: paused");
        vm.prank(address(L2Bridge));
        L2Token.transfer(alice, 100);
    }

    function test_transferFrom_succeeds() external {
        vm.prank(address(L2Bridge));
        L2Token.mint(alice, 100);

        vm.prank(address(alice));
        L2Token.approve(rolesAdmin, 100);

        vm.prank(address(rolesAdmin));
        L2Token.transferFrom(alice, rolesAdmin, 100);

        assertEq(L2Token.balanceOf(alice), 0);
        assertEq(L2Token.balanceOf(rolesAdmin), 100);
    }

    function test_transferFromWhenPaused_reverts() external {
        vm.prank(pauser);
        L2Token.pause();

        vm.expectRevert("Pausable: paused");
        vm.prank(address(L2Bridge));
        L2Token.transferFrom(rolesAdmin, alice, 100);
    }

    function test_approve_succeeds() external {
        vm.prank(address(L2Bridge));
        L2Token.approve(alice, 100);

        assertEq(L2Token.allowance(address(L2Bridge), alice), 100);
    }

    function test_approveWhenPaused_reverts() external {
        vm.prank(pauser);
        L2Token.pause();

        vm.expectRevert("Pausable: paused");
        vm.prank(alice);
        L2Token.approve(rolesAdmin, 100);
    }

    function test_mintWhenBlacklisted_reverts() external {
        vm.prank(blacklister);
        L2Token.blacklist(alice);
        assertEq(L2Token.isBlacklisted(alice), true);
        
        vm.expectRevert("Blacklistable: account is blacklisted");
        vm.prank(address(L2Bridge));
        L2Token.mint(alice, 100);
    }

    function test_burnWhenBlacklisted_reverts() external {
        // Blacklist the bridge
        vm.prank(blacklister);
        L2Token.blacklist(address(L2Bridge));
        assertEq(L2Token.isBlacklisted(address(L2Bridge)), true);
        
        vm.expectRevert("Blacklistable: account is blacklisted");
        vm.prank(address(L2Bridge));
        L2Token.burn(alice, 100);
    }

    function test_transferWhenBlacklisted_reverts() external {
        vm.prank(blacklister);
        L2Token.blacklist(alice);
        assertEq(L2Token.isBlacklisted(alice), true);
        
        vm.expectRevert("Blacklistable: account is blacklisted");
        vm.prank(alice);
        L2Token.transfer(rolesAdmin, 100);
    }

    function test_transferFromWhenFromBlacklisted_reverts() external {
        vm.prank(blacklister);
        L2Token.blacklist(alice);
        assertEq(L2Token.isBlacklisted(alice), true);
        
        vm.expectRevert("Blacklistable: account is blacklisted");
        vm.prank(address(L2Bridge));
        L2Token.transferFrom(alice, rolesAdmin, 100);
    }

    function test_transferFromWhenToBlacklisted_reverts() external {
        vm.prank(blacklister);
        L2Token.blacklist(alice);
        assertEq(L2Token.isBlacklisted(alice), true);
        
        vm.expectRevert("Blacklistable: account is blacklisted");
        vm.prank(address(L2Bridge));
        L2Token.transferFrom(rolesAdmin, alice, 100);
    }

    function test_transferFromWhenMsgSenderBlacklisted_reverts() external {
        vm.prank(blacklister);
        L2Token.blacklist(alice);
        assertEq(L2Token.isBlacklisted(alice), true);
        
        vm.expectRevert("Blacklistable: account is blacklisted");
        vm.prank(alice);
        L2Token.transferFrom(rolesAdmin, pauser, 100);
    }

    function test_approveWhenBlacklistedSpender_reverts() external {
        vm.prank(blacklister);
        L2Token.blacklist(alice);
        assertEq(L2Token.isBlacklisted(alice), true);

        // address being approved (spender) cannot be blacklisted
        vm.expectRevert("Blacklistable: account is blacklisted");
        vm.prank(rolesAdmin);
        L2Token.approve(alice, 100);
    }

    function test_approveWhenBlacklistedMsgSender_reverts() external {
        vm.prank(blacklister);
        L2Token.blacklist(alice);
        assertEq(L2Token.isBlacklisted(alice), true);

        // msg.sender cannot approve if blacklisted
        vm.expectRevert("Blacklistable: account is blacklisted");
        vm.prank(alice);
        L2Token.approve(rolesAdmin, 100);
    }

    function test_renounceRole_reverts() external {
        vm.expectRevert("ExtendedOptimismMintableToken: Cannot renounce role");
        L2Token.renounceRole(DEFAULT_ADMIN_ROLE, rolesAdmin);

    }

    function test_changeRolesAdmin_succeeds() external {
        vm.prank(rolesAdmin);
        L2Token.changeRolesAdmin(alice);
        assertEq(L2Token.hasRole(DEFAULT_ADMIN_ROLE, rolesAdmin), false);
        assertEq(L2Token.hasRole(DEFAULT_ADMIN_ROLE, alice), true);
    }
    
    function test_changeRolesAdminWhenNotRolesAdmin_reverts() external {
        vm.expectRevert(bytes(string.concat(
            "AccessControl: account ",
            addressToString(alice),
            " is missing role ",
            roleToString(L2Token.DEFAULT_ADMIN_ROLE())
        )));

        vm.prank(alice);
        L2Token.changeRolesAdmin(alice);
    }
}
