// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {AuthorityCapability} from "../capabilities/Authority.sol";
import {ExtendableCapability} from "../capabilities/Extendable.sol";

abstract contract ExtensionInstaller is AuthorityCapability, ExtendableCapability {
    /**
     * @dev install a extension
     * @param extensionAndData [0:20]: extension address, [20:]: extension init data
     * @param selectors function selectors that the extension is allowed to call
     */
    function installExtension(bytes calldata extensionAndData, bytes4[] calldata selectors) external {
        canManagePlugins();
        _installExtension(address(bytes20(extensionAndData[:20])), extensionAndData[20:], selectors);
    }
}
