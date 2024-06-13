// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

interface IExtendable {
    /**
     * @notice Emitted when a extension is installed
     * @param extension extension
     */
    event ExtensionInstalled(address extension);

    /**
     * @notice Emitted when a extension is uninstalled
     * @param extension extension
     */
    event ExtensionUninstalled(address extension);

    /**
     * @notice Emitted when a extension is uninstalled with error
     * @param extension extension
     */
    event ExtensionUninstalledwithError(address extension);

    function uninstallExtension(address extensionAddress) external;

    function isInstalledExtension(address extension) external view returns (bool);

    /**
     * @notice Provides a list of all added extensions and their respective authorized function selectors
     * @return extensions An array of the addresses of all added extensions
     * @return selectors A 2D array where each inner array represents the function selectors
     * that the corresponding extension in the 'extensions' array is allowed to call
     */
    function listExtension() external view returns (address[] memory extensions, bytes4[][] memory selectors);
    /**
     * @notice Allows a extension to execute a function within the system. This ensures that the
     * extension can only call functions it is permitted to, based on its declared `requiredFunctions`
     * @param dest The address of the destination contract where the function will be executed
     * @param value The amount of ether (in wei) to be sent with the function call
     * @param func The function data to be executed
     */
    function executeFromExtension(address dest, uint256 value, bytes calldata func) external;
}
