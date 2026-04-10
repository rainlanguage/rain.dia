// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Script} from "forge-std/Script.sol";
import {DiaWords} from "src/concrete/DiaWords.sol";
import {LibFs} from "rain.sol.codegen/lib/LibFs.sol";
import {LibCodeGen} from "rain.sol.codegen/lib/LibCodeGen.sol";
import {LibGenParseMeta} from "rain.interpreter.interface/lib/codegen/LibGenParseMeta.sol";
import {LibDiaSubParser} from "src/lib/parse/LibDiaSubParser.sol";
import {PARSE_META_BUILD_DEPTH} from "src/abstract/DiaSubParser.sol";

contract BuildPointers is Script {
    function buildDiaWordsPointers() internal {
        DiaWords diaWords = new DiaWords();

        string memory name = "DiaWords";

        LibFs.buildFileForContract(
            vm,
            address(diaWords),
            name,
            string.concat(
                LibCodeGen.describedByMetaHashConstantString(vm, name),
                LibGenParseMeta.parseMetaConstantString(vm, LibDiaSubParser.authoringMetaV2(), PARSE_META_BUILD_DEPTH),
                LibCodeGen.subParserWordParsersConstantString(vm, diaWords),
                LibCodeGen.operandHandlerFunctionPointersConstantString(vm, diaWords),
                LibCodeGen.integrityFunctionPointersConstantString(vm, diaWords),
                LibCodeGen.opcodeFunctionPointersConstantString(vm, diaWords)
            )
        );
    }

    function run() external {
        buildDiaWordsPointers();
    }
}
