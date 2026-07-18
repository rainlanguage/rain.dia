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
        uint256 cursor = Pointer.unwrap(source.dataPointer());
        uint256 end = cursor + source.length;
        (, value) = state.parseLiteral(cursor, end);
    }

    function assertParserMatchesV3Encoding(string memory key) internal view {
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

    function testRainlangParserStringMatchesDiaWordsV3Encoding(bytes32 seed, uint8 length) external view {
        length = uint8(bound(length, 0, 31));
        bytes memory alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
        bytes memory keyBytes = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            keyBytes[i] = alphabet[uint8(seed[i]) % alphabet.length];
        }

        assertParserMatchesV3Encoding(string(keyBytes));
    }

    function testRainlangParserStringMatchesDiaWordsV3Encoding31Bytes() external view {
        assertParserMatchesV3Encoding("ABCDEFGHIJKLMNOPQRSTUVWXYZ12345");
    }
}
