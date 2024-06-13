// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

/// @title AuthorityCapability
/// @notice Adds the ability to restrict access to certain functions based on the call context.
abstract contract AuthorityCapability {
    /**
     * @dev checks whether the caller is a authorized extension
     *  caller: msg.sender
     *  method: msg.sig
     * @return bool
     */
    function _isAuthorizedExtension() internal view virtual returns (bool);

    /**
     * @notice Ensures the calling contract is the entrypoint
     */
    function _onlyEntryPoint() internal view virtual;

    /**
     * @notice Ensures the calling contract is an authorized extension
     */
    function _onlyExtension() internal view virtual;

    /**
     * @notice Ensures the calling contract is either the Authority contract itself or an authorized extension
     * @dev Uses the inherited `_isAuthorizedExtension()` from ExtensionAuth for extension-based authentication
     */
    function _onlySelfOrExtension() internal view virtual;

    /**
     * @dev Check if access to the following functions:
     *      1. setFallbackHandler
     */
    function canManageFallbacks() internal view virtual;

    /**
     * @dev Check if access to the following functions:
     *      1. installHook
     *      2. uninstallHook
     *      3. installExtension
     *      4. uninstallExtension
     */
    function canManagePlugins() internal view virtual;

    /**
     * @dev Check if access to the following functions:
     *      1. addOwner
     *      2. removeOwner
     *      3. resetOwner
     */
    function canManageOwnership() internal view virtual;

    /**
     * @dev Check if access to the following functions:
     *      1. execute
     *      2. executeBatch
     */
    function canExecute() internal view virtual;

    /**
     * @dev Check if access to the following functions:
     *      1. installValidator
     *      2. uninstallValidator
     */
    function canManageValidators() internal view virtual;
}
