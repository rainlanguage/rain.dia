// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia, InvalidDiaString} from "src/lib/dia/LibDia.sol";
import {LibFromStringV3} from "test/lib/LibFromStringV3.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";

contract LibDiaStringV3Test is Test {
    function intOrAStringToStringExternal(IntOrAString value) external pure returns (string memory) {
        return LibDia.intOrAStringToString(value);
    }

    function testRoundTrip() external pure {
        string memory decoded = LibDia.intOrAStringToString(LibFromStringV3.fromStringV3("AMZN"));
        assertEq(decoded, "AMZN");
    }

    function testRoundTripNVDA() external pure {
        string memory decoded = LibDia.intOrAStringToString(LibFromStringV3.fromStringV3("NVDA"));
        assertEq(decoded, "NVDA");
    }

    function testRoundTripEmpty() external pure {
        string memory decoded = LibDia.intOrAStringToString(LibFromStringV3.fromStringV3(""));
        assertEq(decoded, "");
    }

    function testRoundTrip31Bytes() external pure {
        string memory value = "1234567890123456789012345678901";
        string memory decoded = LibDia.intOrAStringToString(LibFromStringV3.fromStringV3(value));
        assertEq(decoded, value);
    }

    function testRejectsInvalidStringEncoding() external {
        IntOrAString invalid = IntOrAString.wrap(0);
        vm.expectRevert(abi.encodeWithSelector(InvalidDiaString.selector, invalid));
        this.intOrAStringToStringExternal(invalid);
    }
}
