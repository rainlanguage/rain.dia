// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibOpDiaPrice, OperandV2, StackItem, BadDiaPriceInputs} from "../../../../src/lib/op/LibOpDiaPrice.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {FORK_RPC_URL_BASE, FORK_BLOCK_BASE} from "../../../lib/LibFork.sol";
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

    function testRunRejectsInvalidInputLength(uint256 inputsLength) external {
        inputsLength = bound(inputsLength, 0, 3);
        vm.assume(inputsLength != 2);

        StackItem[] memory inputs = new StackItem[](inputsLength);
        vm.expectRevert(abi.encodeWithSelector(BadDiaPriceInputs.selector, inputsLength));
        this.runExternal(inputs);
    }

    function testRunForkCurrentPriceHappy() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(8453);

        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibFromStringV3.fromStringV3("AMZN"))));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(3600, 0)));

        StackItem[] memory outputs = LibOpDiaPrice.run(OperandV2.wrap(0), inputs);
        assertEq(outputs.length, 2);

        assertTrue(StackItem.unwrap(outputs[0]) != bytes32(0), "price should be non-zero");
        assertTrue(StackItem.unwrap(outputs[1]) != bytes32(0), "timestamp should be non-zero");
    }
}
