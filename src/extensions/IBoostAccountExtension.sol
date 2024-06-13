// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {IPluggable} from "../interfaces/IPluggable.sol";

interface IBoostAccountExtension is IPluggable {
    function requiredFunctions() external pure returns (bytes4[] memory);
}
