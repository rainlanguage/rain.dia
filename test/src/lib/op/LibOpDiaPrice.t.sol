// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibOpDiaPrice, OperandV2, StackItem} from "src/lib/op/LibOpDiaPrice.sol";
import {IntOrAString} from "rain.intorastring/lib/LibIntOrAString.sol";
import {FORK_RPC_URL_BASE, FORK_BLOCK_BASE, DIA_BTC_USD_TIMESTAMP} from "test/lib/LibFork.sol";
import {Float, LibDecimalFloat} from "rain.math.float/lib/LibDecimalFloat.sol";

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
