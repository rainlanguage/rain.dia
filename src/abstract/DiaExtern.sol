// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {
    BaseRainterpreterExternNPE2,
    OperandV2,
    StackItem
} from "rain.interpreter/abstract/BaseRainterpreterExternNPE2.sol";
import {LibOpDiaPrice} from "../lib/op/LibOpDiaPrice.sol";
import {LibConvert} from "rain.lib.typecast/LibConvert.sol";
import {OPCODE_FUNCTION_POINTERS, INTEGRITY_FUNCTION_POINTERS} from "../generated/DiaWords.pointers.sol";

uint256 constant OPCODE_DIA_PRICE = 0;

uint256 constant OPCODE_FUNCTION_POINTERS_LENGTH = 1;

abstract contract DiaExtern is BaseRainterpreterExternNPE2 {
    function opcodeFunctionPointers() internal pure override returns (bytes memory) {
        return OPCODE_FUNCTION_POINTERS;
    }

    function integrityFunctionPointers() internal pure override returns (bytes memory) {
        return INTEGRITY_FUNCTION_POINTERS;
    }

    function buildOpcodeFunctionPointers() external pure returns (bytes memory) {
        function(OperandV2, StackItem[] memory)
            internal
            view
            returns (StackItem[] memory)[] memory fs = new function(OperandV2, StackItem[] memory)
                internal
                view
                returns (StackItem[] memory)[](OPCODE_FUNCTION_POINTERS_LENGTH);
        fs[OPCODE_DIA_PRICE] = LibOpDiaPrice.run;

        uint256[] memory pointers;
        assembly ("memory-safe") {
            pointers := fs
        }
        return LibConvert.unsafeTo16BitBytes(pointers);
    }

    function buildIntegrityFunctionPointers() external pure returns (bytes memory) {
        function(OperandV2, uint256, uint256)
            internal
            pure
            returns (uint256, uint256)[] memory fs = new function(OperandV2, uint256, uint256)
                internal
                pure
                returns (uint256, uint256)[](OPCODE_FUNCTION_POINTERS_LENGTH);
        fs[OPCODE_DIA_PRICE] = LibOpDiaPrice.integrity;

        uint256[] memory pointers;
        assembly ("memory-safe") {
            pointers := fs
        }
        return LibConvert.unsafeTo16BitBytes(pointers);
    }
}
