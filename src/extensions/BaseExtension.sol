// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import "./IBoostAccountExtension.sol";
import "../interfaces/IExtendable.sol";

/**
 * @title BaseExtension
 * @notice An abstract base contract that provides a foundation for other extensions.
 * It ensures the initialization, de-initialization, and proper authorization of extensions.
 */
abstract contract BaseExtension is IBoostAccountExtension {
    event ExtensionInit(address indexed wallet);
    event ExtensionDeInit(address indexed wallet);

    /**
     * @notice Checks if the extension is initialized for a particular wallet.
     * @param wallet Address of the wallet.
     * @return True if the extension is initialized, false otherwise.
     */
    function inited(address wallet) internal view virtual returns (bool);

    /**
     * @notice Initialization logic for the extension.
     * @param data Initialization data for the extension.
     */
    function _init(bytes calldata data) internal virtual;

    /**
     * @notice De-initialization logic for the extension.
     */
    function _deInit() internal virtual;

    /**
     * @notice Helper function to get the sender of the transaction.
     * @return Address of the transaction sender.
     */
    function sender() internal view returns (address) {
        return msg.sender;
    }

    /**
     * @notice Initializes the extension for a wallet.
     * @param data Initialization data for the extension.
     */
    function setup(bytes calldata data) external {
        address _sender = sender();
        if (!inited(_sender)) {
            if (!IExtendable(_sender).isInstalledExtension(address(this))) {
                revert("not authorized extension");
            }
            _init(data);
            emit ExtensionInit(_sender);
        }
    }

    /**
     * @notice De-initializes the extension for a wallet.
     */
    function teardown() external {
        address _sender = sender();
        if (inited(_sender)) {
            if (IExtendable(_sender).isInstalledExtension(address(this))) {
                revert("authorized extension");
            }
            _deInit();
            emit ExtensionDeInit(_sender);
        }
    }
    /**
     * @notice Verifies if the extension supports a specific interface.
     * @param interfaceId ID of the interface to be checked.
     * @return True if the extension supports the given interface, false otherwise.
     */

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IBoostAccountExtension).interfaceId || interfaceId == type(IPluggable).interfaceId;
    }
}
