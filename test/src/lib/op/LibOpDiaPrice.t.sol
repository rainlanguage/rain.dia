// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibOpDiaPrice, OperandV2, StackItem} from "src/lib/op/LibOpDiaPrice.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {FORK_RPC_URL_BASE, FORK_BLOCK_BASE, DIA_BTC_USD_TIMESTAMP} from "test/lib/LibFork.sol";
import {Float, LibDecimalFloat} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {fromStringV3} from "test/src/lib/dia/LibDia.fromStringV3.sol";

contract LibOpDiaPriceTest is Test {
    function testIntegrity(OperandV2 operand, uint256 inputs, uint256 outputs) external pure {
        (uint256 calculatedInputs, uint256 calculatedOutputs) = LibOpDiaPrice.integrity(operand, inputs, outputs);
        assertEq(calculatedInputs, 2);
        assertEq(calculatedOutputs, 2);
    }

    function testIntegrityAfter(OperandV2 operand, uint256 inputs, uint256 outputs) external pure {
        (uint256 calculatedInputs, uint256 calculatedOutputs) = LibOpDiaPrice.integrityAfter(operand, inputs, outputs);
        assertEq(calculatedInputs, 3);
        assertEq(calculatedOutputs, 2);
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

    function testRunAfterForkCurrentPriceHappy() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(8453);
        vm.warp(DIA_BTC_USD_TIMESTAMP + 60);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(fromStringV3("BTC/USD"))));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(int256(DIA_BTC_USD_TIMESTAMP), 0)));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(3600, 0)));

        StackItem[] memory outputs = LibOpDiaPrice.runAfter(OperandV2.wrap(0), inputs);
        assertEq(outputs.length, 2);

        assertTrue(StackItem.unwrap(outputs[0]) != bytes32(0), "price should be non-zero");
        assertEq(
            StackItem.unwrap(outputs[1]),
            Float.unwrap(LibDecimalFloat.packLossless(int256(DIA_BTC_USD_TIMESTAMP), 0)),
            "timestamp should match DIA update"
        );
    }
}
