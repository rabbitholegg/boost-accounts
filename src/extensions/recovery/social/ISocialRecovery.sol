// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

interface ISocialRecovery {
    struct SocialRecoveryInfo {
        bytes32 keeperHash;
        uint256 nonce;
        mapping(bytes32 id => uint256 validAt) operationValidAt;
        uint256 delayPeriod;
    }

    function walletNonce(address wallet) external view returns (uint256 _nonce);

    /**
     * @notice  Start the recovery process
     * @param   wallet to recover
     * @param   newOwners (encoded as bytes32[])
     * @param   rawKeeper abi.encode(KeeperData)
     *  struct KeeperData {
     *     address[] keepers;
     *     uint256 threshold;
     *     uint256 salt;
     * }
     * @param   keeperSignature  .
     * @return  recoveryId  .
     */
    function scheduleRecovery(
        address wallet,
        bytes32[] calldata newOwners,
        bytes calldata rawKeeper,
        bytes calldata keeperSignature
    ) external returns (bytes32 recoveryId);

    function executeRecovery(address wallet, bytes32[] calldata newOwners) external;

    function setKeeper(bytes32 newKeeperHash) external;
    function setDelayPeriod(uint256 newDelay) external;

    enum OperationState {
        Unset,
        Waiting,
        Ready,
        Done
    }

    struct KeeperData {
        address[] keepers;
        uint256 threshold;
        uint256 salt;
    }
}
