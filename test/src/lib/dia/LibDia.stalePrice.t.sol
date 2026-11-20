// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia, StaleDiaPrice} from "src/lib/dia/LibDia.sol";
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

/// @dev External wrapper so `vm.expectRevert` applies to a real external call
/// into the library rather than an internal jump.
contract LibDiaStalePriceExternalWrapper {
    function getPriceNoOlderThan(IntOrAString feedKey, Float staleAfter)
        external
        view
        returns (Float price, Float updatedAt)
    {
        return LibDia.getPriceNoOlderThan(feedKey, staleAfter);
    }
}

contract LibDiaStalePriceTest is Test {
    /// @notice A price older than `staleAfter` seconds reverts with
    /// `StaleDiaPrice(rawTimestamp, staleAfter)`.
    function testGetPriceStaleReverts() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(8453);
        // One second past the tolerance: age = staleAfter + 1.
        vm.warp(DIA_BTC_USD_TIMESTAMP + 3601);

        LibDiaStalePriceExternalWrapper wrapper = new LibDiaStalePriceExternalWrapper();
        IntOrAString key = fromStringV3("BTC/USD");
        Float staleAfter = LibDecimalFloat.packLossless(3600, 0);

        vm.expectRevert(abi.encodeWithSelector(StaleDiaPrice.selector, uint128(DIA_BTC_USD_TIMESTAMP), uint256(3600)));
        wrapper.getPriceNoOlderThan(key, staleAfter);
    }
}
