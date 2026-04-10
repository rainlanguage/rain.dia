// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

string constant FORK_RPC_URL_BASE = "https://base.gateway.tenderly.co";

/// @dev A recent Base block. DIA demo oracle has BTC/USD data with timestamp
/// 1744172776 (April 9, 2025). Tests use vm.warp to set block.timestamp
/// close to the DIA update time so staleness checks pass.
uint256 constant FORK_BLOCK_BASE = 44515230;

/// @dev The timestamp of the DIA BTC/USD update at the demo oracle.
/// Tests warp to this + a small offset so staleness checks pass.
uint256 constant DIA_BTC_USD_TIMESTAMP = 1744172776;
