// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {AuthoringMetaV2} from "rain-interpreter-interface-0.1.0/src/interface/deprecated/v1/IParserV1.sol";
import {LibGenParseMeta} from "rain-interpreter-interface-0.1.0/src/lib/codegen/LibGenParseMeta.sol";
import {LibDiaSubParser} from "src/lib/parse/LibDiaSubParser.sol";
import {PARSE_META, PARSE_META_BUILD_DEPTH} from "src/generated/DiaWords.pointers.sol";

contract DiaWordsPointersTest is Test {
    /// The committed PARSE_META constant must equal the parse meta regenerated
    /// from the live authoring meta, so a word/description edit that changes
    /// the bloom fingerprint cannot drift past CI while the committed constant
    /// serves stale lookups.
    function testSubParserParseMeta() external pure {
        AuthoringMetaV2[] memory authoringMeta = abi.decode(LibDiaSubParser.authoringMetaV2(), (AuthoringMetaV2[]));
        bytes memory expected = LibGenParseMeta.buildParseMetaV2(authoringMeta, PARSE_META_BUILD_DEPTH);
        assertEq(PARSE_META, expected);
        assertEq(uint8(PARSE_META[0]), PARSE_META_BUILD_DEPTH, "parse meta depth byte");
    }
}
