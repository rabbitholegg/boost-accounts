// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import "../BaseExtension.sol";
import "./IUpgradeExtension.sol";
import "../../interfaces/IUpgradeable.sol";

contract UpgradeExtension is BaseExtension, IUpgradeExtension {
    address public newImplementation;
    mapping(address => uint256) private _inited;
    mapping(address => bool) private _upgraded;

    constructor(address _newImplementation) {
        newImplementation = _newImplementation;
    }

    function inited(address wallet) internal view override returns (bool) {
        return _inited[wallet] != 0;
    }

    function _init(bytes calldata data) internal override {
        (data);
        _inited[sender()] = 1;
    }

    function _deInit() internal override {
        _inited[sender()] = 0;
    }

    function upgrade(address wallet) external override {
        require(_inited[wallet] != 0, "not inited");
        require(_upgraded[wallet] == false, "already upgraded");
        IUpgradeable(wallet).upgradeTo(newImplementation);
        _upgraded[wallet] = true;
    }

    function requiredFunctions() external pure override returns (bytes4[] memory) {
        bytes4[] memory _funcs = new bytes4[](1);
        _funcs[0] = IUpgradeable.upgradeTo.selector;
        return _funcs;
    }
}
