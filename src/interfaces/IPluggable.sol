// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Pluggable Interface
 * @dev This interface provides functionalities for setting up and tearing down account-related plugins or extensions
 */
interface IPluggable is IERC165 {
    /**
     * @notice Setup a specific extension or plugin for the account with the provided data
     * @param data Initialization data required for the extension or plugin
     */
    function setup(bytes calldata data) external;

    /**
     * @notice Tear down a specific extension or plugin from the account
     * @dev This function MUST succeed with a gas stipend of 100,000 or less
     */
    function teardown() external;
}
