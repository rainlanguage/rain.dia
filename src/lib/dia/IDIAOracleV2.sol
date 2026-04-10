// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title IDIAOracleV2
/// @notice Minimal interface for the DIA oracle V2 contract.
/// https://github.com/diadata-org/diadata
interface IDIAOracleV2 {
    function getValue(string memory key) external view returns (uint128, uint128);
}
