// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibDia} from "src/lib/dia/LibDia.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";

contract LibDiaGetPriceNoOlderThanExternalWrapper {
    function getPriceNoOlderThan(IntOrAString feedKey, Float staleAfter) external view returns (Float, Float) {
        return LibDia.getPriceNoOlderThan(feedKey, staleAfter);
    }
}
