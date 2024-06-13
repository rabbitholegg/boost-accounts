// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAccount, PackedUserOperation} from "@account-abstraction/contracts/interfaces/IAccount.sol";
import {HasEntrypoint} from "./core/HasEntrypoint.sol";
import {FallbackHandler} from "./core/FallbackHandler.sol";
import {StandardExecutor} from "./core/StandardExecutor.sol";
import {Validatable} from "./core/Validatable.sol";
import {SignatureDecoder} from "./utils/SignatureDecoder.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./base/ERC1271Handler.sol";
import {MultiOwnerManager} from "./base/MultiOwnerManager.sol";
import {ExtensionManager} from "./base/ExtensionManager.sol";
import {Hookable} from "./core/Hookable.sol";
import {UpgradeManager} from "./base/UpgradeManager.sol";

/**
 * @title 
 * @dev This contract is the main entry point for the . It implements the IAccount and IERC1271 interfaces,
 * and is compatible with the ERC-4337 standard.
 * It inherits from multiple base contracts and managers to provide the core functionality of the wallet.
 * This includes managing entry points, owners, extensions, hooks, and upgrades, as well as handling ERC1271 signatures and providing a fallback function.
 */
contract BoostAccount is
    Initializable,
    IAccount,
    IERC1271,
    HasEntrypoint,
    MultiOwnerManager,
    ExtensionManager,
    Hookable,
    StandardExecutor,
    Validatable,
    UpgradeManager,
    FallbackHandler,
    ERC1271Handler
{
    error NoUpgradeLogicDefined();

    address internal immutable _DEFAULT_VALIDATOR;

    constructor(address _entryPoint, address defaultValidator) HasEntrypoint(_entryPoint) {
        _DEFAULT_VALIDATOR = defaultValidator;
        _disableInitializers();
    }

    /**
     * @notice Initializes the  contract
     * @dev This function can only be called once. It sets the initial owners, default callback handler, extensions, and hooks.
     */
    function initialize(
        bytes32[] calldata owners,
        address defalutCallbackHandler,
        bytes[] calldata extensions,
        bytes[] calldata hooks
    ) external initializer {
        _addOwners(owners);
        _setFallbackHandler(defalutCallbackHandler);
        _installValidator(_DEFAULT_VALIDATOR, hex"");
        for (uint256 i = 0; i < extensions.length;) {
            _addExtension(extensions[i]);
            unchecked {
                i++;
            }
        }
        for (uint256 i = 0; i < hooks.length;) {
            bytes calldata hookData = hooks[i];
            _installHook(
                address(bytes20(hookData[:20])),
                hookData[20:hookData.length - 1],
                uint8(bytes1((hookData[hookData.length - 1:hookData.length])))
            );
            unchecked {
                i++;
            }
        }
    }

    function _uninstallValidator(address validator) internal override {
        require(validator != _DEFAULT_VALIDATOR, "can't uninstall default validator");
        super._uninstallValidator(validator);
    }

    function isValidSignature(bytes32 _hash, bytes calldata signature)
        public
        view
        override
        returns (bytes4 magicValue)
    {
        bytes32 datahash = _encodeRawHash(_hash);

        (address validator, bytes calldata validatorSignature, bytes calldata hookSignature) =
            SignatureDecoder.signatureSplit(signature);
        _preIsValidSignatureHook(datahash, hookSignature);
        return _isValidSignature(datahash, validator, validatorSignature);
    }

    function _decodeSignature(bytes calldata signature)
        internal
        pure
        virtual
        returns (address validator, bytes calldata validatorSignature, bytes calldata hookSignature)
    {
        return SignatureDecoder.signatureSplit(signature);
    }

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
            _decodeSignature(userOp.signature);

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

    /*
    The permission to upgrade the logic contract is exclusively granted to extensions (UpgradeExtension),
    meaning that even the wallet owner cannot directly invoke `upgradeTo` for upgrades.
    This design is implemented for security reasons, ensuring that even if the signer's credentials
    are compromised, attackers cannot upgrade the logic contract, potentially rendering the wallet unusable.
    Users can regain control over their wallet through social recovery mechanisms.
    This approach safeguards the wallet's integrity, maintaining its availability and security.
    */
    function upgradeTo(address newImplementation) external override {
        _onlyExtension();
        _upgradeTo(newImplementation);
    }

    /// @notice Handles the upgrade from an old implementation
    /// @param oldImplementation Address of the old implementation
    function upgradeFrom(address oldImplementation) external pure override {
        (oldImplementation);
        revert NoUpgradeLogicDefined();
    }
}