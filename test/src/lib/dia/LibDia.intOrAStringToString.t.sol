// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia} from "src/lib/dia/LibDia.sol";
import {fromStringV3} from "test/src/lib/dia/LibDia.fromStringV3.sol";

contract LibDiaStringV3Test is Test {
    function testRoundTrip() external pure {
        assertEq(LibDia.intOrAStringToString(fromStringV3("BTC/USD")), "BTC/USD");
    }

    function testRoundTripETH() external pure {
        assertEq(LibDia.intOrAStringToString(fromStringV3("ETH/USD")), "ETH/USD");
    }
}
