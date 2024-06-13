// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {IAccountExecute, PackedUserOperation} from "@account-abstraction/contracts/interfaces/IAccountExecute.sol";

import {Authority} from "./Authority.sol";
import {ExecutableCapability} from "../capabilities/Executable.sol";

/**
 * @title Executable
 * @dev Executable is a base contract for accounts that can execute user operations.
 */
abstract contract Executable is Authority, IAccountExecute, ExecutableCapability {
    /**
     * Account may implement this execute method.
     * passing this methodSig at the beginning of callData will cause the entryPoint to pass the full UserOp (and hash)
     * to the account.
     * The account should skip the methodSig, and use the callData (and optionally, other UserOp fields)
     *
     * @param userOp              - The operation that was just validated.
     * @param userOpHash          - Hash of the user's request data.
     */
    function executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external override {
        canExecute();
        _executeUserOp(userOp, userOpHash);
    }

    /**
     * @dev Why need an unimplemented function `executeUserOp`?
     * In Entrypoint v0.7.0, `executeUserOp` was added (https://github.com/eth-infinitism/account-abstraction/commit/346c7bf5bb5a880bfc37fbd811b94b9e08d5647c).
     * Although it is temporarily unnecessary to implement this function in our current implementation,
     * considering that not implementing this function may result in executing `executeUserOp` through a call in the fallback()
     * to execute other unknown functions, and that it may also not correctly identify whether a calldata is executed successfully in the eventLog,
     * we add an empty function implementation here that simply revert.
     */
    function _executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) internal virtual override {
        (userOp, userOpHash);
        revert("Not implemented");
    }
}
