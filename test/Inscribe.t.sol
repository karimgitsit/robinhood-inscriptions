// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {Inscribe} from "../src/Inscribe.sol";

contract InscribeTest is Test {
    Inscribe internal inscribe;
    address internal owner = address(this);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    uint256 internal constant FEE = 0.001 ether;

    receive() external payable {}

    function setUp() public {
        inscribe = new Inscribe(FEE);
    }

    function _dataURI(string memory text) internal pure returns (string memory) {
        return string.concat("data:text/plain;charset=utf-8,", text);
    }

    function test_DeployFees() public view {
        assertEq(inscribe.fee(), FEE);
        assertEq(inscribe.totalInscriptions(), 0);
        assertEq(inscribe.owner(), owner);
    }

    function test_InscribePaysFee() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        uint256 id = inscribe.inscribe{value: FEE}(_dataURI("hello robinhood"));
        assertEq(id, 1);
        assertEq(inscribe.totalInscriptions(), 1);
        assertEq(inscribe.ownerOf(1), alice);
        assertEq(inscribe.balanceOf(alice), 1);
        assertEq(inscribe.contentOf(1), _dataURI("hello robinhood"));
        assertEq(address(inscribe).balance, FEE);
    }

    function test_InscribeRevertsIfUnderFee() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert(Inscribe.InsufficientFee.selector);
        inscribe.inscribe{value: FEE - 1}(_dataURI("cheap"));
    }

    function test_InscribeRevertsIfTooLong() public {
        vm.deal(alice, 1 ether);
        bytes memory big = new bytes(Inscribe(inscribe).MAX_CONTENT_LENGTH() + 1);
        vm.prank(alice);
        vm.expectRevert(Inscribe.ContentTooLong.selector);
        inscribe.inscribe{value: FEE}(string(big));
    }

    function test_TransferOwnership() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        uint256 id = inscribe.inscribe{value: FEE}(_dataURI("artifact"));
        vm.prank(alice);
        inscribe.transfer(id, bob);
        assertEq(inscribe.ownerOf(id), bob);
        assertEq(inscribe.balanceOf(alice), 0);
        assertEq(inscribe.balanceOf(bob), 1);
    }

    function test_TransferRevertsIfNotOwner() public {
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.prank(alice);
        uint256 id = inscribe.inscribe{value: FEE}(_dataURI("artifact"));
        vm.prank(bob);
        vm.expectRevert(Inscribe.NotInscriptionOwner.selector);
        inscribe.transfer(id, alice);
    }

    function test_TransferRevertsToSelf() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        uint256 id = inscribe.inscribe{value: FEE}(_dataURI("artifact"));
        vm.prank(alice);
        vm.expectRevert(Inscribe.TransferToSelf.selector);
        inscribe.transfer(id, alice);
    }

    function test_TransferRevertsToZero() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        uint256 id = inscribe.inscribe{value: FEE}(_dataURI("artifact"));
        vm.prank(alice);
        vm.expectRevert(Inscribe.InvalidAddress.selector);
        inscribe.transfer(id, address(0));
    }

    function test_MultipleInscriptions() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);
        uint256 id1 = inscribe.inscribe{value: FEE}(_dataURI("one"));
        uint256 id2 = inscribe.inscribe{value: FEE}(_dataURI("two"));
        uint256 id3 = inscribe.inscribe{value: FEE}(_dataURI("three"));
        vm.stopPrank();
        assertEq(id1, 1);
        assertEq(id2, 2);
        assertEq(id3, 3);
        assertEq(inscribe.balanceOf(alice), 3);
        assertEq(inscribe.totalInscriptions(), 3);
    }

    function test_SetFeeOwnerOnly() public {
        vm.prank(owner);
        inscribe.setFee(2 ether);
        assertEq(inscribe.fee(), 2 ether);
        vm.prank(alice);
        vm.expectRevert(Inscribe.NotOwner.selector);
        inscribe.setFee(3 ether);
    }

    function test_SetOwner() public {
        inscribe.setOwner(bob);
        assertEq(inscribe.owner(), bob);
        vm.expectRevert(Inscribe.NotOwner.selector);
        inscribe.setFee(1 ether);
        vm.prank(bob);
        inscribe.setFee(1 ether);
        assertEq(inscribe.fee(), 1 ether);
    }

    function test_SetOwnerRevertsIfNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(Inscribe.NotOwner.selector);
        inscribe.setOwner(alice);
    }

    function test_SetOwnerRevertsToZero() public {
        vm.expectRevert(Inscribe.InvalidAddress.selector);
        inscribe.setOwner(address(0));
    }

    function test_WithdrawGoesToNewOwner() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        inscribe.inscribe{value: FEE}(_dataURI("artifact"));
        inscribe.setOwner(bob);
        vm.prank(bob);
        inscribe.withdraw();
        assertEq(address(inscribe).balance, 0);
        assertEq(bob.balance, FEE);
    }

    function test_Withdraw() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        inscribe.inscribe{value: FEE}(_dataURI("artifact"));
        uint256 before = address(inscribe).balance;
        assertEq(before, FEE);
        vm.prank(owner);
        inscribe.withdraw();
        assertEq(address(inscribe).balance, 0);
    }
}
