// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {IHookable} from "./IHookable.sol";

interface IHookManager is IHookable {
    function installHook(bytes calldata hookAndData, uint8 capabilityFlags) external;
}
