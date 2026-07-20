// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";

/// @dev Test helper that delegates to the production V3 encoder.
library LibFromStringV3 {
    function fromStringV3(string memory s) internal pure returns (IntOrAString) {
        return LibIntOrAString.fromStringV3(s);
    }
}
