// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibOpDiaPrice, OperandV2, StackItem, BadDiaPriceInputs} from "../../../../src/lib/op/LibOpDiaPrice.sol";
import {LibDia} from "../../../../src/lib/dia/LibDia.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {FORK_BLOCK_BASE, forkRpcUrlBase} from "../../../lib/LibFork.sol";
import {Float, LibDecimalFloat} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {LibFromStringV3} from "../../../lib/LibFromStringV3.sol";

contract LibOpDiaPriceTest is Test {
    function runExternal(StackItem[] memory inputs) external view returns (StackItem[] memory) {
        return LibOpDiaPrice.run(OperandV2.wrap(0), inputs);
    }

    function testIntegrity(OperandV2 operand, uint256 inputs, uint256 outputs) external pure {
        (uint256 calculatedInputs, uint256 calculatedOutputs) = LibOpDiaPrice.integrity(operand, inputs, outputs);
        assertEq(calculatedInputs, 2);
        assertEq(calculatedOutputs, 2);
    }

    /// Any input count other than the 2 that `integrity` declares reverts with
    /// the offending length, with no oracle or fork present, so nothing is read
    /// past the guard.
    function testRunRejectsInvalidInputLength(uint256 inputsLength) external {
        inputsLength = bound(inputsLength, 0, type(uint8).max);
        vm.assume(inputsLength != 2);

        StackItem[] memory inputs = new StackItem[](inputsLength);
        vm.expectRevert(abi.encodeWithSelector(BadDiaPriceInputs.selector, inputsLength));
        this.runExternal(inputs);
    }

    /// Zero and one input revert on arity alone. The one-input case carries a
    /// real feed key, so the revert does not depend on the input content.
    function testRunRejectsZeroAndOneInputs() external {
        StackItem[] memory zeroInputs = new StackItem[](0);
        vm.expectRevert(abi.encodeWithSelector(BadDiaPriceInputs.selector, uint256(0)));
        this.runExternal(zeroInputs);

        StackItem[] memory oneInput = new StackItem[](1);
        oneInput[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibFromStringV3.fromStringV3("AMZN"))));
        vm.expectRevert(abi.encodeWithSelector(BadDiaPriceInputs.selector, uint256(1)));
        this.runExternal(oneInput);
    }

    /// Lengths that share their low byte or low two bytes with the required 2
    /// are rejected like any other wrong arity; the guard compares the whole
    /// length rather than a narrowed copy of it.
    function testRunRejectsInputLengthAliasingTwo() external {
        uint256[2] memory aliasingLengths = [uint256(2) + (1 << 8), uint256(2) + (1 << 16)];

        for (uint256 i = 0; i < aliasingLengths.length; i++) {
            StackItem[] memory inputs = new StackItem[](aliasingLengths[i]);
            vm.expectRevert(abi.encodeWithSelector(BadDiaPriceInputs.selector, aliasingLengths[i]));
            this.runExternal(inputs);
        }
    }

    function testRunForkCurrentPriceHappy() external {
        vm.createSelectFork(forkRpcUrlBase(vm), FORK_BLOCK_BASE);
        vm.chainId(LibDia.CHAIN_ID_BASE);

        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibFromStringV3.fromStringV3("AMZN"))));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(3600, 0)));

        StackItem[] memory outputs = LibOpDiaPrice.run(OperandV2.wrap(0), inputs);
        assertEq(outputs.length, 2);

        assertEq(
            StackItem.unwrap(outputs[0]),
            Float.unwrap(LibDecimalFloat.packLossless(238650000000000005680, -18)),
            "unexpected AMZN price"
        );
        assertEq(
            StackItem.unwrap(outputs[1]),
            Float.unwrap(LibDecimalFloat.packLossless(1781520797, 0)),
            "unexpected AMZN timestamp"
        );
    }
}
