// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IValidatable} from "./IValidatable.sol";

interface IValidatorManager is IValidatable {
    function installValidator(bytes calldata validatorAndData) external;
}
