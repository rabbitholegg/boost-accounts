// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {Authority} from "./Authority.sol";
import {IStandardExecutor, Execution} from "../interfaces/IStandardExecutor.sol";
import {HasEntrypoint} from "./HasEntrypoint.sol";

abstract contract StandardExecutor is Authority, IStandardExecutor, HasEntrypoint {
    /**
     * @dev execute method
     * only entrypoint can call this method
     * @param target the target address
     * @param value the value
     * @param data the data
     */
    function execute(address target, uint256 value, bytes calldata data) external payable virtual override {
        canExecute();

        assembly ("memory-safe") {
            function allocate(length) -> pos {
                pos := mload(0x40)
                mstore(0x40, add(pos, length))
            }

            let calldataPtr := allocate(data.length)
            calldatacopy(calldataPtr, data.offset, data.length)

            let result := call(gas(), target, value, calldataPtr, data.length, 0, 0)

            // note: return data is ignored
            if iszero(result) {
                let returndataPtr := allocate(returndatasize())
                returndatacopy(returndataPtr, 0, returndatasize())
                revert(returndataPtr, returndatasize())
            }
        }
    }

    /**
     * @dev execute batch method
     * only entrypoint can call this method
     * @param executions the executions
     */
    function executeBatch(Execution[] calldata executions) external payable virtual override {
        canExecute();

        for (uint256 i = 0; i < executions.length; i++) {
            Execution calldata execution = executions[i];
            address target = execution.target;
            uint256 value = execution.value;
            bytes calldata data = execution.data;

            assembly ("memory-safe") {
                function allocate(length) -> pos {
                    pos := mload(0x40)
                    mstore(0x40, add(pos, length))
                }

                let calldataPtr := allocate(data.length)
                calldatacopy(calldataPtr, data.offset, data.length)

                let result := call(gas(), target, value, calldataPtr, data.length, 0, 0)

                // note: return data is ignored
                if iszero(result) {
                    let returndataPtr := allocate(returndatasize())
                    returndatacopy(returndataPtr, 0, returndatasize())
                    revert(returndataPtr, returndatasize())
                }
            }
        }
    }
}
