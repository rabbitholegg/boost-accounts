// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

abstract contract HookableCapability {
    /**
     * @dev checks whether a address is a valid hook
     * note: If you need to extend the interface, override this function
     * @param hookAddress hook address
     */
    function _isSupportsHookInterface(address hookAddress) internal view virtual returns (bool);

    /**
     * @dev checks whether a address is a installed hook
     */
    function _isInstalledHook(address hook) internal view virtual returns (bool);

    /**
     * @dev Install a hook
     * @param hookAddress The address of the hook
     * @param initData The init data of the hook
     * @param capabilityFlags Capability flags for the hook
     */
    function _installHook(address hookAddress, bytes memory initData, uint8 capabilityFlags) internal virtual;

    /**
     * @dev Uninstall a hook
     *      1. revert if the hook is not installed
     *      2. call hook.teardown() with 1M gas, emit HOOK_UNINSTALL_WITHERROR if the call failed
     * @param hookAddress The address of the hook
     */
    function _uninstallHook(address hookAddress) internal virtual;
}
