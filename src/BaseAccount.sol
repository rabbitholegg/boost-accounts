// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {IAccount, PackedUserOperation} from "@account-abstraction/contracts/interfaces/IAccount.sol";

import {HasEntrypoint} from "./core/HasEntrypoint.sol";
import {Executable} from "./core/Executable.sol";
import {Extendable} from "./core/Extendable.sol";
import {FallbackHandler} from "./core/FallbackHandler.sol";
import {Hookable} from "./core/Hookable.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {Manageable} from "./core/Manageable.sol";
import {SignatureDecoder} from "./utils/SignatureDecoder.sol";
import {StandardExecutor} from "./core/StandardExecutor.sol";
import {UserOperationLib} from "./utils/UserOperationLib.sol";
import {Validatable} from "./core/Validatable.sol";

/**
 *             $$$$$$$\                                 $$\
 *             $$  __$$\                                $$ |
 *             $$ |  $$ | $$$$$$\   $$$$$$\   $$$$$$$\$$$$$$\
 *             $$$$$$$\ |$$  __$$\ $$  __$$\ $$  _____\_$$  _
 *             $$  __$$\ $$ /  $$ |$$ /  $$ |\$$$$$$\   $$ |
 *             $$ |  $$ |$$ |  $$ |$$ |  $$ | \____$$\  $$ |$$\
 *   $$$$$$\   $$$$$$$  |\$$$$$$  |\$$$$$$  |$$$$$$$  | \$$$$  |$$\
 *  $$  __$$\  \_______/  \______/  \______/ \_______/   \____/ $$ |
 *  $$ /  $$ | $$$$$$$\  $$$$$$$\  $$$$$$\  $$\   $$\ $$$$$$$\$$$$$$\    $$$$$$$\
 *  $$$$$$$$ |$$  _____|$$  _____|$$  __$$\ $$ |  $$ |$$  __$$\_$$  _|  $$  _____
 *  $$  __$$ |$$ /      $$ /      $$ /  $$ |$$ |  $$ |$$ |  $$ |$$ |    \$$$$$$\
 *  $$ |  $$ |$$ |      $$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |$$\  \____$$\
 *  $$ |  $$ |\$$$$$$$\ \$$$$$$$\ \$$$$$$  |\$$$$$$  |$$ |  $$ |\$$$$  |$$$$$$$  |
 *  \__|  \__| \_______| \_______| \______/  \______/ \__|  \__| \____/ \_______/
 *
 * @title BaseAccount
 * @notice A base ERC-4337 account abstraction implementation that provides the basic functionality for
 *         managing the account's state, executing operations, and handling fallback calls. It supports
 *         flexible validator models, hooks for pre/post validation and execution stages of an operation,
 *         and a pluggable extension architecture for adding custom functionality.
 */
contract BaseAccount is
    IAccount,
    IERC1271,
    HasEntrypoint,
    Extendable,
    Manageable,
    Hookable,
    StandardExecutor,
    Executable,
    Validatable,
    FallbackHandler
{
    constructor(address _entryPoint) HasEntrypoint(_entryPoint) {}

    /**
     * @dev EIP-1271
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _hash
     */
    function isValidSignature(bytes32 hash, bytes calldata signature)
        public
        view
        virtual
        override
        returns (bytes4 magicValue)
    {
        (address validator, bytes calldata validatorSignature, bytes calldata hookSignature) =
            SignatureDecoder.signatureSplit(signature);

        /*
            Warning!!!
                This function uses `return` to terminate the execution of the entire contract.
                If any `Hook` fails, this function will stop the contract's execution and
                return `bytes4(0)`, skipping all the subsequent unexecuted code.
        */
        _preIsValidSignatureHook(hash, hookSignature);

        /*
            When any hook execution fails, this line will not be executed.
         */
        return _isValidSignature(hash, validator, validatorSignature);
    }

    /**
     * @dev If you need to redefine the signatures structure, please override this function.
     */
    function _decodeSignature(bytes calldata signature)
        internal
        view
        virtual
        returns (address validator, bytes calldata validatorSignature, bytes calldata hookSignature)
    {
        return SignatureDecoder.signatureSplit(signature);
    }

    /**
     * Validate user's signature and nonce
     * @param userOp The operation that is about to be executed.
     * @param userOpHash Hash of the user's request data. can be used as the basis for signature.
     * @param missingAccountFunds Missing funds on the account's deposit in the entrypoint.
     */
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        public
        virtual
        override
        returns (uint256 validationData)
    {
        _onlyEntryPoint();

        assembly ("memory-safe") {
            if missingAccountFunds {
                // ignore failure (its EntryPoint's job to verify, not account.)
                pop(call(gas(), caller(), missingAccountFunds, 0x00, 0x00, 0x00, 0x00))
            }
        }
        (address validator, bytes calldata validatorSignature, bytes calldata hookSignature) =
            _decodeSignature(UserOperationLib.getSignature(userOp));

        /*
            Warning!!!
                This function uses `return` to terminate the execution of the entire contract.
                If any `Hook` fails, this function will stop the contract's execution and
                return `SIG_VALIDATION_FAILED`, skipping all the subsequent unexecuted code.
        */
        _preUserOpValidationHook(userOp, userOpHash, missingAccountFunds, hookSignature);

        /*
            When any hook execution fails, this line will not be executed.
         */
        return _validateUserOp(userOp, userOpHash, validator, validatorSignature);
    }
}
