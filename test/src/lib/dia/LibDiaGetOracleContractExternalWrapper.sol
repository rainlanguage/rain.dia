// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibDia, IDIAOracleV2} from "src/lib/dia/LibDia.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";

contract LibDiaGetOracleContractExternalWrapper {
    function getOracleContract(uint256 chainId) external pure returns (IDIAOracleV2) {
        return LibDia.getOracleContract(chainId);
    }

    function getPriceNoOlderThanAndUpdatedAfter(IntOrAString key, Float minimumUpdatedAt, Float staleAfter)
        external
        view
        returns (Float price, Float updatedAt)
    {
        return LibDia.getPriceNoOlderThanAndUpdatedAfter(key, minimumUpdatedAt, staleAfter);
    }
}
