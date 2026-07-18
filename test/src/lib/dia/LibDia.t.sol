// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia, IDIAOracleV2, UnsupportedChainId} from "src/lib/dia/LibDia.sol";
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

    /// The empty string is the low length boundary: the V3 word is just the
    /// truthy low byte 0xE0 and must decode back to a zero-length string.
    function testRoundTripEmpty() external pure {
        IntOrAString encoded = fromStringV3("");
        assertEq(IntOrAString.unwrap(encoded), 0xE0);
        string memory decoded = LibDia.intOrAStringToString(encoded);
        assertEq(bytes(decoded).length, 0);
        assertEq(decoded, "");
    }

    /// 31 characters is the max length representable in the 5 bit V3 length
    /// field; every byte must survive the round-trip.
    function testRoundTripMax31() external pure {
        string memory max31 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ01234";
        assertEq(bytes(max31).length, 31);
        IntOrAString encoded = fromStringV3(max31);
        string memory decoded = LibDia.intOrAStringToString(encoded);
        assertEq(bytes(decoded).length, 31);
        assertEq(decoded, max31);
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
