// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Deploy} from "../../script/Deploy.sol";

contract UnexpectedAddressDeploy is Deploy {
    function deployDiaWords() internal pure override returns (address) {
        return address(1);
    }
}
