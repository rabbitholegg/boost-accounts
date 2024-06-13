// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/IAccount.sol";

library UserOperationLib {
    /* 
        In calldata, the data structure of the UserOperation is always: 
                refer to:https://docs.soliditylang.org/en/develop/abi-spec.html
         offset: 0x00   000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa # sender
         offset: 0x20   000000000000000000000000000000000000000000000000000b0b0b0b0b0b0b # nonce
         offset: 0x40   0000000000000000000000000000000000000000000000000000000000000160 # initCode offset
         offset: 0x60   00000000000000000000000000000000000000000000000000000000000001a0 # callData offset
         offset: 0x80   000000000000000000000000000000000000000000000000000e0e0e0e0e0e0e # accountGasLimits
         offset: 0xa0   0000000000000000000000000000000000000000000000000010101010101010 # preVerificationGas
         offset: 0xc0   0000000000000000000000000000000000000000000000000011111111111111 # maxPriorityFeePerGas & maxFeePerGas
         offset: 0xe0   00000000000000000000000000000000000000000000000000000000000001e0 # paymasterAndData offset
         offset:0x100   0000000000000000000000000000000000000000000000000000000000000220 # signature offset
                        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ──┐
                        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx   │ dynamic data
                        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx   │
                        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ──┘
     */
    function getSignature(PackedUserOperation calldata userOp) internal pure returns (bytes calldata signature) {
        // this is ~121 gas units more efficient than using `abi.decode`
        assembly ("memory-safe") {
            let userOpOffset := userOp
            let signatureOffset := add(userOpOffset, calldataload(add(userOpOffset, 0x100)))
            signature.length := calldataload(signatureOffset)
            signature.offset := add(signatureOffset, 0x20)
        }
    }
}
