// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {Deploy, METABOARD_ADDRESS} from "../../script/Deploy.sol";
import {LibRainDeploy} from "rain-deploy-0.1.2/src/lib/LibRainDeploy.sol";
import {LibDiaWordsDeploy} from "../../src/lib/deploy/LibDiaWordsDeploy.sol";

contract UnexpectedAddressDeploy is Deploy {
    function deployDiaWords() internal pure override returns (address) {
        return address(1);
    }
}

contract DeployTest is Test {
    function setUp() external {
        LibRainDeploy.etchZoltuFactory(vm);
        vm.setEnv("DEPLOYMENT_KEY", "1");
        vm.etch(METABOARD_ADDRESS, hex"00");
    }

    function testRunReusesExistingDeployment() external {
        Deploy deploy = new Deploy();

        deploy.run();
        deploy.run();

        assertEq(LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_ADDRESS.codehash, LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_CODEHASH);
    }

    function testRunRejectsUnexpectedDeploymentAddress() external {
        UnexpectedAddressDeploy deploy = new UnexpectedAddressDeploy();

        vm.expectRevert(
            abi.encodeWithSelector(
                LibRainDeploy.UnexpectedDeployedAddress.selector,
                LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_ADDRESS,
                address(1)
            )
        );
        deploy.run();
    }

    function testRunRejectsUnexpectedDeploymentCodehash() external {
        vm.etch(LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_ADDRESS, hex"00");
        bytes32 actualCodehash = LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_ADDRESS.codehash;
        Deploy deploy = new Deploy();

        vm.expectRevert(
            abi.encodeWithSelector(
                LibRainDeploy.UnexpectedDeployedCodeHash.selector,
                LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_CODEHASH,
                actualCodehash
            )
        );
        deploy.run();
    }
}
