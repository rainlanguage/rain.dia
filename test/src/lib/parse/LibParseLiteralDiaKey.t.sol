// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibBytes, Pointer} from "rain-solmem-0.1.3/src/lib/LibBytes.sol";
import {LibParseState, ParseState} from "rainlang-0.1.2/src/lib/parse/LibParseState.sol";
import {LibParseLiteral} from "rainlang-0.1.2/src/lib/parse/literal/LibParseLiteral.sol";
import {LibAllStandardOps} from "rainlang-0.1.2/src/lib/op/LibAllStandardOps.sol";
import {LibIntOrAString, IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {LibFromStringV3} from "test/lib/LibFromStringV3.sol";

/// @dev Pins rainlang parser string literals to the V3 IntOrAString encoding DiaWords consumes.
contract LibParseLiteralDiaKeyTest is Test {
    using LibBytes for bytes;
    using LibParseLiteral for ParseState;

    function parseStringLiteral(bytes memory source) internal view returns (bytes32 value) {
        ParseState memory state =
            LibParseState.newState(source, "", "", LibAllStandardOps.literalParserFunctionPointers());
        state.literalParsers = LibAllStandardOps.literalParserFunctionPointers();
        uint256 cursor = Pointer.unwrap(source.dataPointer());
        uint256 end = cursor + source.length;
        (, value) = state.parseLiteral(cursor, end);
    }

    function testRainlangParserStringMatchesDiaWordsV3Encoding(string memory key) external view {
        bytes memory keyBytes = bytes(key);
        vm.assume(keyBytes.length <= 31);
        for (uint256 i = 0; i < keyBytes.length; i++) {
            bytes1 char = keyBytes[i];
            vm.assume(
                (char >= 0x30 && char <= 0x39) || (char >= 0x41 && char <= 0x5a) || (char >= 0x61 && char <= 0x7a)
            );
        }

        bytes memory source = bytes(string.concat('"', key, '"'));
        bytes32 parsed = parseStringLiteral(source);

        assertEq(
            parsed,
            bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3(key))),
            "rainlang parser must emit V3 IntOrAString for feed keys"
        );
        assertEq(
            parsed,
            bytes32(IntOrAString.unwrap(LibFromStringV3.fromStringV3(key))),
            "test helper must match LibIntOrAString.fromStringV3"
        );
    }

    function testRainlangParserStringMatchesDiaWordsV3EncodingAmzn() external view {
        bytes32 parsed = parseStringLiteral(bytes('"AMZN"'));
        assertEq(parsed, bytes32(IntOrAString.unwrap(LibFromStringV3.fromStringV3("AMZN"))));
    }
}
