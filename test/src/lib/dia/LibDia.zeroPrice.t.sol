// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibDia, ZeroDiaPrice} from "src/lib/dia/LibDia.sol";
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

/// @dev External wrapper so `vm.expectRevert` applies to a real external call
/// into the library rather than an internal jump.
contract LibDiaZeroPriceExternalWrapper {
    function getPriceNoOlderThan(IntOrAString feedKey, Float staleAfter)
        external
        view
        returns (Float price, Float updatedAt)
    {
        return LibDia.getPriceNoOlderThan(feedKey, staleAfter);
    }
}

contract LibDiaZeroPriceTest is Test {
    /// @notice A key the DIA oracle has no feed for returns `(0, 0)`, which
    /// reverts with `ZeroDiaPrice(key)` before any staleness logic runs.
    function testGetPriceUnknownKeyReverts() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(8453);

        LibDiaZeroPriceExternalWrapper wrapper = new LibDiaZeroPriceExternalWrapper();
        IntOrAString key = fromStringV3("FOO/BAR");
        Float staleAfter = LibDecimalFloat.packLossless(3600, 0);

        vm.expectRevert(abi.encodeWithSelector(ZeroDiaPrice.selector, "FOO/BAR"));
        wrapper.getPriceNoOlderThan(key, staleAfter);
    }

    /// @notice The empty key also has no feed, so it reverts with
    /// `ZeroDiaPrice("")`.
    function testGetPriceEmptyKeyReverts() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(8453);

        LibDiaZeroPriceExternalWrapper wrapper = new LibDiaZeroPriceExternalWrapper();
        IntOrAString key = fromStringV3("");
        Float staleAfter = LibDecimalFloat.packLossless(3600, 0);

        vm.expectRevert(abi.encodeWithSelector(ZeroDiaPrice.selector, ""));
        wrapper.getPriceNoOlderThan(key, staleAfter);
    }
}
