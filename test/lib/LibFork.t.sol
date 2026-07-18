// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {MissingBaseRpcUrl, forkRpcUrlBase, resolveForkRpcUrl} from "./LibFork.sol";

contract LibForkTest is Test {
    function forkRpcUrlBaseExternal() external view returns (string memory) {
        return forkRpcUrlBase(vm);
    }

    function resolveForkRpcUrlExternal(bool hasUrl, string memory configuredUrl, bool isCi)
        external
        pure
        returns (string memory)
    {
        return resolveForkRpcUrl(hasUrl, configuredUrl, isCi);
    }

    function testConfiguredBaseRpcUrlWinsInCi() external pure {
        assertEq(resolveForkRpcUrl(true, "https://configured.example", true), "https://configured.example");
    }

    function testMissingBaseRpcUrlRevertsInCi() external {
        vm.expectRevert(MissingBaseRpcUrl.selector);
        this.resolveForkRpcUrlExternal(false, "", true);
    }

    function testMissingBaseRpcUrlUsesDefaultLocally() external pure {
        assertEq(resolveForkRpcUrl(false, "", false), "https://mainnet.base.org");
    }

    function testEmptyBaseRpcUrlUsesDefaultLocally() external pure {
        assertEq(resolveForkRpcUrl(true, "", false), "https://mainnet.base.org");
    }

    function testEmptyBaseRpcUrlRevertsInCi() external {
        vm.setEnv("BASE_RPC_URL", "");
        vm.setEnv("CI", "true");

        vm.expectRevert(MissingBaseRpcUrl.selector);
        this.forkRpcUrlBaseExternal();
    }
}
