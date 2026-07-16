// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {DiaWords} from "src/concrete/DiaWords.sol";
import {LibRainDeploy} from "rain-deploy-0.1.2/src/lib/LibRainDeploy.sol";
import {LibDiaWordsDeploy} from "src/lib/deploy/LibDiaWordsDeploy.sol";

contract LibDiaWordsDeployTest is Test {
    function setUp() external {
        LibRainDeploy.etchZoltuFactory(vm);
    }

    function testPinnedAddressMatchesZoltuDerivation() external pure {
        assertEq(
            LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_ADDRESS,
            LibDiaWordsDeploy.zoltuAddress(LibDiaWordsDeploy.creationCode())
        );
    }

    function testPinnedCodehashMatchesRuntimeBytecode() external {
        LibRainDeploy.deployZoltu(LibDiaWordsDeploy.creationCode());
        assertEq(
            LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_ADDRESS.codehash,
            LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_CODEHASH
        );
    }

    function testZoltuDeployMatchesPinnedRecord() external {
        address deployed = LibRainDeploy.deployZoltu(LibDiaWordsDeploy.creationCode());
        assertEq(deployed, LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_ADDRESS);
        assertEq(deployed.codehash, LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_CODEHASH);
    }

    function testCreationCodeMatchesCompiledContract() external pure {
        assertEq(type(DiaWords).creationCode, LibDiaWordsDeploy.creationCode());
    }
}
