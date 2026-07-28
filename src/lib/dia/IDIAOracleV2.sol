// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title IDIAOracleV2
/// @notice Minimal interface for the DIA oracle V2 contract.
/// https://github.com/diadata-org/diadata
interface IDIAOracleV2 {
    /// @notice Returns the latest value and update timestamp for a DIA feed.
    /// @param key The DIA feed key, such as "AMZN".
    /// @return value The latest feed value with the feed's configured decimals.
    /// @return timestamp The unix timestamp when the value was last updated.
    function getValue(string memory key) external view returns (uint128 value, uint128 timestamp);
}
