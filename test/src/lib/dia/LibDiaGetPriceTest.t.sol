// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia} from "src/lib/dia/LibDia.sol";
import {Float, LibDecimalFloat} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {FORK_RPC_URL_BASE, FORK_BLOCK_BASE} from "test/lib/LibFork.sol";
import {LibFromStringV3} from "test/lib/LibFromStringV3.sol";

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
}
