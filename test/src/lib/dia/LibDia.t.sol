// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia, IDIAOracleV2, UnsupportedChainId, ZeroDiaPrice} from "src/lib/dia/LibDia.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {Float, LibDecimalFloat} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {FORK_RPC_URL_BASE, FORK_BLOCK_BASE, DIA_BTC_USD_TIMESTAMP} from "test/lib/LibFork.sol";

/// @dev Create a V3-encoded IntOrAString matching the latest Rain parser output.
/// Layout: string data right-aligned above the low byte, low byte = 0xE0 | length.
function fromStringV3(string memory s) pure returns (IntOrAString intOrAString) {
    assembly ("memory-safe") {
        let length := and(mload(s), 0x1f)
        mstore(0, or(0xe0, length))
        mcopy(sub(0x20, add(length, 1)), add(s, 0x20), length)
        intOrAString := mload(0)
    }
}

contract LibDiaGetOracleContractExternalWrapper {
    function getOracleContract(uint256 chainId) external pure returns (IDIAOracleV2) {
        return LibDia.getOracleContract(chainId);
    }
}

contract LibDiaGetOracleContractTest is Test {
    function testGetOracleContractBase() external pure {
        IDIAOracleV2 oracle = LibDia.getOracleContract(8453);
        assertEq(address(oracle), address(LibDia.ORACLE_BASE));
    }

    function testGetOracleContractUnsupported() external {
        LibDiaGetOracleContractExternalWrapper wrapper = new LibDiaGetOracleContractExternalWrapper();
        vm.expectRevert(UnsupportedChainId.selector);
        wrapper.getOracleContract(1);
    }
}

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

contract LibDiaGetPriceNoOlderThanExternalWrapper {
    function getPriceNoOlderThan(IntOrAString feedKey, Float staleAfter) external view returns (Float, Float) {
        return LibDia.getPriceNoOlderThan(feedKey, staleAfter);
    }
}

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
}
