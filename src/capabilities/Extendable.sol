// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/// @title Extendable Capability
/// @notice This contract provides the ability to install and uninstall extensions
abstract contract ExtendableCapability {
    /**
     * @dev checks whether a address is a authorized extension
     */
    function _isInstalledExtension(address extension) internal view virtual returns (bool);

    /**
     * @dev checks whether a address is a extension
     * note: If you need to extend the interface, override this function
     * @param extensionAddress extension address
     */
    function _isSupportsExtensionInterface(address extensionAddress) internal view virtual returns (bool);

    /**
     * @dev install a extension
     * @param extensionAddress extension address
     * @param initData extension init data
     * @param selectors function selectors that the extension is allowed to call
     */
    function _installExtension(address extensionAddress, bytes memory initData, bytes4[] memory selectors)
        internal
        virtual;

    /**
     * @dev uninstall a extension
     * @param extensionAddress extension address
     */
    function _uninstallExtension(address extensionAddress) internal virtual;
}
