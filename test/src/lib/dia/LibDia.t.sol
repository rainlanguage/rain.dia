// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibDia, IDIAOracleV2, UnsupportedChainId} from "src/lib/dia/LibDia.sol";
import {IntOrAString} from "rain.intorastring/lib/LibIntOrAString.sol";
import {Float, LibDecimalFloat} from "rain.math.float/lib/LibDecimalFloat.sol";
import {FORK_RPC_URL_BASE, FORK_BLOCK_BASE} from "test/lib/LibFork.sol";

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
        IntOrAString encoded = fromStringV3("AMZN");
        string memory decoded = LibDia.intOrAStringToString(encoded);
        assertEq(decoded, "AMZN");
    }

    function testRoundTripNVDA() external pure {
        IntOrAString encoded = fromStringV3("NVDA");
        string memory decoded = LibDia.intOrAStringToString(encoded);
        assertEq(decoded, "NVDA");
    }
}

contract LibDiaGetPriceTest is Test {
    function setUp() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(8453);
    }

    function _assertFeedPrice(string memory symbol, uint256 rawPrice) internal view {
        IntOrAString key = fromStringV3(symbol);
        Float staleAfter = LibDecimalFloat.packLossless(3600, 0);

        (Float price, Float updatedAt) = LibDia.getPriceNoOlderThan(key, staleAfter);

        assertTrue(Float.unwrap(price) != 0, "price should be non-zero");
        assertTrue(Float.unwrap(updatedAt) != 0, "timestamp should be non-zero");
        assertEq(
            Float.unwrap(price),
            Float.unwrap(LibDecimalFloat.packLossless(int256(rawPrice), -18)),
            string.concat("unexpected ", symbol, " price")
        );
    }

    function testGetPriceAmzn() external {
        _assertFeedPrice("AMZN", 264100000000000022736);
    }

    function testGetPriceNvda() external {
        _assertFeedPrice("NVDA", 225389999999999986352);
    }

    function testGetPriceCoin() external {
        _assertFeedPrice("COIN", 195539999999999992048);
    }

    function testGetPriceMstr() external {
        _assertFeedPrice("MSTR", 177455000000000012512);
    }

    function testGetPriceTsla() external {
        _assertFeedPrice("TSLA", 422350000000000022752);
    }
}
