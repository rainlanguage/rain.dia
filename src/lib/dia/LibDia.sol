// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {IDIAOracleV2} from "./IDIAOracleV2.sol";
import {LibDecimalFloat, Float} from "rain.math.float/lib/LibDecimalFloat.sol";
import {IntOrAString, LibIntOrAString} from "rain.intorastring/lib/LibIntOrAString.sol";

error UnsupportedChainId();
error StaleDiaPrice(uint128 timestamp, uint256 staleAfter);

/// @title LibDia
/// @notice Core library for interacting with DIA oracle V2 on-chain.
/// DIA keys are simple strings like "BTC/USD", "ETH/USD", etc.
/// The string is passed through directly from the Rain expression.
/// DIA prices have 8 decimals.
library LibDia {
    using LibIntOrAString for IntOrAString;

    uint256 constant CHAIN_ID_BASE = 8453;

    /// @dev DIA oracle V2 contract on Base.
    /// https://docs.diadata.org/products/token-price-feeds/access-the-oracle
    IDIAOracleV2 constant ORACLE_BASE = IDIAOracleV2(0xB8BF9ba432282F25F56e143641145349ab7c5Bf6);

    /// @dev DIA prices have 8 decimal places.
    int256 constant DIA_DECIMALS = -8;

    function getOracleContract(uint256 chainId) internal pure returns (IDIAOracleV2) {
        if (chainId == CHAIN_ID_BASE) {
            return ORACLE_BASE;
        } else {
            revert UnsupportedChainId();
        }
    }

    /// @notice Fetches a price from the DIA oracle and reverts if the price is
    /// stale. The key is passed through as a string directly from the Rain
    /// expression, e.g. "BTC/USD".
    /// @param feedKey The IntOrAString key for the DIA feed, e.g. "BTC/USD".
    /// @param staleAfter The maximum age of the price in seconds as a Float.
    /// @return price The price as a Float with 8 decimal places.
    /// @return updatedAt The timestamp of the price update as a Float (seconds).
    function getPriceNoOlderThan(IntOrAString feedKey, Float staleAfter)
        internal
        view
        returns (Float price, Float updatedAt)
    {
        uint256 staleAfterUint = LibDecimalFloat.toFixedDecimalLossless(staleAfter, 0);
        string memory key = LibIntOrAString.toString(feedKey);
        IDIAOracleV2 oracle = getOracleContract(block.chainid);

        (uint128 rawPrice, uint128 rawTimestamp) = oracle.getValue(key);

        if (block.timestamp - rawTimestamp > staleAfterUint) {
            revert StaleDiaPrice(rawTimestamp, staleAfterUint);
        }

        price = LibDecimalFloat.packLossless(int256(uint256(rawPrice)), DIA_DECIMALS);
        updatedAt = LibDecimalFloat.packLossless(int256(uint256(rawTimestamp)), 0);
    }
}
