// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {LibRainDeploy} from "rain-deploy-0.1.18/src/lib/LibRainDeploy.sol";

/// @title LibDiaWordsDeploy
/// @notice Deterministic DiaWords deployment record for Zoltu CREATE2 deploys.
library LibDiaWordsDeploy {
    /// @dev Zoltu-derived deployment address for the current DiaWords creation code.
    address constant DIA_WORDS_DEPLOYED_ADDRESS = 0xA067FD0Cc69429C7650589d45Ce5A9970Ff48E9e;

    /// @dev Runtime codehash for `DIA_WORDS_DEPLOYED_ADDRESS`.
    bytes32 constant DIA_WORDS_DEPLOYED_CODEHASH = 0xc83e75e1406e8460fc80d2d6f35f64329dfa608d1a471f9c2a3a446d8461c8d8;

    /// @notice Predicts the Zoltu CREATE2 address for the given creation code.
    function zoltuAddress(bytes memory initCode) internal pure returns (address predicted) {
        bytes32 initCodeHash = keccak256(initCode);
        bytes32 digest =
            keccak256(abi.encodePacked(bytes1(0xff), LibRainDeploy.ZOLTU_FACTORY, bytes32(0), initCodeHash));
        predicted = address(uint160(uint256(digest)));
    }
}
