// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia, DiaPriceBefore, ZeroDiaPrice} from "src/lib/dia/LibDia.sol";
import {IDIAOracleV2} from "src/lib/dia/IDIAOracleV2.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {Float, LibDecimalFloat} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {FORK_RPC_URL_BASE, FORK_BLOCK_BASE, DIA_BTC_USD_TIMESTAMP} from "test/lib/LibFork.sol";
import {fromStringV3} from "test/src/lib/dia/LibDia.fromStringV3.sol";
import {LibDiaGetOracleContractExternalWrapper} from "test/src/lib/dia/LibDiaGetOracleContractExternalWrapper.sol";

contract LibDiaGetPriceTest is Test {
    function testGetPriceBtcUsd() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(8453);
        vm.warp(DIA_BTC_USD_TIMESTAMP + 60);

        IntOrAString key = fromStringV3("BTC/USD");
        Float staleAfter = LibDecimalFloat.packLossless(3600, 0);

        (Float price, Float updatedAt) = LibDia.getPriceNoOlderThan(key, staleAfter);

        assertTrue(Float.unwrap(price) != 0, "price should be non-zero");
        assertTrue(Float.unwrap(updatedAt) != 0, "timestamp should be non-zero");

        assertEq(
            Float.unwrap(price),
            Float.unwrap(LibDecimalFloat.packLossless(int256(uint256(7568457939217)), -8)),
            "unexpected BTC price"
        );
    }

    function testGetPriceUpdatedAfterAcceptsBoundaryTimestamp() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(8453);
        vm.warp(DIA_BTC_USD_TIMESTAMP + 60);

        IntOrAString key = fromStringV3("BTC/USD");
        Float minimumUpdatedAt = LibDecimalFloat.packLossless(int256(DIA_BTC_USD_TIMESTAMP), 0);
        Float staleAfter = LibDecimalFloat.packLossless(3600, 0);

        (Float price, Float updatedAt) = LibDia.getPriceNoOlderThanAndUpdatedAfter(key, minimumUpdatedAt, staleAfter);

        assertTrue(Float.unwrap(price) != 0, "price should be non-zero");
        assertEq(
            Float.unwrap(updatedAt),
            Float.unwrap(LibDecimalFloat.packLossless(int256(DIA_BTC_USD_TIMESTAMP), 0)),
            "unexpected update timestamp"
        );
    }

    function testGetPriceUpdatedAfterRejectsEarlierTimestamp() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(8453);
        vm.warp(DIA_BTC_USD_TIMESTAMP + 60);

        IntOrAString key = fromStringV3("BTC/USD");
        Float minimumUpdatedAt = LibDecimalFloat.packLossless(int256(DIA_BTC_USD_TIMESTAMP + 1), 0);
        Float staleAfter = LibDecimalFloat.packLossless(3600, 0);

        assertEq(
            LibDecimalFloat.toFixedDecimalLossless(minimumUpdatedAt, 0),
            DIA_BTC_USD_TIMESTAMP + 1,
            "minimum timestamp should roundtrip"
        );

        LibDiaGetOracleContractExternalWrapper wrapper = new LibDiaGetOracleContractExternalWrapper();

        vm.expectRevert(
            abi.encodeWithSelector(DiaPriceBefore.selector, uint128(DIA_BTC_USD_TIMESTAMP), DIA_BTC_USD_TIMESTAMP + 1)
        );
        wrapper.getPriceNoOlderThanAndUpdatedAfter(key, minimumUpdatedAt, staleAfter);
    }

    function testGetPriceRejectsZeroPriceWithRecentTimestamp() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(8453);
        vm.warp(DIA_BTC_USD_TIMESTAMP + 60);

        string memory keyString = "BTC/USD";
        IntOrAString key = fromStringV3(keyString);
        Float minimumUpdatedAt = LibDecimalFloat.packLossless(int256(DIA_BTC_USD_TIMESTAMP), 0);
        Float staleAfter = LibDecimalFloat.packLossless(3600, 0);

        vm.mockCall(
            address(LibDia.ORACLE_BASE),
            abi.encodeCall(IDIAOracleV2.getValue, (keyString)),
            abi.encode(uint128(0), uint128(DIA_BTC_USD_TIMESTAMP))
        );

        LibDiaGetOracleContractExternalWrapper wrapper = new LibDiaGetOracleContractExternalWrapper();

        vm.expectRevert(abi.encodeWithSelector(ZeroDiaPrice.selector, keyString));
        wrapper.getPriceNoOlderThanAndUpdatedAfter(key, minimumUpdatedAt, staleAfter);
    }
}
