// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

interface IUpgradeExtension {
    event Upgrade(address indexed newLogic, address indexed oldLogic);

    function upgrade(address wallet) external;
}
