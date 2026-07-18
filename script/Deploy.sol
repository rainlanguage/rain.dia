// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Script} from "forge-std-1.16.1/src/Script.sol";
import {DiaWords} from "../src/concrete/DiaWords.sol";
import {IMetaBoardV1_2} from "rain-metadata-0.1.0/src/interface/unstable/IMetaBoardV1_2.sol";
import {LibDescribedByMeta} from "rain-metadata-0.1.0/src/lib/LibDescribedByMeta.sol";
import {LibRainDeploy} from "rain-deploy-0.1.2/src/lib/LibRainDeploy.sol";
import {LibDiaWordsDeploy} from "../src/lib/deploy/LibDiaWordsDeploy.sol";

/// @dev Deterministic MetaBoard address deployed via Zoltu factory.
/// https://github.com/rainlanguage/rain.metadata
address constant METABOARD_ADDRESS = 0xfb8437AeFBB8031064E274527C5fc08e30Ac6928;

contract Deploy is Script {
    function deployDiaWords() internal virtual returns (address deployed) {
        if (LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_ADDRESS.code.length == 0) {
            return LibRainDeploy.deployZoltu(type(DiaWords).creationCode);
        }
        return LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_ADDRESS;
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");
        bytes memory subParserDescribedByMeta = vm.readFileBinary("meta/DiaWords.rain.meta");
        IMetaBoardV1_2 metaboard = IMetaBoardV1_2(METABOARD_ADDRESS);

        vm.startBroadcast(deployerPrivateKey);

        address deployed = deployDiaWords();
        if (deployed != LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_ADDRESS) {
            revert LibRainDeploy.UnexpectedDeployedAddress(LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_ADDRESS, deployed);
        }
        if (deployed.codehash != LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_CODEHASH) {
            revert LibRainDeploy.UnexpectedDeployedCodeHash(
                LibDiaWordsDeploy.DIA_WORDS_DEPLOYED_CODEHASH, deployed.codehash
            );
        }

        DiaWords subParser = DiaWords(deployed);
        LibDescribedByMeta.emitForDescribedAddress(metaboard, subParser, subParserDescribedByMeta);

        vm.stopBroadcast();
    }
}
