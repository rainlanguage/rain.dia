// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {DiaWords} from "src/concrete/DiaWords.sol";
import {OPCODE_DIA_PRICE, OPCODE_DIA_PRICE_AFTER} from "src/abstract/DiaExtern.sol";
import {FORK_RPC_URL_BASE, FORK_BLOCK_BASE, DIA_BTC_USD_TIMESTAMP} from "test/lib/LibFork.sol";
import {LibDia, DiaPriceBefore} from "src/lib/dia/LibDia.sol";
import {LibDecimalFloat, Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {ExternDispatchV2, StackItem} from "rain-interpreter-interface-0.1.0/src/interface/IInterpreterExternV4.sol";

function fromStringV3(string memory s) pure returns (IntOrAString intOrAString) {
    assembly ("memory-safe") {
        let length := and(mload(s), 0x1f)
        mstore(0, or(0xe0, length))
        mcopy(sub(0x20, add(length, 1)), add(s, 0x20), length)
        intOrAString := mload(0)
    }
}

/// @notice Tests DiaWords extern dispatch directly (bypassing the parser).
/// The integration test with checkHappy/OpTest is not possible because the
/// submodule's parser uses V2 IntOrAString encoding, while DiaWords expects
/// V3 encoding (matching the latest on-chain deployer). This test verifies
/// the extern contract works correctly with V3-encoded inputs.
contract DiaWordsDiaPriceTest is Test {
    function testDiaWordsExternDispatch() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(LibDia.CHAIN_ID_BASE);
        vm.warp(DIA_BTC_USD_TIMESTAMP + 60);

        DiaWords diaWords = new DiaWords();
        assertTrue(diaWords.describedByMetaV1() != bytes32(0), "metadata hash should be non-zero");

        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(fromStringV3("BTC/USD"))));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(3600, 0)));

        StackItem[] memory outputs = diaWords.extern(dispatch(OPCODE_DIA_PRICE), inputs);
        assertEq(outputs.length, 2);
        assertTrue(StackItem.unwrap(outputs[0]) != bytes32(0), "price should be non-zero");
        assertTrue(StackItem.unwrap(outputs[1]) != bytes32(0), "timestamp should be non-zero");
    }

    function testDiaWordsExternDispatchAfterAcceptsBoundaryTimestamp() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(LibDia.CHAIN_ID_BASE);
        vm.warp(DIA_BTC_USD_TIMESTAMP + 60);

        DiaWords diaWords = new DiaWords();

        (uint256 calculatedInputs, uint256 calculatedOutputs) =
            diaWords.externIntegrity(dispatch(OPCODE_DIA_PRICE_AFTER), 0, 0);
        assertEq(calculatedInputs, 3);
        assertEq(calculatedOutputs, 2);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(fromStringV3("BTC/USD"))));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(int256(DIA_BTC_USD_TIMESTAMP), 0)));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(3600, 0)));

        StackItem[] memory outputs = diaWords.extern(dispatch(OPCODE_DIA_PRICE_AFTER), inputs);
        assertEq(outputs.length, 2);
        assertTrue(StackItem.unwrap(outputs[0]) != bytes32(0), "price should be non-zero");
        assertEq(
            StackItem.unwrap(outputs[1]),
            Float.unwrap(LibDecimalFloat.packLossless(int256(DIA_BTC_USD_TIMESTAMP), 0)),
            "timestamp should match DIA update"
        );
    }

    function testDiaWordsExternDispatchAfterRejectsEarlierTimestamp() external {
        vm.createSelectFork(FORK_RPC_URL_BASE, FORK_BLOCK_BASE);
        vm.chainId(LibDia.CHAIN_ID_BASE);
        vm.warp(DIA_BTC_USD_TIMESTAMP + 60);

        DiaWords diaWords = new DiaWords();

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(fromStringV3("BTC/USD"))));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(int256(DIA_BTC_USD_TIMESTAMP + 1), 0)));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(3600, 0)));

        vm.expectRevert(
            abi.encodeWithSelector(DiaPriceBefore.selector, uint128(DIA_BTC_USD_TIMESTAMP), DIA_BTC_USD_TIMESTAMP + 1)
        );
        diaWords.extern(dispatch(OPCODE_DIA_PRICE_AFTER), inputs);
    }

    function dispatch(uint256 opcode) internal pure returns (ExternDispatchV2) {
        return ExternDispatchV2.wrap(bytes32(opcode << 0x10));
    }
}
