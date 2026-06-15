// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia} from "src/lib/dia/LibDia.sol";
import {LibFromStringV3} from "test/lib/LibFromStringV3.sol";

contract LibDiaStringV3Test is Test {
    function testRoundTrip() external pure {
        string memory decoded = LibDia.intOrAStringToString(LibFromStringV3.fromStringV3("AMZN"));
        assertEq(decoded, "AMZN");
    }

    function testRoundTripNVDA() external pure {
        string memory decoded = LibDia.intOrAStringToString(LibFromStringV3.fromStringV3("NVDA"));
        assertEq(decoded, "NVDA");
    }
}
