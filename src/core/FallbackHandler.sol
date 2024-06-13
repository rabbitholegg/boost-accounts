// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {Storage} from "../utils/Storage.sol";
import {Authority} from "./Authority.sol";
import {FallbackHandlerCapability} from "../capabilities/FallbackHandler.sol";
import {IFallbackHandler} from "../interfaces/IFallbackHandler.sol";

abstract contract FallbackHandler is IFallbackHandler, Authority, FallbackHandlerCapability {
    receive() external payable virtual {}

    /**
     * @dev Sets the address of the fallback handler contract
     * @param fallbackContract The address of the new fallback handler contract
     */
    function _setFallbackHandler(address fallbackContract) internal virtual override {
        Storage.context().defaultFallbackContract = fallbackContract;
    }

    /**
     * @notice Fallback function that forwards all requests to the fallback handler contract
     * @dev The request is forwarded using a STATICCALL
     * It ensures that the state of the contract doesn't change even if the fallback function has state-changing operations
     */
    fallback() external payable virtual {
        address fallbackContract = Storage.context().defaultFallbackContract;
        assembly ("memory-safe") {
            function allocate(length) -> pos {
                pos := mload(0x40)
                mstore(0x40, add(pos, length))
            }

            if iszero(fallbackContract) { return(0, 0) }
            let calldataPtr := allocate(calldatasize())
            calldatacopy(calldataPtr, 0, calldatasize())

            let result := staticcall(gas(), fallbackContract, calldataPtr, calldatasize(), 0, 0)

            let returndataPtr := allocate(returndatasize())
            returndatacopy(returndataPtr, 0, returndatasize())

            if iszero(result) { revert(returndataPtr, returndatasize()) }
            return(returndataPtr, returndatasize())
        }
    }

    /**
     * @notice Sets the address of the fallback handler and emits the FallbackChanged event
     * @param fallbackContract The address of the new fallback handler
     */
    function setFallbackHandler(address fallbackContract) external virtual override {
        canManageFallbacks();
        _setFallbackHandler(fallbackContract);
        emit FallbackChanged(fallbackContract);
    }
}
