// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import "../../BaseExtension.sol";
import "./SocialRecoveryBase.sol";

/**
 * @title SocialRecoveryExtension
 * @dev This contract extends BaseExtension and SocialRecoveryBase to provide social recovery functionality for a wallet.
 * It allows a wallet owner to set a list of keepers and a recovery delay period. If the wallet is lost or compromised,
 * the keepers can recover the wallet after the delay period has passed.
 */
contract SocialRecoveryExtension is BaseExtension, SocialRecoveryBase {
    bytes4 private constant _FUNC_RESET_OWNER = bytes4(keccak256("resetOwner(bytes32)"));
    bytes4 private constant _FUNC_RESET_OWNERS = bytes4(keccak256("resetOwners(bytes32[])"));
    mapping(address => bool) walletInited;

    event SocialRecoveryInitialized(address indexed wallet, bytes32 keeperHash, uint256 delayPeriod);
    event SocialRecoveryDeInitialized(address indexed wallet);

    constructor() EIP712("SocialRecovery", "1") {}

    /**
     * @dev De-initializes the social recovery settings for the sender's wallet.
     */
    function _deInit() internal override {
        address _sender = sender();
        _clearWalletSocialRecoveryInfo(_sender);
        walletInited[_sender] = false;
        emit SocialRecoveryDeInitialized(_sender);
    }

    /**
     * @dev Initializes the social recovery settings for the sender's wallet.
     * @param _data The encoded keeper hash and delay period.
     */
    function _init(bytes calldata _data) internal override {
        address _sender = sender();
        (bytes32 keeperHash, uint256 delayPeriod) = abi.decode(_data, (bytes32, uint256));
        _setKeeperHash(_sender, keeperHash);
        _setDelayPeriod(_sender, delayPeriod);
        walletInited[_sender] = true;
        emit SocialRecoveryInitialized(_sender, keeperHash, delayPeriod);
    }

    /**
     * @dev Checks if the social recovery settings for a wallet have been initialized.
     * @param wallet The address of the wallet.
     * @return A boolean indicating whether the social recovery settings for the wallet have been initialized.
     */
    function inited(address wallet) internal view override returns (bool) {
        return walletInited[wallet];
    }

    /**
     * @dev Returns the list of functions required by this extension.
     * @return An array of function selectors.
     */
    function requiredFunctions() external pure override returns (bytes4[] memory) {
        bytes4[] memory functions = new bytes4[](2);
        functions[0] = _FUNC_RESET_OWNER;
        functions[1] = _FUNC_RESET_OWNERS;
        return functions;
    }
}
