// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IManageable} from "./IManageable.sol";

interface IMultiOwnerManager is IManageable {
    function addOwners(bytes32[] calldata owners) external;
    function resetOwners(bytes32[] calldata newOwners) external;
}
