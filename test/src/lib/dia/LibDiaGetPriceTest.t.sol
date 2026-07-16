// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {
    LibDia,
    StaleDiaPrice,
    ZeroDiaPrice,
    InvalidDiaString,
    InvalidDiaTimestamp
} from "../../../../src/lib/dia/LibDia.sol";
import {IDIAOracleV2} from "../../../../src/lib/dia/IDIAOracleV2.sol";
import {Float, LibDecimalFloat} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {FORK_BLOCK_BASE, forkRpcUrlBase} from "../../../lib/LibFork.sol";
import {LibFromStringV3} from "../../../lib/LibFromStringV3.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";

/// @dev Hardcoded prices are pinned to a Base fork snapshot (see comments on each test).
/// Oracle: 0xCE521b52513242c5094bc56f57887BB2A05B8129 (LibDia.ORACLE_BASE).
/// Fork block: `FORK_BLOCK_BASE` in `test/lib/LibFork.sol` (47365950 at time of pin).
/// Reproduce: cast call 0xCE521b52513242c5094bc56f57887BB2A05B8129
/// "getValue(string)(uint128,uint128)" SYMBOL --rpc-url $BASE_RPC_URL --block $FORK_BLOCK_BASE
/// When changing `FORK_BLOCK_BASE`, re-run that command per symbol and update the raw
/// uint128 price literals below (first return value; 18 decimals).
contract LibDiaGetPriceTest is Test {
    function setUp() external {
        vm.createSelectFork(forkRpcUrlBase(vm), FORK_BLOCK_BASE);
        vm.chainId(LibDia.CHAIN_ID_BASE);
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

    /// raw price 238650000000000005680 (~$238.65); update timestamp at fork block.
    function testGetPriceAmzn() external view {
        _assertFeedPrice("AMZN", 238650000000000005680);
    }

    /// raw price 208969999999999998864 (~$208.97); update timestamp at fork block.
    function testGetPriceNvda() external view {
        _assertFeedPrice("NVDA", 208969999999999998864);
    }

    /// raw price 159810000000000002272 (~$159.81); update timestamp at fork block.
    function testGetPriceCoin() external view {
        _assertFeedPrice("COIN", 159810000000000002272);
    }

    /// raw price 124269999999999996024 (~$124.27); update timestamp at fork block.
    function testGetPriceMstr() external view {
        _assertFeedPrice("MSTR", 124269999999999996024);
    }

    /// raw price 405800000000000011360 (~$405.80); update timestamp at fork block.
    function testGetPriceTsla() external view {
        _assertFeedPrice("TSLA", 405800000000000011360);
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
