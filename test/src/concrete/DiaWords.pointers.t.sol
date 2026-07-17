// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {DiaWords} from "../../../src/concrete/DiaWords.sol";
import {OPCODE_DIA_PRICE, OPCODE_FUNCTION_POINTERS_LENGTH} from "../../../src/abstract/DiaExtern.sol";
import {SUB_PARSER_WORD_DIA_PRICE, SUB_PARSER_WORD_PARSERS_LENGTH} from "../../../src/lib/parse/LibDiaSubParser.sol";
import {
    OPCODE_FUNCTION_POINTERS,
    INTEGRITY_FUNCTION_POINTERS,
    OPERAND_HANDLER_FUNCTION_POINTERS,
    SUB_PARSER_WORD_PARSERS
} from "../../../src/generated/DiaWords.pointers.sol";
import {OperandV2} from "rain-interpreter-interface-0.1.0/src/interface/IInterpreterV4.sol";
import {
    IInterpreterExternV4,
    ExternDispatchV2,
    EncodedExternDispatchV2
} from "rain-interpreter-interface-0.1.0/src/interface/IInterpreterExternV4.sol";
import {LibExtern} from "rainlang-0.1.2/src/lib/extern/LibExtern.sol";

contract DiaWordsPointersTest is Test {
    function testBuildOpcodeFunctionPointersMatchesCommittedPointers() external {
        DiaWords diaWords = new DiaWords();

        assertEq(diaWords.buildOpcodeFunctionPointers(), OPCODE_FUNCTION_POINTERS);
    }

    function testBuildIntegrityFunctionPointersMatchesCommittedPointers() external {
        DiaWords diaWords = new DiaWords();

        assertEq(diaWords.buildIntegrityFunctionPointers(), INTEGRITY_FUNCTION_POINTERS);
    }

    function testBuildOperandHandlerFunctionPointersMatchesCommittedPointers() external {
        DiaWords diaWords = new DiaWords();

        assertEq(diaWords.buildOperandHandlerFunctionPointers(), OPERAND_HANDLER_FUNCTION_POINTERS);
    }

    function testBuildSubParserWordParsersMatchesCommittedPointers() external {
        DiaWords diaWords = new DiaWords();

        assertEq(diaWords.buildSubParserWordParsers(), SUB_PARSER_WORD_PARSERS);
    }

    function testBuildLiteralParserFunctionPointersIsEmpty() external {
        DiaWords diaWords = new DiaWords();

        assertEq(diaWords.buildLiteralParserFunctionPointers(), hex"");
    }

    function testOpcodeAndSubParserTablesShareLengthAndIndexConvention() external pure {
        assertEq(OPCODE_FUNCTION_POINTERS_LENGTH, SUB_PARSER_WORD_PARSERS_LENGTH);
        assertEq(OPCODE_DIA_PRICE, SUB_PARSER_WORD_DIA_PRICE);
        assertEq(OPCODE_FUNCTION_POINTERS.length, OPCODE_FUNCTION_POINTERS_LENGTH * 2);
        assertEq(INTEGRITY_FUNCTION_POINTERS.length, OPCODE_FUNCTION_POINTERS_LENGTH * 2);
        assertEq(OPERAND_HANDLER_FUNCTION_POINTERS.length, SUB_PARSER_WORD_PARSERS_LENGTH * 2);
        assertEq(SUB_PARSER_WORD_PARSERS.length, SUB_PARSER_WORD_PARSERS_LENGTH * 2);
    }

    function testDiaPriceSubParserEncodesDiaPriceOpcodeAndZeroOperand() external {
        DiaWords diaWords = new DiaWords();
        bytes memory word = bytes("dia-price");

        (bool success,, bytes32[] memory constants) =
            diaWords.subParseWord2(bytes.concat(bytes2(0), bytes1(0), bytes2(uint16(word.length)), word, bytes32(0)));
        assertTrue(success);
        assertEq(constants.length, 1);

        (IInterpreterExternV4 decodedExtern, ExternDispatchV2 dispatch) =
            LibExtern.decodeExternCall(EncodedExternDispatchV2.wrap(constants[0]));
        assertEq(address(decodedExtern), address(diaWords));

        (uint256 opcode, OperandV2 operand) = LibExtern.decodeExternDispatch(dispatch);
        assertEq(opcode, OPCODE_DIA_PRICE);
        assertEq(OperandV2.unwrap(operand), bytes32(0));
    }
}
