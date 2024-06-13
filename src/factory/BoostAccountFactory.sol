// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

import "../BaseAccount.sol";

/**
 * @title BoostAccountFactory
 * @notice A factory contract to create Boost Accounts
 * @dev This contract is called by the entrypoint which uses the "initCode" to create and return the sender's wallet address
 */
contract BoostAccountFactory is Ownable {
    address public immutable WALLET_IMPLEMENTATION;
    IEntryPoint public immutable entryPoint;
    string public constant VERSION = "0.0.1";

    event BoostAccountCreation(address indexed proxy);

    /**
     * @dev Initializes the factory with the wallet implementation and entry point addresses
     * @param _walletImpl Address of the BoostAccount implementation
     * @param _entryPoint Address of the EntryPoint contract
     * @param _owner Address of the contract owner
     */
    constructor(address _walletImpl, address _entryPoint, address _owner) Ownable(_owner) {
        require(WALLET_IMPLEMENTATION != address(0), "Invalid wallet implementation address");
        WALLET_IMPLEMENTATION = _walletImpl;
        require(_entryPoint != address(0), "Invalid entry point address");
        entryPoint = IEntryPoint(_entryPoint);
    }

    function _calcSalt(bytes memory _initializer, bytes32 _salt) private pure returns (bytes32 salt) {
        return keccak256(abi.encodePacked(keccak256(_initializer), _salt));
    }

    /**
     * @dev Deploys a BoostAccount and returns its proxy
     * @param _initializer Initialization data
     * @param _salt Salt for the create2 deployment
     * @return proxy Address of the deployed proxy
     */
    function createWallet(bytes memory _initializer, bytes32 _salt) external returns (address proxy) {
        // In accordance with the ERC-4337 spec, this method will NOT revert if the wallet has already been
        // created. In this case, it will simply return the address of the existing wallet.
        address addr = getWalletAddress(_initializer, _salt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return addr;
        }
        bytes memory deploymentData = _proxyCode(WALLET_IMPLEMENTATION);
        bytes32 salt = _calcSalt(_initializer, _salt);
        assembly ("memory-safe") {
            proxy := create2(0x0, add(deploymentData, 0x20), mload(deploymentData), salt)
        }
        if (proxy == address(0)) {
            revert();
        }
        assembly ("memory-safe") {
            let succ := call(gas(), proxy, 0, add(_initializer, 0x20), mload(_initializer), 0, 0)
            if eq(succ, 0) { revert(0, 0) }
        }
        emit BoostAccountCreation(proxy);
    }

    /**
     * @notice Returns the proxy's creation code
     * @dev Used by BoostAccountlib to calculate the BoostAccount address
     * @return Byte array representing the proxy's creation code
     */
    function proxyCode() external view returns (bytes memory) {
        return _proxyCode(WALLET_IMPLEMENTATION);
    }
    /**
     * @notice  using solay ERC1967 https://github.com/Vectorized/solady/blob/5eff720c27746987dc95e5e2b720615d3d96f7ee/src/utils/LibClone.sol#L774C18-L774C18
     */

    function _proxyCode(address implementation) private pure returns (bytes memory deploymentData) {
        deploymentData = abi.encodePacked(
            hex"603d3d8160223d3973",
            implementation,
            hex"60095155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3"
        );
    }

    /**
     * @notice Calculates the counterfactual address of the BoostAccount as it would be returned by `createWallet`
     * @param _initializer Initialization data
     * @param _salt Salt for the create2 deployment
     * @return proxy Counterfactual address of the BoostAccount
     */
    function getWalletAddress(bytes memory _initializer, bytes32 _salt) public view returns (address proxy) {
        bytes memory deploymentData = _proxyCode(WALLET_IMPLEMENTATION);
        bytes32 salt = _calcSalt(_initializer, _salt);
        proxy = Create2.computeAddress(salt, keccak256(deploymentData));
    }

    /**
     * @notice Deposits ETH to the entry point on behalf of the contract
     */
    function deposit() public payable {
        entryPoint.depositTo{value: msg.value}(address(this));
    }

    /**
     * @notice Allows the owner to withdraw ETH from entrypoint contract
     * @param withdrawAddress Address to receive the withdrawn ETH
     * @param amount Amount of ETH to withdraw
     */
    function withdrawTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entryPoint.withdrawTo(withdrawAddress, amount);
    }

    /**
     * @notice Allows the owner to add stake to the entry point
     * @param unstakeDelaySec Duration (in seconds) after which the stake can be unlocked
     */
    function addStake(uint32 unstakeDelaySec) external payable onlyOwner {
        entryPoint.addStake{value: msg.value}(unstakeDelaySec);
    }

    /**
     * @notice Allows the owner to unlock their stake from the entry point
     */
    function unlockStake() external onlyOwner {
        entryPoint.unlockStake();
    }

    /**
     * @notice Allows the owner to withdraw their stake from the entry point
     * @param withdrawAddress Address to receive the withdrawn stake
     */
    function withdrawStake(address payable withdrawAddress) external onlyOwner {
        entryPoint.withdrawStake(withdrawAddress);
    }
}
