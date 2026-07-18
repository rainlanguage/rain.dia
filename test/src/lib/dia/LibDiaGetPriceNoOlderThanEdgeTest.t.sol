// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia, IDIAOracleV2, StaleDiaPrice, ZeroDiaPrice} from "src/lib/dia/LibDia.sol";
import {Float, LibDecimalFloat} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {fromStringV3} from "test/src/lib/dia/FromStringV3.sol";
import {LibDiaGetPriceNoOlderThanExternalWrapper} from "test/src/lib/dia/LibDiaGetPriceNoOlderThanExternalWrapper.sol";

/// @notice Edge-case tests for `getPriceNoOlderThan` using a mocked oracle so
/// staleness boundaries and sentinel values can be pinned exactly without a
/// fork. Expected values are derived from the DIA oracle contract semantics:
/// `getValue` returns `(0, 0)` for keys it has never stored, and any stored
/// update has a non-zero timestamp; staleness is fail-safe, so a price aged
/// exactly `staleAfter` (or with no recorded update time at all) is stale.
contract LibDiaGetPriceNoOlderThanEdgeTest is Test {
    uint128 constant MOCK_PRICE = 7568457939217;
    uint128 constant MOCK_TIMESTAMP = 1744172776;
    uint256 constant STALE_AFTER = 3600;

    LibDiaGetPriceNoOlderThanExternalWrapper internal wrapper = new LibDiaGetPriceNoOlderThanExternalWrapper();

    function mockOracleValue(uint128 rawPrice, uint128 rawTimestamp) internal {
        vm.chainId(LibDia.CHAIN_ID_BASE);
        vm.mockCall(
            address(LibDia.ORACLE_BASE),
            abi.encodeWithSelector(IDIAOracleV2.getValue.selector, "BTC/USD"),
            abi.encode(rawPrice, rawTimestamp)
        );
    }

    /// elapsed == staleAfter is stale. Fail-safe at the exact boundary.
    function testGetPriceNoOlderThanStaleAtExactBoundary() external {
        mockOracleValue(MOCK_PRICE, MOCK_TIMESTAMP);
        vm.warp(uint256(MOCK_TIMESTAMP) + STALE_AFTER);

        vm.expectRevert(abi.encodeWithSelector(StaleDiaPrice.selector, MOCK_TIMESTAMP, STALE_AFTER));
        wrapper.getPriceNoOlderThan(fromStringV3("BTC/USD"), LibDecimalFloat.packLossless(int256(STALE_AFTER), 0));
    }

    /// elapsed == staleAfter + 1 is stale.
    function testGetPriceNoOlderThanStaleOnePastBoundary() external {
        mockOracleValue(MOCK_PRICE, MOCK_TIMESTAMP);
        vm.warp(uint256(MOCK_TIMESTAMP) + STALE_AFTER + 1);

        vm.expectRevert(abi.encodeWithSelector(StaleDiaPrice.selector, MOCK_TIMESTAMP, STALE_AFTER));
        wrapper.getPriceNoOlderThan(fromStringV3("BTC/USD"), LibDecimalFloat.packLossless(int256(STALE_AFTER), 0));
    }

    /// elapsed == staleAfter - 1 is fresh.
    function testGetPriceNoOlderThanFreshOneSecondInsideBoundary() external {
        mockOracleValue(MOCK_PRICE, MOCK_TIMESTAMP);
        vm.warp(uint256(MOCK_TIMESTAMP) + STALE_AFTER - 1);

        (Float price, Float updatedAt) =
            wrapper.getPriceNoOlderThan(fromStringV3("BTC/USD"), LibDecimalFloat.packLossless(int256(STALE_AFTER), 0));

        assertEq(
            Float.unwrap(price),
            Float.unwrap(LibDecimalFloat.packLossless(int256(uint256(MOCK_PRICE)), -8)),
            "unexpected price"
        );
        assertEq(
            Float.unwrap(updatedAt),
            Float.unwrap(LibDecimalFloat.packLossless(int256(uint256(MOCK_TIMESTAMP)), 0)),
            "unexpected updatedAt"
        );
    }

    /// A zero timestamp with a non-zero price is stale no matter how large
    /// `staleAfter` is: there is no recorded update time to be fresh relative
    /// to.
    function testGetPriceNoOlderThanZeroTimestampNonZeroPriceReverts() external {
        mockOracleValue(MOCK_PRICE, 0);
        vm.warp(MOCK_TIMESTAMP);
        // Far larger than block.timestamp, so `block.timestamp - 0` alone
        // would not trip the elapsed-time staleness check.
        uint256 hugeStaleAfter = 1e30;

        vm.expectRevert(abi.encodeWithSelector(StaleDiaPrice.selector, uint128(0), hugeStaleAfter));
        wrapper.getPriceNoOlderThan(fromStringV3("BTC/USD"), LibDecimalFloat.packLossless(int256(hugeStaleAfter), 0));
    }

    /// The all-zero unknown-key sentinel keeps its `ZeroDiaPrice` identity
    /// even though its timestamp is also zero.
    function testGetPriceNoOlderThanZeroPriceZeroTimestampRevertsZeroDiaPrice() external {
        mockOracleValue(0, 0);
        vm.warp(MOCK_TIMESTAMP);
        uint256 hugeStaleAfter = 1e30;

        vm.expectRevert(abi.encodeWithSelector(ZeroDiaPrice.selector, "BTC/USD"));
        wrapper.getPriceNoOlderThan(fromStringV3("BTC/USD"), LibDecimalFloat.packLossless(int256(hugeStaleAfter), 0));
    }
}
