// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IExtendable} from "./IExtendable.sol";

interface IExtensionManager is IExtendable {
    function installExtension(bytes calldata extensionAndData) external;
}
