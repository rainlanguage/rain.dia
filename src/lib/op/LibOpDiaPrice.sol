// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {OperandV2, StackItem} from "rain.interpreter.interface/interface/unstable/IInterpreterV4.sol";
import {LibIntOrAString, IntOrAString} from "rain.intorastring/lib/LibIntOrAString.sol";
import {LibDia} from "../dia/LibDia.sol";
import {Float} from "rain.math.float/lib/LibDecimalFloat.sol";

library LibOpDiaPrice {
    using LibIntOrAString for IntOrAString;

    /// Extern integrity for the DIA price operation.
    /// Always requires 2 inputs and produces 2 outputs.
    function integrity(OperandV2, uint256, uint256) internal pure returns (uint256, uint256) {
        return (2, 2);
    }

    /// Runs the DIA price operation.
    /// @param inputs the inputs to the extern.
    function run(OperandV2, StackItem[] memory inputs) internal view returns (StackItem[] memory) {
        IntOrAString symbol;
        Float staleAfter;
        assembly ("memory-safe") {
            symbol := mload(add(inputs, 0x20))
            staleAfter := mload(add(inputs, 0x40))
        }

        (Float price, Float updatedAt) = LibDia.getPriceNoOlderThan(symbol, staleAfter);

        StackItem[] memory outputs;
        assembly ("memory-safe") {
            outputs := mload(0x40)
            mstore(0x40, add(outputs, 0x60))
            mstore(outputs, 2)
            mstore(add(outputs, 0x20), price)
            mstore(add(outputs, 0x40), updatedAt)
        }
        return outputs;
    }
}
