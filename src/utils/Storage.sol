// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

/**
 * @title Storage
 * @notice A library that defines the storage context for Boost Accounts.
 */
library Storage {
    bytes32 internal constant _ACCOUNT_SLOT = keccak256("@boost/accounts/contracts/utils/Storage");

    /// @notice The storage context for a Boost Account.
    /// @param owners The owners of the account.
    struct Context {
        mapping(bytes32 => bytes32) owners;
        address defaultFallbackContract;
        mapping(address => address) validators;
        mapping(address => address) preIsValidSignatureHook;
        mapping(address => address) preUserOpValidationHook;
        mapping(address => address) extensions;
        mapping(address => mapping(bytes4 => bytes4)) extensionSelectors;
    }

    /**
     * @notice Get the storage context for the account.
     * @return ctx The account's storage context.
     */
    function context() internal pure returns (Context storage ctx) {
        bytes32 slot = _ACCOUNT_SLOT;
        assembly ("memory-safe") {
            ctx.slot := slot
        }
    }
}
