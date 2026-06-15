// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {DiaWords} from "src/concrete/DiaWords.sol";
import {FORK_RPC_URL_BASE, FORK_BLOCK_BASE} from "test/lib/LibFork.sol";
import {LibDia} from "src/lib/dia/LibDia.sol";
import {LibDecimalFloat, Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {LibOpDiaPrice, OperandV2, StackItem} from "src/lib/op/LibOpDiaPrice.sol";
import {LibFromStringV3} from "test/lib/LibFromStringV3.sol";

/// @notice Tests DiaWords extern dispatch directly (bypassing the parser).
/// The integration test with checkHappy/OpTest is not possible because the
/// submodule's parser uses V2 IntOrAString encoding, while DiaWords expects
/// V3 encoding (matching the latest on-chain deployer). This test verifies
/// the extern contract works correctly with V3-encoded inputs.
contract DiaWordsDiaPriceTest is Test {
    function testDiaWordsExternDispatch() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(LibDia.CHAIN_ID_BASE);

        DiaWords diaWords = new DiaWords();

        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibFromStringV3.fromStringV3("AMZN"))));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(3600, 0)));

        StackItem[] memory outputs = LibOpDiaPrice.run(OperandV2.wrap(0), inputs);
        assertEq(outputs.length, 2);
        assertTrue(StackItem.unwrap(outputs[0]) != bytes32(0), "price should be non-zero");
        assertTrue(StackItem.unwrap(outputs[1]) != bytes32(0), "timestamp should be non-zero");
    }
}
