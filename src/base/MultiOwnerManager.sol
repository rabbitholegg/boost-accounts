// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Manageable} from "../core/Manageable.sol";
import {IMultiOwnerManager} from "../interfaces/IMultiOwnerManager.sol";

abstract contract MultiOwnerManager is IMultiOwnerManager, Manageable {
    function _addOwners(bytes32[] calldata owners) internal {
        for (uint256 i = 0; i < owners.length;) {
            _addOwner(owners[i]);
            unchecked {
                i++;
            }
        }
    }

    function addOwners(bytes32[] calldata owners) external override {
        canManageOwnership();
        _addOwners(owners);
    }

    function resetOwners(bytes32[] calldata newOwners) external override {
        canManageOwnership();
        _clearOwner();
        _addOwners(newOwners);
    }
}
