// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {DiaExtern, BaseRainlangExtern} from "../abstract/DiaExtern.sol";
import {DiaSubParser, BaseRainlangSubParser} from "../abstract/DiaSubParser.sol";
import {IDescribedByMetaV1} from "rain-metadata-0.1.0/src/interface/IDescribedByMetaV1.sol";
import {DESCRIBED_BY_META_HASH} from "../generated/DiaWords.pointers.sol";

contract DiaWords is DiaExtern, DiaSubParser {
    /// @inheritdoc IDescribedByMetaV1
    function describedByMetaV1() external pure returns (bytes32) {
        return DESCRIBED_BY_META_HASH;
    }

    /// This is only needed because the parser and extern base contracts both
    /// implement IERC165, and the compiler needs to be told how to resolve the
    /// ambiguity.
    /// @inheritdoc BaseRainlangSubParser
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BaseRainlangSubParser, BaseRainlangExtern)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
