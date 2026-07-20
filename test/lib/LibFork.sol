// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {Vm} from "forge-std-1.16.1/src/Vm.sol";

error MissingBaseRpcUrl();

string constant DEFAULT_BASE_RPC_URL = "https://mainnet.base.org";

/// @dev A recent Base block. DIA oracle has AMZN data with timestamp
/// 1781520797. The fork block timestamp is close enough to that update for
/// staleness checks without vm.warp.
uint256 constant FORK_BLOCK_BASE = 47365950;

/// @notice Resolves an optional configured Base RPC URL for local or CI use.
function resolveForkRpcUrl(bool hasUrl, string memory configuredUrl, bool isCi) pure returns (string memory url) {
    if (hasUrl && bytes(configuredUrl).length != 0) {
        return configuredUrl;
    }
    if (isCi) {
        revert MissingBaseRpcUrl();
    }
    return DEFAULT_BASE_RPC_URL;
}

/// @notice Returns the Base RPC URL for fork tests.
/// @dev Requires `BASE_RPC_URL` in CI; defaults to public Base mainnet locally.
function forkRpcUrlBase(Vm vm) view returns (string memory url) {
    bool hasUrl = vm.envExists("BASE_RPC_URL");
    string memory configuredUrl = hasUrl ? vm.envString("BASE_RPC_URL") : "";
    bool isCi = vm.envExists("CI") || vm.envExists("GITHUB_ACTIONS");
    return resolveForkRpcUrl(hasUrl, configuredUrl, isCi);
}
