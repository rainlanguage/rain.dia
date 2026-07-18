// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia} from "src/lib/dia/LibDia.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {fromStringV3} from "test/src/lib/dia/FromStringV3.sol";

contract LibDiaStringV3Test is Test {
    function testRoundTrip() external pure {
        IntOrAString encoded = fromStringV3("BTC/USD");
        string memory decoded = LibDia.intOrAStringToString(encoded);
        assertEq(decoded, "BTC/USD");
    }

    function testRoundTripETH() external pure {
        IntOrAString encoded = fromStringV3("ETH/USD");
        string memory decoded = LibDia.intOrAStringToString(encoded);
        assertEq(decoded, "ETH/USD");
    }

    /// The empty string is the low length boundary: the V3 word is just the
    /// truthy low byte 0xE0 and must decode back to a zero-length string.
    function testRoundTripEmpty() external pure {
        IntOrAString encoded = fromStringV3("");
        assertEq(IntOrAString.unwrap(encoded), 0xE0);
        string memory decoded = LibDia.intOrAStringToString(encoded);
        assertEq(bytes(decoded).length, 0);
        assertEq(decoded, "");
    }

    /// 31 characters is the max length representable in the 5 bit V3 length
    /// field; every byte must survive the round-trip.
    function testRoundTripMax31() external pure {
        string memory max31 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ01234";
        assertEq(bytes(max31).length, 31);
        IntOrAString encoded = fromStringV3(max31);
        string memory decoded = LibDia.intOrAStringToString(encoded);
        assertEq(bytes(decoded).length, 31);
        assertEq(decoded, max31);
    }
}
