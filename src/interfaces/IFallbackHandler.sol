// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

interface IFallbackHandler {
    /**
     * @notice Emitted when the fallback contract is changed
     * @param fallbackContract The address of the newly set fallback contract
     */
    event FallbackChanged(address indexed fallbackContract);

    /**
     * @notice Set a new fallback contract
     * @dev This function allows setting a new address as the fallback contract. The fallback contract will receive
     * all calls made to this contract that do not match any other function
     * @param fallbackContract The address of the fallback contract to be set
     */
    function setFallbackHandler(address fallbackContract) external;
}
