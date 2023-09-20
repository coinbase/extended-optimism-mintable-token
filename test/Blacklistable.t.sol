// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Common_Test } from "test/CommonTest.t.sol";
import { BlacklistableFake } from "test/fakes/BlacklistableFake.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract Blacklistable_Test is Common_Test {    
    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);

    BlacklistableFake blacklistable;

    function setUp() public virtual override {
        super.setUp();

        blacklistable = new BlacklistableFake(owner);

        vm.prank(owner);
        blacklistable.grantRole(BLACKLISTER_ROLE, blacklister);
    }

    function test_blacklisterRoleIsCorrectHash_succeeds() external {
        assertEq(
            blacklistable.BLACKLISTER_ROLE(),
            keccak256("roles.blacklister")
        );
    }

    function test_blacklistedAfterBlacklisting_succeeds() external {
        vm.expectEmit(true, true, true, true);
        emit Blacklisted(alice);

        vm.prank(blacklister);
        blacklistable.blacklist(alice);
        assertEq(blacklistable.isBlacklisted(alice), true);
    }

    function test_unBlacklistAfterUnBlacklisting_succeeds() external {
        vm.prank(blacklister);
        blacklistable.blacklist(alice);
        assertEq(blacklistable.isBlacklisted(alice), true);

        vm.expectEmit(true, true, true, true);
        emit UnBlacklisted(alice);

        vm.prank(blacklister);
        blacklistable.unBlacklist(alice);
        assertEq(blacklistable.isBlacklisted(alice), false);
    }

    function test_nonBlacklisterBlacklisting_reverts() external{
        vm.prank(owner);
        vm.expectRevert(bytes(string.concat(
            "AccessControl: account ",
            addressToString(owner),
            " is missing role ",
            roleToString(BLACKLISTER_ROLE)
        )));
        blacklistable.blacklist(alice);
    }

    function test_nonBlacklisterUnBlacklisting_reverts() external{
        vm.prank(blacklister);
        blacklistable.blacklist(alice);
        assertEq(blacklistable.isBlacklisted(alice), true);

        vm.prank(owner);
        vm.expectRevert(bytes(string.concat(
            "AccessControl: account ",
            addressToString(owner),
            " is missing role ",
            roleToString(BLACKLISTER_ROLE)
        )));
        blacklistable.unBlacklist(alice);
    }

    function test_changingBlacklister_succeeds() external {
        vm.expectEmit(true, true, true, true);
        emit RoleGranted(BLACKLISTER_ROLE, alice, owner);

        vm.prank(owner);
        blacklistable.grantRole(BLACKLISTER_ROLE, alice);
        assertEq(blacklistable.hasRole(BLACKLISTER_ROLE, alice), true);
    }

    function test_nonAdminChangingBlacklister_reverts() external {
        vm.expectRevert(bytes(string.concat(
            "AccessControl: account ",
            addressToString(blacklister),
            " is missing role ",
            roleToString(blacklistable.DEFAULT_ADMIN_ROLE())
        )));
        vm.prank(blacklister);
        blacklistable.grantRole(BLACKLISTER_ROLE, alice);
    }
}
