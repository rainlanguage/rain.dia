// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Script} from "forge-std-1.16.1/src/Script.sol";
import {DiaWords} from "../src/concrete/DiaWords.sol";
import {LibFs} from "rain-sol-codegen-0.1.0/src/lib/LibFs.sol";
import {LibCodeGen} from "rain-sol-codegen-0.1.0/src/lib/LibCodeGen.sol";
import {LibGenParseMeta} from "rain-interpreter-interface-0.1.0/src/lib/codegen/LibGenParseMeta.sol";
import {LibDiaSubParser} from "../src/lib/parse/LibDiaSubParser.sol";
import {PARSE_META_BUILD_DEPTH} from "../src/abstract/DiaSubParser.sol";

contract Build is Script {
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

        string memory path = LibFs.pathForContract(name);
        vm.writeFile(
            path, vm.replace(vm.readFile(path), string.concat("./script/Build", "Pointers.sol"), "./script/Build.sol")
        );
    }

    function run() external {
        buildDiaWordsPointers();
    }
}
