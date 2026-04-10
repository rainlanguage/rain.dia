// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {OpTest, StackItem} from "rain.interpreter/../test/abstract/OpTest.sol";
import {DiaWords} from "src/concrete/DiaWords.sol";
import {FORK_RPC_URL_BASE, FORK_BLOCK_BASE, DIA_BTC_USD_TIMESTAMP} from "test/lib/LibFork.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {LibDia} from "src/lib/dia/LibDia.sol";
import {LibDecimalFloat, Float} from "rain.math.float/lib/LibDecimalFloat.sol";
import {LibIntOrAString, IntOrAString} from "rain.intorastring/lib/LibIntOrAString.sol";

contract DiaWordsDiaPriceTest is OpTest {
    using Strings for address;

    function beforeOpTestConstructor() internal override {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
    }

    function testDiaWordsDiaPriceHappy() external {
        vm.chainId(LibDia.CHAIN_ID_BASE);
        vm.warp(DIA_BTC_USD_TIMESTAMP + 60);

        DiaWords diaWords = new DiaWords();

        // Get the actual values from the oracle so we can build
        // the expected stack.
        IntOrAString key = LibIntOrAString.fromString2("BTC/USD");
        Float staleAfter = LibDecimalFloat.packLossless(3600, 0);
        (Float price, Float updatedAt) = LibDia.getPriceNoOlderThan(key, staleAfter);

        StackItem[] memory expectedStack = new StackItem[](2);
        expectedStack[0] = StackItem.wrap(Float.unwrap(updatedAt));
        expectedStack[1] = StackItem.wrap(Float.unwrap(price));

        checkHappy(
            bytes(
                string.concat(
                    "using-words-from ",
                    address(diaWords).toHexString(),
                    "price updated-at: dia-price(\"BTC/USD\" 3600);"
                )
            ),
            expectedStack,
            "dia-price(\"BTC/USD\" 3600)"
        );
    }
}
