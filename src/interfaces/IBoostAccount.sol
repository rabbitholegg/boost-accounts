// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {IHookManager} from "./IHookManager.sol";
import {IExtensionManager} from "./IExtensionManager.sol";
import {IMultiOwnerManager} from "./IMultiOwnerManager.sol";
import {IManageable} from "./IManageable.sol";
import {IUpgradeable} from "./IUpgradeable.sol";
import {IStandardExecutor} from "./IStandardExecutor.sol";

interface IBoostAccount is IHookManager, IExtensionManager, IMultiOwnerManager, IStandardExecutor, IUpgradeable {
    function initialize(
        bytes32[] calldata owners,
        address defalutCallbackHandler,
        bytes[] calldata extensions,
        bytes[] calldata hooks
    ) external;
}
