// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia} from "src/lib/dia/LibDia.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {fromStringV3} from "test/src/lib/dia/LibDiaFromStringV3.sol";

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
}
