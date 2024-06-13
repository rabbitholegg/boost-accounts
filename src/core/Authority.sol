// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {AuthorityCapability} from "../capabilities/Authority.sol";

abstract contract Authority is AuthorityCapability {
    /**
     * a custom error for caller must be self or extension
     */
    error RestrictedContextOnlySelfOrExtension();

    /**
     * a custom error for caller must be extension
     */
    error RestrictedContextOnlyExtension();

    /**
     * @notice Ensures the calling contract is an authorized extension
     */
    function _onlyExtension() internal view override {
        if (!_isAuthorizedExtension()) {
            revert RestrictedContextOnlyExtension();
        }
    }

    /**
     * @notice Ensures the calling contract is either the Authority contract itself or an authorized extension
     * @dev Uses the inherited `_isAuthorizedExtension()` from ExtensionAuth for extension-based authentication
     */
    function _onlySelfOrExtension() internal view override {
        if (msg.sender != address(this) && !_isAuthorizedExtension()) {
            revert RestrictedContextOnlySelfOrExtension();
        }
    }

    /**
     * @dev Check if access to the following functions:
     *      1. setFallbackHandler
     */
    function canManageFallbacks() internal view virtual override {
        _onlySelfOrExtension();
    }

    /**
     * @dev Check if access to the following functions:
     *      1. installHook
     *      2. uninstallHook
     *      3. installExtension
     *      4. uninstallExtension
     */
    function canManagePlugins() internal view virtual override {
        _onlySelfOrExtension();
    }

    /**
     * @dev Check if access to the following functions:
     *      1. addOwner
     *      2. removeOwner
     *      3. resetOwner
     */
    function canManageOwnership() internal view virtual override {
        _onlySelfOrExtension();
    }

    /**
     * @dev Check if access to the following functions:
     *      1. execute
     *      2. executeBatch
     *      3. executeUserOp
     */
    function canExecute() internal view virtual override {
        _onlyEntryPoint();
    }

    /**
     * @dev Check if access to the following functions:
     *      1. installValidator
     *      2. uninstallValidator
     */
    function canManageValidators() internal view virtual override {
        _onlySelfOrExtension();
    }
}
