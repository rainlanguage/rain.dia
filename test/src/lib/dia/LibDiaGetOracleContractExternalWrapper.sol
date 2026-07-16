// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibDia, IDIAOracleV2} from "../../../../src/lib/dia/LibDia.sol";

contract LibDiaGetOracleContractExternalWrapper {
    function getOracleContract(uint256 chainId) external pure returns (IDIAOracleV2) {
        return LibDia.getOracleContract(chainId);
    }
}
