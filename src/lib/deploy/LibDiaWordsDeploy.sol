// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {DiaWords} from "../../concrete/DiaWords.sol";
import {LibRainDeploy} from "rain-deploy-0.1.2/src/lib/LibRainDeploy.sol";

/// @title LibDiaWordsDeploy
/// @notice Deterministic DiaWords deployment record for Zoltu CREATE2 deploys.
library LibDiaWordsDeploy {
    /// @dev Zoltu-derived deployment address for the current DiaWords creation code.
    address constant DIA_WORDS_DEPLOYED_ADDRESS = 0xE30408dE1D707C003f282A774ed6aC77F096Ea29;

    /// @dev Runtime codehash for `DIA_WORDS_DEPLOYED_ADDRESS`.
    bytes32 constant DIA_WORDS_DEPLOYED_CODEHASH = 0xea126daaa957cc166271a64204d95b94c50e72244a564f7317358ae71c0450e0;

    /// @notice Returns the canonical DiaWords creation code for Zoltu deployment.
    function creationCode() internal pure returns (bytes memory code) {
        return type(DiaWords).creationCode;
    }

    /// @notice Predicts the Zoltu CREATE2 address for the given creation code.
    function zoltuAddress(bytes memory initCode) internal pure returns (address predicted) {
        bytes32 initCodeHash = keccak256(initCode);
        bytes32 digest = keccak256(abi.encodePacked(bytes1(0xff), LibRainDeploy.ZOLTU_FACTORY, bytes32(0), initCodeHash));
        predicted = address(uint160(uint256(digest)));
    }
}
