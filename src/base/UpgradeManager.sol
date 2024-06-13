// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import "../interfaces/IUpgradeable.sol";

/**
 * @title UpgradeManager
 * @dev This contract allows for the logic of a proxy to be upgraded
 */
abstract contract UpgradeManager is IUpgradeable {
    error InvalidLogicAddress();
    error SameLogicAddress();
    error UpgradeFailed();

    /**
     * @dev Storage slot with the address of the current implementation
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Upgrades the logic to a new implementation
     * @param newImplementation Address of the new implementation
     */
    function _upgradeTo(address newImplementation) internal {
        bool isContract;
        assembly ("memory-safe") {
            isContract := gt(extcodesize(newImplementation), 0)
        }
        if (!isContract) revert InvalidLogicAddress();

        address oldImplementation;
        assembly ("memory-safe") {
            oldImplementation := and(sload(_IMPLEMENTATION_SLOT), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        if (oldImplementation == newImplementation) revert SameLogicAddress();

        // Save the new implementation address
        assembly ("memory-safe") {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }

        // Call the new implementation's upgradeFrom function and revert if it fails
        (bool success,) =
            newImplementation.delegatecall(abi.encodeWithSelector(IUpgradeable.upgradeFrom.selector, oldImplementation));
        if (!success) revert UpgradeFailed();

        emit Upgraded(oldImplementation, newImplementation);
    }
}
