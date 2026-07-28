// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {DiaWords} from "../../../src/concrete/DiaWords.sol";

contract DiaWordsMetaTest is Test {
    function testDescribedByMetaMatchesCommittedMeta() external {
        DiaWords diaWords = new DiaWords();
        bytes memory committedMeta = vm.readFileBinary("meta/DiaWords.rain.meta");

        assertEq(diaWords.describedByMetaV1(), keccak256(committedMeta));
    }
}
