// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia, IDIAOracleV2, UnsupportedChainId, StaleDiaPrice, ZeroDiaPrice} from "src/lib/dia/LibDia.sol";
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
    function getPriceNoOlderThan(IntOrAString feedKey, Float staleAfter)
        external
        view
        returns (Float price, Float updatedAt)
    {
        return LibDia.getPriceNoOlderThan(feedKey, staleAfter);
    }
}

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
