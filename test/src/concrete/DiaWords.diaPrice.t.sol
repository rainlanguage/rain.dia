// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {DiaWords} from "../../../src/concrete/DiaWords.sol";
import {FORK_BLOCK_BASE, forkRpcUrlBase} from "../../lib/LibFork.sol";
import {LibDia} from "../../../src/lib/dia/LibDia.sol";
import {LibDecimalFloat, Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {OPCODE_DIA_PRICE} from "../../../src/abstract/DiaExtern.sol";
import {LibFromStringV3} from "../../lib/LibFromStringV3.sol";
import {OperandV2, StackItem} from "rain-interpreter-interface-0.1.0/src/interface/IInterpreterV4.sol";
import {LibExtern, ExternDispatchV2} from "rainlang-0.1.2/src/lib/extern/LibExtern.sol";

/// @notice Tests DiaWords extern dispatch directly (bypassing the parser).
/// The integration test with checkHappy/OpTest is not possible because the
/// submodule's parser uses V2 IntOrAString encoding, while DiaWords expects
/// V3 encoding (matching the latest on-chain deployer). This test verifies
/// the extern contract works correctly with V3-encoded inputs.
contract DiaWordsDiaPriceTest is Test {
    function testDiaWordsExternDispatch() external {
        vm.createSelectFork(forkRpcUrlBase(vm), FORK_BLOCK_BASE);
        vm.chainId(LibDia.CHAIN_ID_BASE);

        DiaWords diaWords = new DiaWords();

        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibFromStringV3.fromStringV3("AMZN"))));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(3600, 0)));

        ExternDispatchV2 dispatch = LibExtern.encodeExternDispatch(OPCODE_DIA_PRICE, OperandV2.wrap(bytes32(0)));
        (uint256 actualInputs, uint256 actualOutputs) = diaWords.externIntegrity(dispatch, 0, 0);
        assertEq(actualInputs, 2);
        assertEq(actualOutputs, 2);

        StackItem[] memory outputs = diaWords.extern(dispatch, inputs);
        assertEq(outputs.length, 2);
        assertTrue(StackItem.unwrap(outputs[0]) != bytes32(0), "price should be non-zero");
        assertTrue(StackItem.unwrap(outputs[1]) != bytes32(0), "timestamp should be non-zero");
    }
}
