// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {AuthorityCapability} from "../capabilities/Authority.sol";
import {ValidatableCapability} from "../capabilities/Validatable.sol";

abstract contract ValidatorInstaller is AuthorityCapability, ValidatableCapability {
    /**
     * @dev Install a validator
     * @param validatorAndData [0:20]: validator address, [20:]: validator data
     */
    function installValidator(bytes calldata validatorAndData) external {
        canManageValidators();
        _installValidator(address(bytes20(validatorAndData[:20])), validatorAndData[20:]);
    }
}
