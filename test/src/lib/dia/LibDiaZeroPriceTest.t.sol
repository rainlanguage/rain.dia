// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia, IDIAOracleV2, ZeroDiaPrice} from "src/lib/dia/LibDia.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {Float, LibDecimalFloat} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {fromStringV3} from "test/src/lib/dia/FromStringV3.sol";
import {LibDiaGetPriceNoOlderThanExternalWrapper} from "test/src/lib/dia/LibDiaGetPriceNoOlderThanExternalWrapper.sol";

contract LibDiaZeroPriceTest is Test {
    LibDiaGetPriceNoOlderThanExternalWrapper internal wrapper;

    function setUp() external {
        wrapper = new LibDiaGetPriceNoOlderThanExternalWrapper();
        vm.chainId(LibDia.CHAIN_ID_BASE);
        vm.warp(1700000000);
        vm.etch(address(LibDia.ORACLE_BASE), hex"00");
    }

    function mockGetValue(string memory key, uint128 rawPrice, uint128 rawTimestamp) internal {
        vm.mockCall(
            address(LibDia.ORACLE_BASE),
            abi.encodeWithSelector(IDIAOracleV2.getValue.selector, key),
            abi.encode(rawPrice, rawTimestamp)
        );
    }

    /// A zero price with a fresh timestamp is not a usable price and reverts.
    function testZeroPriceFreshTimestampReverts() external {
        mockGetValue("BTC/USD", 0, uint128(block.timestamp));
        vm.expectRevert(abi.encodeWithSelector(ZeroDiaPrice.selector, "BTC/USD"));
        wrapper.getPriceNoOlderThan(fromStringV3("BTC/USD"), LibDecimalFloat.packLossless(3600, 0));
    }

    /// A zero price reverts regardless of the timestamp; the zero check runs
    /// before the staleness check, so stale and even future timestamps still
    /// surface ZeroDiaPrice rather than StaleDiaPrice or an underflow panic.
    function testZeroPriceAnyTimestampReverts(uint128 rawTimestamp) external {
        mockGetValue("ETH/USD", 0, rawTimestamp);
        vm.expectRevert(abi.encodeWithSelector(ZeroDiaPrice.selector, "ETH/USD"));
        wrapper.getPriceNoOlderThan(fromStringV3("ETH/USD"), LibDecimalFloat.packLossless(3600, 0));
    }

    /// A nonzero fresh price passes the zero guard and returns floats.
    function testNonZeroFreshPriceReturns() external {
        mockGetValue("BTC/USD", 7568457939217, uint128(block.timestamp));
        (Float price, Float updatedAt) =
            wrapper.getPriceNoOlderThan(fromStringV3("BTC/USD"), LibDecimalFloat.packLossless(3600, 0));
        assertEq(
            Float.unwrap(price),
            Float.unwrap(LibDecimalFloat.packLossless(int256(uint256(7568457939217)), -8)),
            "unexpected price"
        );
        assertEq(
            Float.unwrap(updatedAt),
            Float.unwrap(LibDecimalFloat.packLossless(int256(block.timestamp), 0)),
            "unexpected timestamp"
        );
    }
}
