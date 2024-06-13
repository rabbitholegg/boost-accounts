// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/IAccount.sol";

import {IPluggable} from "./IPluggable.sol";

interface IHook is IPluggable {
    /*
        NOTE: Any implementation must ensure that the `hookSignature` exactly matches your expectations, 
              otherwise, you will face security risks.
              For example: 
                if you do not require any `hookSignature`, make sure your implementation included the following code:
                `require(hookSignature.length == 0)`
        
        NOTE: All implemention must ensure that the teardown() function can be covered by 100,000 gas in all scenarios.
     */

    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param hookSignature Signature byte array associated with _data
     */
    function preIsValidSignatureHook(bytes32 hash, bytes calldata hookSignature) external view;

    /**
     * @dev Hook that is called before any userOp is executed.
     * NOTE: Do not rely on userOperation.signature, which may be empty in some versions of the implementation. see: /contracts/utils/CalldataPack.sol
     * must revert if the userOp is invalid.
     */
    function preUserOpValidationHook(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds,
        bytes calldata hookSignature
    ) external;
}
