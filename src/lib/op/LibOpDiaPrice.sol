// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {OperandV2, StackItem} from "rain-interpreter-interface-0.1.0/src/interface/IInterpreterV4.sol";
import {LibIntOrAString, IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {LibDia} from "../dia/LibDia.sol";
import {Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";

/// @dev Thrown when the DIA price extern is called with an input count other
/// than the 2 (feed key, stale-after) that `integrity` declares.
error BadDiaPriceInputs(uint256 length);

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
        // A direct extern call is not bound by integrity checks, so fail
        // closed on arity before the assembly reads below can interpret
        // adjacent memory as the feed key or stale-after.
        if (inputs.length != 2) {
            revert BadDiaPriceInputs(inputs.length);
        }
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
