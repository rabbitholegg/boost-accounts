// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {AddressLinkedList} from "../utils/AddressLinkedList.sol";
import {Authority} from "./Authority.sol";
import {ExtendableCapability} from "../capabilities/Extendable.sol";
import {IExtendable} from "../interfaces/IExtendable.sol";
import {IPluggable} from "../interfaces/IPluggable.sol";
import {SelectorLinkedList} from "../utils/SelectorLinkedList.sol";
import {Storage} from "../utils/Storage.sol";

abstract contract Extendable is IExtendable, Authority, ExtendableCapability {
    using AddressLinkedList for mapping(address => address);
    using SelectorLinkedList for mapping(bytes4 => bytes4);

    error UnexpectedRecursiveExecution();
    error InvalidExtension();
    error ExtensionNotInstalled();
    error ExtensionAlreadyInstalled();
    error UnauthorizedCaller();

    bytes4 private constant INTERFACE_ID_EXTENSION = type(IPluggable).interfaceId;

    function _extensionMapping() internal view returns (mapping(address => address) storage extensions) {
        extensions = Storage.context().extensions;
    }

    /**
     * @dev checks whether the caller is a authorized extension
     *  caller: msg.sender
     *  method: msg.sig
     * @return bool
     */
    function _isAuthorizedExtension() internal view override returns (bool) {
        return Storage.context().extensionSelectors[msg.sender].isExist(msg.sig);
    }

    /**
     * @dev checks whether a address is a authorized extension
     */
    function _isInstalledExtension(address extension) internal view virtual override returns (bool) {
        return _extensionMapping().isExist(extension);
    }

    /**
     * @dev checks whether a address is a installed extension
     */
    function isInstalledExtension(address extension) external view override returns (bool) {
        return _isInstalledExtension(extension);
    }

    /**
     * @dev checks whether a address is a extension
     * note: If you need to extend the interface, override this function
     * @param extensionAddress extension address
     */
    function _isSupportsExtensionInterface(address extensionAddress)
        internal
        view
        virtual
        override
        returns (bool supported)
    {
        bytes memory callData = abi.encodeWithSelector(IERC165.supportsInterface.selector, INTERFACE_ID_EXTENSION);
        assembly ("memory-safe") {
            let result := staticcall(gas(), extensionAddress, add(callData, 0x20), mload(callData), 0x00, 0x20)
            if and(result, eq(returndatasize(), 32)) { supported := mload(0x00) }
        }
    }

    /**
     * @dev install a extension
     *
     * During the installation process of a extension (even if the installation ultimately fails),
     * the extension retains all of its permissions. This allows the extension to execute highly
     * customized operations during the installation process, but it also comes with risks.
     * To mitigate these risks, it is recommended that users only install extensions that have
     * been audited and are trusted.
     *
     * @param extensionAddress extension address
     * @param initData extension init data
     * @param selectors function selectors that the extension is allowed to call
     */
    function _installExtension(address extensionAddress, bytes memory initData, bytes4[] memory selectors)
        internal
        virtual
        override
    {
        if (_isInstalledExtension(extensionAddress)) {
            revert ExtensionAlreadyInstalled();
        }

        if (_isSupportsExtensionInterface(extensionAddress) == false) {
            revert InvalidExtension();
        }

        mapping(address => address) storage extensions = _extensionMapping();
        extensions.add(extensionAddress);
        mapping(bytes4 => bytes4) storage extensionSelectors = Storage.context().extensionSelectors[extensionAddress];

        for (uint256 i = 0; i < selectors.length; i++) {
            extensionSelectors.add(selectors[i]);
        }
        bytes memory callData = abi.encodeWithSelector(IPluggable.setup.selector, initData);
        bytes4 invalidExtensionSelector = InvalidExtension.selector;
        assembly ("memory-safe") {
            let result := call(gas(), extensionAddress, 0, add(callData, 0x20), mload(callData), 0x00, 0x00)
            if iszero(result) {
                mstore(0x00, invalidExtensionSelector)
                revert(0x00, 4)
            }
        }

        emit ExtensionInstalled(extensionAddress);
    }

    /**
     * @dev uninstall a extension
     * @param extensionAddress extension address
     */
    function _uninstallExtension(address extensionAddress) internal virtual override {
        mapping(address => address) storage extensions = _extensionMapping();
        if (!extensions.tryRemove(extensionAddress)) {
            revert ExtensionNotInstalled();
        }
        Storage.context().extensionSelectors[extensionAddress].clear();
        (bool success,) = extensionAddress.call{gas: 1000000 /* max to 1M gas */ }(
            abi.encodeWithSelector(IPluggable.teardown.selector)
        );
        if (success) {
            emit ExtensionUninstalled(extensionAddress);
        } else {
            emit ExtensionUninstalledwithError(extensionAddress);
        }
    }

    /**
     * @dev uninstall a extension
     * @param extensionAddress extension address
     */
    function uninstallExtension(address extensionAddress) external virtual override {
        canManagePlugins();
        _uninstallExtension(extensionAddress);
    }

    /**
     * @dev Provides a list of all added extensions and their respective authorized function selectors
     * @return extensions An array of the addresses of all added extensions
     * @return selectors A 2D array where each inner array represents the function selectors
     * that the corresponding extension in the 'extensions' array is allowed to call
     */
    function listExtension()
        external
        view
        virtual
        override
        returns (address[] memory extensions, bytes4[][] memory selectors)
    {
        mapping(address => address) storage _extensions = _extensionMapping();
        uint256 extensionSize = _extensionMapping().size();
        extensions = new address[](extensionSize);
        mapping(address => mapping(bytes4 => bytes4)) storage extensionSelectors = Storage.context().extensionSelectors;
        selectors = new bytes4[][](extensionSize);

        uint256 i = 0;
        address addr = _extensions[AddressLinkedList.SENTINEL_ADDRESS];
        while (uint160(addr) > AddressLinkedList.SENTINEL_UINT) {
            {
                extensions[i] = addr;
                mapping(bytes4 => bytes4) storage extensionSelector = extensionSelectors[addr];

                {
                    uint256 selectorSize = extensionSelector.size();
                    bytes4[] memory _selectors = new bytes4[](selectorSize);
                    uint256 j = 0;
                    bytes4 selector = extensionSelector[SelectorLinkedList.SENTINEL_SELECTOR];
                    while (uint32(selector) > SelectorLinkedList.SENTINEL_UINT) {
                        _selectors[j] = selector;

                        selector = extensionSelector[selector];
                        unchecked {
                            j++;
                        }
                    }
                    selectors[i] = _selectors;
                }
            }

            addr = _extensions[addr];
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Allows a extension to execute a function within the system. This ensures that the
     * extension can only call functions it is permitted to.
     * @param dest The address of the destination contract where the function will be executed
     * @param value The amount of ether (in wei) to be sent with the function call
     * @param func The function data to be executed
     */
    function executeFromExtension(address dest, uint256 value, bytes memory func) external virtual override {
        if (_isAuthorizedExtension() == false) {
            revert UnauthorizedCaller();
        }

        if (dest == address(this)) revert UnexpectedRecursiveExecution();
        assembly ("memory-safe") {
            function allocate(length) -> pos {
                pos := mload(0x40)
                mstore(0x40, add(pos, length))
            }

            let result := call(gas(), dest, value, add(func, 0x20), mload(func), 0, 0)

            let returndataPtr := allocate(returndatasize())
            returndatacopy(returndataPtr, 0, returndatasize())

            if iszero(result) { revert(returndataPtr, returndatasize()) }
            return(returndataPtr, returndatasize())
        }
    }
}
