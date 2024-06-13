// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

interface IOwnable {
    /**
     * @notice Checks if a given bytes32 ID corresponds to an owner within the system
     * @param owner The bytes32 ID to check
     * @return True if the ID corresponds to an owner, false otherwise
     */
    function isOwner(bytes32 owner) external view returns (bool);
}
