// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {AuthoringMetaV2} from "rain-interpreter-interface-0.1.0/src/interface/IParserV2.sol";
import {LibDiaSubParser} from "../../../../src/lib/parse/LibDiaSubParser.sol";

contract LibDiaSubParserAuthoringMetaTest is Test {
    function testAuthoringMetaV2() external pure {
        AuthoringMetaV2[] memory authoringMeta = abi.decode(LibDiaSubParser.authoringMetaV2(), (AuthoringMetaV2[]));

        assertEq(authoringMeta.length, 1);
        assertEq(authoringMeta[0].word, bytes32("dia-price"));
        assertTrue(bytes(authoringMeta[0].description).length > 0);
        assertEq(
            authoringMeta[0].description,
            "Returns the current price of the given asset according to DIA. Accepts 2 inputs, the price key as a string (e.g. \"AMZN\") and the timeout in seconds. The price has 18 decimal places. The timeout will be used to determine if the price is stale and revert if it is. Returns 2 outputs: the price and the timestamp of the last update."
        );
    }
}
