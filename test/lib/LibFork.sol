// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

string constant FORK_RPC_URL_BASE = "https://base.gateway.tenderly.co";

/// @dev A recent Base block. DIA oracle has AMZN data with timestamp
/// 1778908932. The fork block timestamp is close enough to that update for
/// staleness checks without vm.warp.
uint256 constant FORK_BLOCK_BASE = 46061133;
