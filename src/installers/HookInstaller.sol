// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {AuthorityCapability} from "../capabilities/Authority.sol";
import {HookableCapability} from "../capabilities/Hookable.sol";

abstract contract HookInstaller is AuthorityCapability, HookableCapability {
    /**
     * @dev Install a hook
     * @param hookAndData [0:20]: hook address, [20:]: hook data
     * @param capabilityFlags Capability flags for the hook
     */
    function installHook(bytes calldata hookAndData, uint8 capabilityFlags) external {
        canManagePlugins();
        _installHook(address(bytes20(hookAndData[:20])), hookAndData[20:], capabilityFlags);
    }
}
