// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

/// @title FallbackHandlerCapability
/// @notice Adds the ability to set a fallback handler contract which will be called when the account receives ether or a call to an undefined function.
abstract contract FallbackHandlerCapability {
    /**
     * @dev Sets the address of the fallback handler contract
     * @param fallbackContract The address of the new fallback handler contract
     */
    function _setFallbackHandler(address fallbackContract) internal virtual;
}
