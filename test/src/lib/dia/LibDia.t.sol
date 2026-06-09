// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia, IDIAOracleV2, UnsupportedChainId} from "src/lib/dia/LibDia.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {Float, LibDecimalFloat} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
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
