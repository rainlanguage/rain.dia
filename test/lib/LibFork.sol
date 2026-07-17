// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {Vm} from "forge-std-1.16.1/src/Vm.sol";

error MissingBaseRpcUrl();

/// @dev A recent Base block. DIA oracle has AMZN data with timestamp
/// 1778908932. The fork block timestamp is close enough to that update for
/// staleness checks without vm.warp.
uint256 constant FORK_BLOCK_BASE = 47365950;

/// @notice Returns the Base RPC URL for fork tests.
/// @dev Requires `BASE_RPC_URL` in CI; defaults to public Base mainnet locally.
function forkRpcUrlBase(Vm vm) view returns (string memory url) {
    if (vm.envExists("BASE_RPC_URL")) {
        return vm.envString("BASE_RPC_URL");
    }
    if (vm.envExists("CI") || vm.envExists("GITHUB_ACTIONS")) {
        revert MissingBaseRpcUrl();
    }
    return "https://mainnet.base.org";
}
