// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/IAccount.sol";

import {Authority} from "./Authority.sol";
import {IValidatable} from "../interfaces/IValidatable.sol";
import {IValidator} from "../interfaces/IValidator.sol";
import {Storage} from "../utils/Storage.sol";
import {AddressLinkedList} from "../utils/AddressLinkedList.sol";
import {SIG_VALIDATION_FAILED} from "../utils/Constants.sol";
import {ValidatableCapability} from "../capabilities/Validatable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IPluggable} from "../interfaces/IPluggable.sol";
import {CallDataPack} from "../utils/CalldataPack.sol";

abstract contract Validatable is Authority, IValidatable, ValidatableCapability {
    using AddressLinkedList for mapping(address => address);

    error ValidatorInvalid();
    error ValidatorExists();
    error ValidatorNotFound();

    bytes4 private constant INTERFACE_ID_VALIDATOR = type(IValidator).interfaceId;

    /**
     * @dev checks whether a address is a installed validator
     */
    function _isInstalledValidator(address validator) internal view virtual override returns (bool) {
        return Storage.context().validators.isExist(validator);
    }

    /**
     * @dev checks whether a address is a valid validator
     * note: If you need to extend the interface, override this function
     * @param validator validator address
     */
    function _isSupportsValidatorInterface(address validator) internal view virtual override returns (bool supported) {
        bytes memory callData = abi.encodeWithSelector(IERC165.supportsInterface.selector, INTERFACE_ID_VALIDATOR);
        assembly ("memory-safe") {
            let result := staticcall(gas(), validator, add(callData, 0x20), mload(callData), 0x00, 0x20)
            if and(result, eq(returndatasize(), 32)) { supported := mload(0x00) }
        }
    }

    /**
     * @dev install a validator
     */
    function _installValidator(address validator, bytes memory initData) internal virtual override {
        if (_isInstalledValidator(validator)) {
            revert ValidatorExists();
        }

        if (_isSupportsValidatorInterface(validator) == false) {
            revert ValidatorInvalid();
        }

        Storage.context().validators.add(validator);

        bytes memory callData = abi.encodeWithSelector(IPluggable.setup.selector, initData);
        bytes4 invalidValidatorSelector = ValidatorInvalid.selector;
        assembly ("memory-safe") {
            let result := call(gas(), validator, 0, add(callData, 0x20), mload(callData), 0x00, 0x00)
            if iszero(result) {
                mstore(0x00, invalidValidatorSelector)
                revert(0x00, 4)
            }
        }

        emit ValidatorInstalled(validator);
    }

    /**
     * @dev uninstall a validator
     */
    function _uninstallValidator(address validator) internal virtual override {
        if (!Storage.context().validators.tryRemove(validator)) {
            revert ValidatorNotFound();
        }
        (bool success,) =
            validator.call{gas: 1000000 /* max to 1M gas */ }(abi.encodeWithSelector(IPluggable.teardown.selector));
        if (success) {
            emit ValidatorUninstalled(validator);
        } else {
            emit ValidatorUninstalledwithError(validator);
        }
    }

    /**
     * @dev uninstall a validator
     */
    function uninstallValidator(address validator) external virtual override {
        canManageValidators();
        _uninstallValidator(validator);
    }

    /**
     * @dev list validators
     */
    function listValidator() external view virtual override returns (address[] memory validators) {
        mapping(address => address) storage validator = Storage.context().validators;
        validators = validator.list(AddressLinkedList.SENTINEL_ADDRESS, validator.size());
    }

    /**
     * @dev EIP-1271
     * @param hash hash of the data to be signed
     * @param validator validator address
     * @param validatorSignature Signature byte array associated with _data
     * @return magicValue Magic value 0x1626ba7e if the validator is registered and signature is valid
     */
    function _isValidSignature(bytes32 hash, address validator, bytes calldata validatorSignature)
        internal
        view
        virtual
        override
        returns (bytes4 magicValue)
    {
        if (_isInstalledValidator(validator) == false) {
            return bytes4(0);
        }
        bytes memory callData =
            abi.encodeWithSelector(IValidator.validateSignature.selector, msg.sender, hash, validatorSignature);
        assembly ("memory-safe") {
            let result := staticcall(gas(), validator, add(callData, 0x20), mload(callData), 0x00, 0x20)
            /* 
                Since the validator's compliance with the expected interface has been confirmed before,
                we don't need to handle the scenario where `result=true` but the `returndata` is not returned as expected here.
             */
            if result { magicValue := mload(0x00) }
        }
    }

    /**
     * @dev validate UserOperation
     * @param userOp UserOperation
     * @param userOpHash UserOperation hash
     * @param validator validator address
     * @param validatorSignature validator signature
     * @return validationData refer to https://github.com/eth-infinitism/account-abstraction/blob/v0.6.0/contracts/interfaces/IAccount.sol#L24-L30
     */
    function _validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        address validator,
        bytes calldata validatorSignature
    ) internal virtual override returns (uint256 validationData) {
        if (_isInstalledValidator(validator) == false) {
            return SIG_VALIDATION_FAILED;
        }

        // abi.encodeWithSelector(IValidator.validateUserOp.selector, userOp, userOpHash, validatorSignature);
        bytes memory callData = CallDataPack.encodeWithoutUserOpSignature_validateUserOp_UserOperation_bytes32_bytes(
            userOp, userOpHash, validatorSignature
        );
        assembly ("memory-safe") {
            let result := call(gas(), validator, 0, add(callData, 0x20), mload(callData), 0x00, 0x20)
            if iszero(result) { mstore(0x00, SIG_VALIDATION_FAILED) }
            /* 
                Since the validator's compliance with the expected interface has been confirmed before,
                we don't need to handle the scenario where `result=true` but the `returndata` is not returned as expected here.
             */
            validationData := mload(0x00)
        }
    }
}
