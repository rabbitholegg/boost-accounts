// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {Extendable} from "../core/Extendable.sol";
import {IExtensionManager} from "../interfaces/IExtensionManager.sol";
import {IBoostAccountExtension} from "../extensions/IBoostAccountExtension.sol";

abstract contract ExtensionManager is IExtensionManager, Extendable {
    error MissingSelectors();

    function installExtension(bytes calldata extensionAndData) external override {
        canManagePlugins();
        _addExtension(extensionAndData);
    }

    function _isSupportsExtensionInterface(address extensionAddress) internal view override returns (bool supported) {
        supported = false;
        bytes memory callData =
            abi.encodeWithSelector(IERC165.supportsInterface.selector, type(IBoostAccountExtension).interfaceId);
        assembly ("memory-safe") {
            let result := staticcall(gas(), extensionAddress, add(callData, 0x20), mload(callData), 0x00, 0x20)
            if gt(result, 0) { supported := mload(0x00) }
        }
    }

    function _addExtension(bytes calldata extensionAndData) internal {
        address extensionAddress = address(bytes20(extensionAndData[:20]));
        IBoostAccountExtension aExtension = IBoostAccountExtension(extensionAddress);
        bytes4[] memory requiredFunctions = aExtension.requiredFunctions();
        if (requiredFunctions.length == 0) revert MissingSelectors();
        _installExtension(address(bytes20(extensionAndData[:20])), extensionAndData[20:], requiredFunctions);
    }
}
