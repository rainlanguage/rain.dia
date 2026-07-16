// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {DiaWords} from "src/concrete/DiaWords.sol";
import {OPCODE_DIA_PRICE, OPCODE_FUNCTION_POINTERS_LENGTH} from "src/abstract/DiaExtern.sol";
import {SUB_PARSER_WORD_DIA_PRICE, SUB_PARSER_WORD_PARSERS_LENGTH} from "src/lib/parse/LibDiaSubParser.sol";
import {
    OPCODE_FUNCTION_POINTERS,
    INTEGRITY_FUNCTION_POINTERS,
    OPERAND_HANDLER_FUNCTION_POINTERS,
    SUB_PARSER_WORD_PARSERS
} from "src/generated/DiaWords.pointers.sol";

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
}
