// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {Validatable} from "../core/Validatable.sol";
import {IValidatorManager} from "../interfaces/IValidatorManager.sol";

abstract contract ValidatorManager is IValidatorManager, Validatable {
    function installValidator(bytes calldata validatorAndData) external virtual override {
        canManageValidators();
        _installValidator(address(bytes20(validatorAndData[:20])), validatorAndData[20:]);
    }
}
