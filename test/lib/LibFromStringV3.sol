// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";

/// @dev V3-encoded IntOrAString matching the latest Rain parser output.
/// Layout: string data right-aligned above the low byte, low byte = 0xE0 | length.
library LibFromStringV3 {
    function fromStringV3(string memory s) internal pure returns (IntOrAString intOrAString) {
        assembly ("memory-safe") {
            let length := and(mload(s), 0x1f)
            mstore(0, or(0xe0, length))
            mcopy(sub(0x20, add(length, 1)), add(s, 0x20), length)
            intOrAString := mload(0)
        }
    }
}
