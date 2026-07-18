// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {OpTest} from "rainlang-0.1.2/test/abstract/OpTest.sol";
import {DiaWords} from "../../../src/concrete/DiaWords.sol";
import {LibDia} from "../../../src/lib/dia/LibDia.sol";
import {FORK_BLOCK_BASE, forkRpcUrlBase} from "../../lib/LibFork.sol";
import {StackItem} from "rain-interpreter-interface-0.1.0/src/interface/IInterpreterV4.sol";
import {Float, LibDecimalFloat} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {Strings} from "@openzeppelin-contracts-5.6.1/utils/Strings.sol";
import {LibInterpreterDeploy} from "rainlang-0.1.2/src/lib/deploy/LibInterpreterDeploy.sol";

/// @notice Full parse→eval integration for `dia-price`. The parser encodes the
/// `"AMZN"` string literal as a V3 IntOrAString
/// (`LibIntOrAString.fromStringV3`) and `LibDia.intOrAStringToString` decodes
/// the same layout. Hardcoded fork outputs ensure parser or consumer drift
/// cannot be hidden by deriving expectations through the same decode path.
contract DiaWordsDiaPriceIntegrationTest is OpTest {
    using Strings for address;

    /// Select the Base fork, then (re)etch the rainlang interpreter contracts
    /// onto the forked state so `OpTest`'s fixed addresses resolve there.
    function setUp() external {
        vm.createSelectFork(forkRpcUrlBase(vm), FORK_BLOCK_BASE);
        vm.chainId(LibDia.CHAIN_ID_BASE);
        LibInterpreterDeploy.etchRainlang(vm);
    }

    /// Parse and eval `dia-price("AMZN" 3600)` against the pinned Base fork.
    /// Expected stack values are pinned directly to the oracle response at
    /// `FORK_BLOCK_BASE`.
    function testDiaWordsDiaPriceParseEvalHappy() external {
        DiaWords diaWords = new DiaWords();

        StackItem[] memory expectedStack = new StackItem[](2);
        // Stack index 0 is the top of the stack: the last output, i.e. the
        // update timestamp.
        expectedStack[0] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(1781520797, 0)));
        expectedStack[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(238650000000000005680, -18)));

        checkHappy(
            bytes(
                string.concat(
                    "using-words-from ", address(diaWords).toHexString(), " price ts: dia-price(\"AMZN\" 3600);"
                )
            ),
            expectedStack,
            "dia-price AMZN parse eval"
        );
    }
}
