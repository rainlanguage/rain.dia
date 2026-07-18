// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibOpDiaPrice, BadDiaPriceInputs, OperandV2, StackItem} from "src/lib/op/LibOpDiaPrice.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {FORK_RPC_URL_BASE, FORK_BLOCK_BASE, DIA_BTC_USD_TIMESTAMP} from "test/lib/LibFork.sol";
import {Float, LibDecimalFloat} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";

function fromStringV3(string memory s) pure returns (IntOrAString intOrAString) {
    assembly ("memory-safe") {
        let length := and(mload(s), 0x1f)
        mstore(0, or(0xe0, length))
        mcopy(sub(0x20, add(length, 1)), add(s, 0x20), length)
        intOrAString := mload(0)
    }
}

contract LibOpDiaPriceTest is Test {
    function testIntegrity(OperandV2 operand, uint256 inputs, uint256 outputs) external pure {
        (uint256 calculatedInputs, uint256 calculatedOutputs) = LibOpDiaPrice.integrity(operand, inputs, outputs);
        assertEq(calculatedInputs, 2);
        assertEq(calculatedOutputs, 2);
    }

    function runExternal(OperandV2 operand, StackItem[] memory inputs) external view returns (StackItem[] memory) {
        return LibOpDiaPrice.run(operand, inputs);
    }

    /// Any input count other than the 2 that `integrity` declares reverts
    /// before the assembly loads can read adjacent memory. The revert carries
    /// the actual length, and fires with no oracle (or fork) present at all,
    /// proving nothing is read past the guard.
    function testRunBadArityReverts(uint8 length) external {
        vm.assume(length != 2);
        StackItem[] memory inputs = new StackItem[](length);
        vm.expectRevert(abi.encodeWithSelector(BadDiaPriceInputs.selector, uint256(length)));
        this.runExternal(OperandV2.wrap(0), inputs);
    }

    /// The zero- and one-input direct-call cases from the audit finding, with
    /// the one-input case carrying a real feed key to show the guard fires on
    /// arity, not on content.
    function testRunZeroAndOneInputRevert() external {
        StackItem[] memory zeroInputs = new StackItem[](0);
        vm.expectRevert(abi.encodeWithSelector(BadDiaPriceInputs.selector, 0));
        this.runExternal(OperandV2.wrap(0), zeroInputs);

        StackItem[] memory oneInput = new StackItem[](1);
        oneInput[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(fromStringV3("BTC/USD"))));
        vm.expectRevert(abi.encodeWithSelector(BadDiaPriceInputs.selector, 1));
        this.runExternal(OperandV2.wrap(0), oneInput);
    }

    function testRunForkCurrentPriceHappy() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(8453);
        vm.warp(DIA_BTC_USD_TIMESTAMP + 60);

        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(fromStringV3("BTC/USD"))));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(3600, 0)));

        StackItem[] memory outputs = LibOpDiaPrice.run(OperandV2.wrap(0), inputs);
        assertEq(outputs.length, 2);

        assertTrue(StackItem.unwrap(outputs[0]) != bytes32(0), "price should be non-zero");
        assertTrue(StackItem.unwrap(outputs[1]) != bytes32(0), "timestamp should be non-zero");
    }
}
