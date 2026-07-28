// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {IERC165} from "@openzeppelin-contracts-5.6.1/utils/introspection/IERC165.sol";
import {IInterpreterExternV4} from "rain-interpreter-interface-0.1.0/src/interface/IInterpreterExternV4.sol";
import {ISubParserV4} from "rain-interpreter-interface-0.1.0/src/interface/ISubParserV4.sol";
import {IDescribedByMetaV1} from "rain-metadata-0.1.0/src/interface/IDescribedByMetaV1.sol";
import {IIntegrityToolingV1} from "rain-sol-codegen-0.1.0/src/interface/IIntegrityToolingV1.sol";
import {IOpcodeToolingV1} from "rain-sol-codegen-0.1.0/src/interface/IOpcodeToolingV1.sol";
import {IParserToolingV1} from "rain-sol-codegen-0.1.0/src/interface/IParserToolingV1.sol";
import {ISubParserToolingV1} from "rain-sol-codegen-0.1.0/src/interface/ISubParserToolingV1.sol";
import {DiaWords} from "../../../src/concrete/DiaWords.sol";

contract DiaWordsIERC165Test is Test {
    function testSupportsAdvertisedInterfaces() external {
        DiaWords diaWords = new DiaWords();

        assertTrue(diaWords.supportsInterface(type(IERC165).interfaceId));
        assertTrue(diaWords.supportsInterface(type(IInterpreterExternV4).interfaceId));
        assertTrue(diaWords.supportsInterface(type(ISubParserV4).interfaceId));
        assertTrue(diaWords.supportsInterface(type(IDescribedByMetaV1).interfaceId));
        assertTrue(diaWords.supportsInterface(type(IIntegrityToolingV1).interfaceId));
        assertTrue(diaWords.supportsInterface(type(IOpcodeToolingV1).interfaceId));
        assertTrue(diaWords.supportsInterface(type(IParserToolingV1).interfaceId));
        assertTrue(diaWords.supportsInterface(type(ISubParserToolingV1).interfaceId));
    }

    function testDoesNotSupportInvalidInterface() external {
        DiaWords diaWords = new DiaWords();

        assertFalse(diaWords.supportsInterface(0xffffffff));
    }

    function testDoesNotSupportUnadvertisedInterface(bytes4 interfaceId) external {
        vm.assume(interfaceId != type(IERC165).interfaceId);
        vm.assume(interfaceId != type(IInterpreterExternV4).interfaceId);
        vm.assume(interfaceId != type(ISubParserV4).interfaceId);
        vm.assume(interfaceId != type(IDescribedByMetaV1).interfaceId);
        vm.assume(interfaceId != type(IIntegrityToolingV1).interfaceId);
        vm.assume(interfaceId != type(IOpcodeToolingV1).interfaceId);
        vm.assume(interfaceId != type(IParserToolingV1).interfaceId);
        vm.assume(interfaceId != type(ISubParserToolingV1).interfaceId);

        DiaWords diaWords = new DiaWords();
        assertFalse(diaWords.supportsInterface(interfaceId));
    }
}
