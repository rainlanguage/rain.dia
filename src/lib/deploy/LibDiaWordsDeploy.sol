// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {LibRainDeploy} from "rain-deploy-0.1.2/src/lib/LibRainDeploy.sol";

/// @title LibDiaWordsDeploy
/// @notice Deterministic DiaWords deployment record for Zoltu CREATE2 deploys.
library LibDiaWordsDeploy {
    /// @dev Zoltu-derived deployment address for the current DiaWords creation code.
    address constant DIA_WORDS_DEPLOYED_ADDRESS = 0x64288bBA6FC86506f0aF001545eBCF23544B8389;

    /// @dev Runtime codehash for `DIA_WORDS_DEPLOYED_ADDRESS`.
    bytes32 constant DIA_WORDS_DEPLOYED_CODEHASH = 0xf0b030be8140c85d41825a53dfc0c27ba42cf4959e34b8322963d191fb36b493;

    /// @notice Predicts the Zoltu CREATE2 address for the given creation code.
    function zoltuAddress(bytes memory initCode) internal pure returns (address predicted) {
        bytes32 initCodeHash = keccak256(initCode);
        bytes32 digest =
            keccak256(abi.encodePacked(bytes1(0xff), LibRainDeploy.ZOLTU_FACTORY, bytes32(0), initCodeHash));
        predicted = address(uint160(uint256(digest)));
    }
}
