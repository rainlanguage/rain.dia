// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {UnsupportedChainId} from "../../../../src/lib/dia/LibDia.sol";
import {LibDiaGetOracleContractExternalWrapper} from "./LibDiaGetOracleContractExternalWrapper.sol";

contract LibDiaGetOracleContractTest is Test {
    function testGetOracleContractUnsupported() external {
        LibDiaGetOracleContractExternalWrapper wrapper = new LibDiaGetOracleContractExternalWrapper();
        vm.expectRevert(UnsupportedChainId.selector);
        wrapper.getOracleContract(1);
    }
}
