// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {
    LibDia, StaleDiaPrice, ZeroDiaPrice, InvalidDiaString, InvalidDiaTimestamp
} from "../../../../src/lib/dia/LibDia.sol";
import {IDIAOracleV2} from "../../../../src/lib/dia/IDIAOracleV2.sol";
import {Float, LibDecimalFloat} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {FORK_RPC_URL_BASE, FORK_BLOCK_BASE} from "../../../lib/LibFork.sol";
import {LibFromStringV3} from "../../../lib/LibFromStringV3.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";

/// @dev Hardcoded prices are pinned to a Base fork snapshot (see comments on each test).
/// Oracle: 0xCE521b52513242c5094bc56f57887BB2A05B8129 (LibDia.ORACLE_BASE).
/// Fork block: 46061133 (block.timestamp 1778911613, 2026-05-16 06:06:53 UTC).
/// Reproduce: cast call 0xCE521b52513242c5094bc56f57887BB2A05B8129
/// "getValue(string)(uint128,uint128)" SYMBOL --rpc-url https://mainnet.base.org --block 46061133
/// When changing FORK_BLOCK_BASE in test/lib/LibFork.sol, re-run that command per symbol and
/// update the raw uint128 price literals below (first return value; 18 decimals).
contract LibDiaGetPriceTest is Test {
    function setUp() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(8453);
    }

    /// @dev Asserts getValue(key) raw price at the fork block matches `rawPrice` (18-decimal uint128).
    function _assertFeedPrice(string memory symbol, uint256 rawPrice) internal view {
        Float staleAfter = LibDecimalFloat.packLossless(3600, 0);

        (Float price, Float updatedAt) = LibDia.getPriceNoOlderThan(LibFromStringV3.fromStringV3(symbol), staleAfter);

        assertTrue(Float.unwrap(price) != 0, "price should be non-zero");
        assertTrue(Float.unwrap(updatedAt) != 0, "timestamp should be non-zero");
        assertEq(
            Float.unwrap(price),
            Float.unwrap(LibDecimalFloat.packLossless(int256(rawPrice), -18)),
            string.concat("unexpected ", symbol, " price")
        );
    }

    function getPriceNoOlderThanExternal(IntOrAString feedKey, Float staleAfter)
        external
        view
        returns (Float price, Float updatedAt)
    {
        return LibDia.getPriceNoOlderThan(feedKey, staleAfter);
    }

    function _mockValue(string memory key, uint128 rawPrice, uint128 rawTimestamp) internal {
        vm.mockCall(
            address(LibDia.ORACLE_BASE),
            abi.encodeCall(IDIAOracleV2.getValue, (key)),
            abi.encode(rawPrice, rawTimestamp)
        );
    }

    function _getPrice(string memory key, uint256 staleAfter) internal view returns (Float price, Float updatedAt) {
        return LibDia.getPriceNoOlderThan(
            LibFromStringV3.fromStringV3(key), LibDecimalFloat.packLossless(int256(staleAfter), 0)
        );
    }

    /// raw price 264100000000000022736 (~$264.10); update timestamp 1778908932 at fork block.
    function testGetPriceAmzn() external {
        _assertFeedPrice("AMZN", 264100000000000022736);
    }

    /// raw price 225389999999999986352 (~$225.39); update timestamp 1778908933 at fork block.
    function testGetPriceNvda() external {
        _assertFeedPrice("NVDA", 225389999999999986352);
    }

    /// raw price 195539999999999992048 (~$195.54); update timestamp 1778908934 at fork block.
    function testGetPriceCoin() external {
        _assertFeedPrice("COIN", 195539999999999992048);
    }

    /// raw price 177455000000000012512 (~$177.46); update timestamp 1778908935 at fork block.
    function testGetPriceMstr() external {
        _assertFeedPrice("MSTR", 177455000000000012512);
    }

    /// raw price 422350000000000022752 (~$422.35); update timestamp 1778908936 at fork block.
    function testGetPriceTsla() external {
        _assertFeedPrice("TSLA", 422350000000000022752);
    }

    function testStalePriceReverts() external {
        vm.warp(1000);
        _mockValue("TEST", 1e18, 899);

        vm.expectRevert(abi.encodeWithSelector(StaleDiaPrice.selector, uint128(899), uint256(100)));
        this.getPriceNoOlderThanExternal(LibFromStringV3.fromStringV3("TEST"), LibDecimalFloat.packLossless(100, 0));
    }

    function testExactStaleBoundaryReverts() external {
        vm.warp(1000);
        _mockValue("TEST", 1e18, 900);

        vm.expectRevert(abi.encodeWithSelector(StaleDiaPrice.selector, uint128(900), uint256(100)));
        this.getPriceNoOlderThanExternal(LibFromStringV3.fromStringV3("TEST"), LibDecimalFloat.packLossless(100, 0));
    }

    function testJustInsideStaleBoundarySucceeds() external {
        vm.warp(1000);
        _mockValue("TEST", 1e18, 901);

        (Float price, Float updatedAt) = _getPrice("TEST", 100);

        assertEq(Float.unwrap(price), Float.unwrap(LibDecimalFloat.packLossless(1e18, -18)));
        assertEq(Float.unwrap(updatedAt), Float.unwrap(LibDecimalFloat.packLossless(901, 0)));
    }

    function testUnknownKeyRevertsZeroDiaPrice() external {
        _mockValue("UNKNOWN", 0, 0);

        vm.expectRevert(abi.encodeWithSelector(ZeroDiaPrice.selector, "UNKNOWN"));
        this.getPriceNoOlderThanExternal(LibFromStringV3.fromStringV3("UNKNOWN"), LibDecimalFloat.packLossless(100, 0));
    }

    function testEmptyKeyRevertsZeroDiaPrice() external {
        _mockValue("", 0, 0);

        vm.expectRevert(abi.encodeWithSelector(ZeroDiaPrice.selector, ""));
        this.getPriceNoOlderThanExternal(LibFromStringV3.fromStringV3(""), LibDecimalFloat.packLossless(100, 0));
    }

    function testZeroPriceWithTimestampRevertsZeroDiaPrice() external {
        _mockValue("TEST", 0, uint128(block.timestamp));

        vm.expectRevert(abi.encodeWithSelector(ZeroDiaPrice.selector, "TEST"));
        this.getPriceNoOlderThanExternal(LibFromStringV3.fromStringV3("TEST"), LibDecimalFloat.packLossless(100, 0));
    }

    function testZeroTimestampReverts() external {
        _mockValue("TEST", 1e18, 0);

        vm.expectRevert(abi.encodeWithSelector(InvalidDiaTimestamp.selector, uint128(0)));
        this.getPriceNoOlderThanExternal(
            LibFromStringV3.fromStringV3("TEST"), LibDecimalFloat.packLossless(int256(uint256(type(uint128).max)), 0)
        );
    }

    function testFutureTimestampReverts() external {
        uint128 futureTimestamp = uint128(block.timestamp + 1);
        _mockValue("TEST", 1e18, futureTimestamp);

        vm.expectRevert(abi.encodeWithSelector(InvalidDiaTimestamp.selector, futureTimestamp));
        this.getPriceNoOlderThanExternal(LibFromStringV3.fromStringV3("TEST"), LibDecimalFloat.packLossless(100, 0));
    }

    function testInvalidStringRevertsBeforeOracleLookup() external {
        vm.chainId(1);
        IntOrAString invalid = IntOrAString.wrap(0);

        vm.expectRevert(abi.encodeWithSelector(InvalidDiaString.selector, invalid));
        this.getPriceNoOlderThanExternal(invalid, LibDecimalFloat.packLossless(100, 0));
    }
}
