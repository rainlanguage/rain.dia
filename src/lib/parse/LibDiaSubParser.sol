// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {AuthoringMetaV2} from "rain-interpreter-interface-0.1.0/src/interface/deprecated/v1/IParserV1.sol";

uint256 constant SUB_PARSER_WORD_DIA_PRICE = 0;
uint256 constant SUB_PARSER_WORD_DIA_PRICE_AFTER = 1;

uint256 constant SUB_PARSER_WORD_PARSERS_LENGTH = 2;

library LibDiaSubParser {
    function authoringMetaV2() internal pure returns (bytes memory) {
        AuthoringMetaV2[] memory meta = new AuthoringMetaV2[](SUB_PARSER_WORD_PARSERS_LENGTH);

        meta[SUB_PARSER_WORD_DIA_PRICE] = AuthoringMetaV2(
            "dia-price",
            "Returns the current price of the given asset according to DIA. Accepts 2 inputs, the price key as a string (e.g. \"BTC/USD\") and the timeout in seconds. The price has 8 decimal places. The timeout will be used to determine if the price is stale and revert if it is. Returns 2 outputs: the price and the timestamp of the last update."
        );
        meta[SUB_PARSER_WORD_DIA_PRICE_AFTER] = AuthoringMetaV2(
            "dia-price-after",
            "Returns the current price of the given asset according to DIA. Accepts 3 inputs: the price key as a string (e.g. \"BTC/USD\"), the minimum acceptable update timestamp in unix seconds, and the timeout in seconds. Reverts if the price is older than the minimum update timestamp, stale by the timeout, or zero. Returns 2 outputs: the price and the timestamp of the last update."
        );
        return abi.encode(meta);
    }
}
