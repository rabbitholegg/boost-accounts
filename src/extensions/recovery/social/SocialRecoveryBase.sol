// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ISocialRecovery.sol";
import "../../../interfaces/IMultiOwnerManager.sol";

/**
 * @title SocialRecoveryBase
 * @dev This abstract contract provides the base implementation for the social recovery functionality.
 * It implements the ISocialRecovery interface and extends the EIP712 contract.
 * It allows a user to designate a list of keepers for their wallet and establish a recovery threshold.
 * If a wallet is lost or compromised, the keepers can initiate a recovery process by signing a special EIP712 signature.
 * However, this recovery process is subject to a user-defined time lock period, and can only execute the recovery after this period has passed.
 * This mechanism ensures that the user's assets remain secure and recoverable, even in unforeseen circumstances.
 */
abstract contract SocialRecoveryBase is ISocialRecovery, EIP712 {
    using ECDSA for bytes32;

    event KeeperSet(address wallet, bytes32 newKeeperHash);
    event DelayPeriodSet(address wallet, uint256 newDelay);
    event RecoveryCancelled(address wallet, bytes32 recoveryId);
    event RecoveryScheduled(address wallet, bytes32 recoveryId, uint256 operationValidTime);
    event RecoveryExecuted(address wallet, bytes32 recoveryId);
    event ApproveHash(address indexed keeper, bytes32 hash);
    event RejectHash(address indexed keeper, bytes32 hash);

    error InvalidUserOpState(address wallet, bytes32 recoveryId, bytes32 expectedStates);
    error HashPreviouslyApproved();
    error InvalidKeeperSignature();
    error InvalidKeeperThreshold();
    error InvalidKeeperSignatureLength();
    error HashPreviouslyRejected();

    mapping(address => SocialRecoveryInfo) socialRecoveryInfo;
    mapping(bytes32 => uint256) public approvedHashes;
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    bytes32 private constant _TYPE_HASH_SOCIAL_RECOVERY =
        keccak256("SocialRecovery(address wallet,uint256 nonce,bytes32[] newOwners)");

    function walletNonce(address wallet) public view override returns (uint256 _nonce) {
        return socialRecoveryInfo[wallet].nonce;
    }

    /**
     * @notice Returns the social recovery information for a given wallet.
     */
    function getSocialRecoveryInfo(address wallet)
        public
        view
        returns (bytes32 keeperHash, uint256 nonce, uint256 delayPeriod)
    {
        return (
            socialRecoveryInfo[wallet].keeperHash,
            socialRecoveryInfo[wallet].nonce,
            socialRecoveryInfo[wallet].delayPeriod
        );
    }

    function getOperationState(address wallet, bytes32 id) public view returns (OperationState) {
        uint256 timestamp = getOperationValidTime(wallet, id);
        if (timestamp == 0) {
            return OperationState.Unset;
        } else if (timestamp == _DONE_TIMESTAMP) {
            return OperationState.Done;
        } else if (timestamp > block.timestamp) {
            return OperationState.Waiting;
        } else {
            return OperationState.Ready;
        }
    }

    /**
     * @dev Returns whether an operation is pending or not. Note that a "pending" operation may also be "ready".
     */
    function isOperationPending(address wallet, bytes32 id) public view returns (bool) {
        OperationState state = getOperationState(wallet, id);
        return state == OperationState.Waiting || state == OperationState.Ready;
    }

    /**
     * @dev Returns whether an operation is ready for execution. Note that a "ready" operation is also "pending".
     */
    function isOperationReady(address wallet, bytes32 id) public view returns (bool) {
        return getOperationState(wallet, id) == OperationState.Ready;
    }

    /**
     * @dev Returns whether an id corresponds to a registered operation. This
     * includes both Waiting, Ready, and Done operations.
     */
    function isOperationSet(address wallet, bytes32 id) public view returns (bool) {
        return getOperationState(wallet, id) != OperationState.Unset;
    }

    function getOperationValidTime(address wallet, bytes32 id) public view returns (uint256) {
        return socialRecoveryInfo[wallet].operationValidAt[id];
    }

    /**
     * @notice modify the keeper hash for a wallet
     * @dev Emits a KeeperSet event
     * @param newKeeperHash The new keeper hash
     */
    function setKeeper(bytes32 newKeeperHash) external {
        address wallet = _msgSender();
        socialRecoveryInfo[wallet].keeperHash = newKeeperHash;
        _increaseNonce(wallet);
        emit KeeperSet(wallet, newKeeperHash);
    }

    /**
     * @notice Sets the recovery time lock period for a wallet
     * @dev Emits a DelayPeriodSet event
     * @param newDelay The new delay period
     */
    function setDelayPeriod(uint256 newDelay) external {
        address wallet = _msgSender();
        socialRecoveryInfo[wallet].delayPeriod = newDelay;
        _increaseNonce(wallet);
        emit DelayPeriodSet(wallet, newDelay);
    }

    function cancelAllRecovery() external {
        address wallet = _msgSender();
        _increaseNonce(wallet);
        emit RecoveryCancelled(wallet, 0);
    }

    /**
     * @notice Approves a hash for the sender
     * the hash is the eip712 hash of the recover operation for keeper to sign
     * @dev Considering that not all contracts are EIP-1271 compatible, this function could be called by the keeper if the keeper is a smart contract.
     * It emits an ApproveHash event.
     * @param hash The hash to be approved
     */
    function approveHash(bytes32 hash) external {
        bytes32 key = _approveKey(msg.sender, hash);
        if (approvedHashes[key] == 1) {
            revert HashPreviouslyApproved();
        }
        approvedHashes[key] = 1;
        emit ApproveHash(msg.sender, hash);
    }
    /**
     *
     * @notice Rejects a hash for the sender
     * the hash is the eip712 hash of the recover operation for keeper to sign
     * @dev Considering that not all contracts are EIP-1271 compatible, this function could be called by the keeper if the keeper is a smart contract.
     * It emits a RejectHash event.
     * @param hash The hash to be rejected
     */

    function rejectHash(bytes32 hash) external {
        bytes32 key = _approveKey(msg.sender, hash);
        if (approvedHashes[key] == 0) {
            revert HashPreviouslyRejected();
        }
        approvedHashes[key] = 0;
        emit RejectHash(msg.sender, hash);
    }

    /**
     * @notice Schedules a recovery operation for a wallet
     * @param wallet The address of the wallet
     * @param newOwners The new owners to be set for the wallet
     * @param rawKeeper The raw keeper data
     * @param keeperSignature The signature of the keeper
     * @return recoveryId The ID of the recovery operation
     */
    function scheduleRecovery(
        address wallet,
        bytes32[] calldata newOwners,
        bytes calldata rawKeeper,
        bytes calldata keeperSignature
    ) external override returns (bytes32 recoveryId) {
        recoveryId = hashOperation(wallet, walletNonce(wallet), abi.encode(newOwners));
        if (isOperationSet(wallet, recoveryId)) {
            revert InvalidUserOpState(wallet, recoveryId, _encodeStateBitmap(OperationState.Unset));
        }
        bytes32 keeperHash = _getKeeperHash(rawKeeper);
        _checkKeeperHash(wallet, keeperHash);
        _verifyKeeperSignature(wallet, walletNonce(wallet), newOwners, rawKeeper, keeperSignature);
        uint256 scheduleTime = _setTimeStamp(wallet, recoveryId);
        emit RecoveryScheduled(wallet, recoveryId, scheduleTime);
    }

    /**
     * @notice Executes a recovery operation for a wallet
     * @param wallet The address of the wallet
     * @param newOwners The new owners to be set for the wallet
     */
    function executeRecovery(address wallet, bytes32[] calldata newOwners) external override {
        bytes32 recoveryId = hashOperation(wallet, walletNonce(wallet), abi.encode(newOwners));
        if (!isOperationReady(wallet, recoveryId)) {
            revert InvalidUserOpState(wallet, recoveryId, _encodeStateBitmap(OperationState.Ready));
        }
        _setRecoveryDone(wallet, recoveryId);
        _increaseNonce(wallet);
        _recoveryOwner(wallet, newOwners);
        emit RecoveryExecuted(wallet, recoveryId);
    }

    function _setRecoveryDone(address wallet, bytes32 recoveryId) internal {
        socialRecoveryInfo[wallet].operationValidAt[recoveryId] = _DONE_TIMESTAMP;
    }

    function _recoveryOwner(address wallet, bytes32[] memory newOwners) internal {
        IMultiOwnerManager(payable(wallet)).resetOwners(newOwners);
    }

    /**
     * @notice Verifies the keeper's signature
     * @dev This function checks the signature type and verifies it accordingly. It supports EIP-1271 signatures for smart contract wallet, approved hashes, and EOA signatures.
     */
    function _verifyKeeperSignature(
        address wallet,
        uint256 nonce,
        bytes32[] calldata newOwners,
        bytes calldata rawKeeper,
        bytes calldata keeperSignature
    ) internal view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(_TYPE_HASH_SOCIAL_RECOVERY, wallet, nonce, keccak256(abi.encodePacked(newOwners))))
        );
        KeeperData memory keeperData = _parseKeeperData(rawKeeper);
        uint256 keepersLen = keeperData.keepers.length;

        if (keeperData.threshold == 0) {
            revert InvalidKeeperThreshold();
        }
        if (keepersLen == 0) {
            revert InvalidKeeperSignatureLength();
        }

        // for extreme cases
        if (keeperData.threshold > keepersLen) keeperData.threshold = keepersLen;

        /*
        keySignature structure:
        ┌──────────────┬──────────────┬──────────────┬──────────────┐
        │              │              │              │              │
        │   signature1 │   signature2 │      ...     │   signatureN │
        │              │              │              │              │
        └──────────────┴──────────────┴──────────────┴──────────────┘

        one signature structure:
        ┌──────────┬──────────────┬──────────┬────────────────┐
        │          │              │          │                │
        │    v     │       s      │   r      │  dynamic data  │
        │  bytes1  │bytes4|bytes32│  bytes32 │     dynamic    │
        │  (must)  │  (optional)  │(optional)│   (optional)   │
        └──────────┴──────────────┴──────────┴────────────────┘

        data logic description:
            v = 0
                EIP-1271 signature
                s: bytes4 Length of signature data
                r: no set
                dynamic data: signature data

            v = 1
                approved hash
                r: no set
                s: no set

            v = 2
                skip
                s: bytes4 skip times
                r: no set

            v > 2
                EOA signature
                r: bytes32
                s: bytes32

        ==============================================================
        Note: Why is the definition of 's' unstable (bytes4|bytes32)?
              If 's' is defined as bytes32, it incurs lower read costs( shr(224, calldataload() -> calldataload() ). However, to prevent arithmetic overflow, all calculations involving 's' need to be protected against overflow, which leads to higher overhead.
              If, in certain cases, 's' is defined as bytes4 (up to 4GB), there is no need to perform overflow prevention under the current known block gas limit.
              Overall, it is more suitable for both Layer1 and Layer2.
     */
        uint8 v;
        uint256 cursor = 0;

        uint256 skipCount = 0;
        uint256 keeperSignatureLen = keeperSignature.length;
        for (uint256 i = 0; i < keepersLen;) {
            if (cursor >= keeperSignatureLen) break;
            bytes calldata signatures = keeperSignature[cursor:];
            assembly ("memory-safe") {
                v := byte(0, calldataload(signatures.offset))
            }

            if (v == 0) {
                /*
                v = 0
                    EIP-1271 signature
                    s: bytes4 Length of signature data
                    r: no set
                    dynamic data: signature data
             */
                uint256 cursorEnd;
                assembly ("memory-safe") {
                    // read 's' as bytes4
                    let sigLen := shr(224, calldataload(add(signatures.offset, 1)))

                    cursorEnd := add(5, sigLen) // see Note line 282
                    cursor := add(cursor, cursorEnd)
                }

                bytes calldata dynamicData = signatures[5:cursorEnd];
                {
                    (bool success, bytes memory result) = keeperData.keepers[i].staticcall(
                        abi.encodeWithSelector(IERC1271.isValidSignature.selector, digest, dynamicData)
                    );
                    require(
                        success && result.length == 32
                            && abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector),
                        "contract signature invalid"
                    );
                }
            } else if (v == 1) {
                /*
                v = 1
                    approved hash
                    r: no set
                    s: no set
             */
                bytes32 key = _approveKey(keeperData.keepers[i], digest);
                require(approvedHashes[key] == 1, "hash not approved");
                cursor += 1; // see Note line 282
            } else if (v == 2) {
                /*
                v = 2
                    skip
                    s: bytes4 skip times
                    r: no set
             */
                assembly ("memory-safe") {
                    // read 's' as bytes4
                    let skipTimes := shr(224, calldataload(add(signatures.offset, 1)))

                    i := add(i, skipTimes) // see Note line 282
                    skipCount := add(skipCount, add(skipTimes, 1))
                    cursor := add(cursor, 5)
                }
            } else {
                /*
                v > 2
                    EOA signature
             */
                bytes32 s;
                bytes32 r;
                assembly ("memory-safe") {
                    s := calldataload(add(signatures.offset, 1))
                    r := calldataload(add(signatures.offset, 33))

                    cursor := add(cursor, 65) // see Note line 282
                }
                require(keeperData.keepers[i] == ECDSA.recover(digest, v, r, s), "keeper signature invalid");
            }
            i++; // see Note line 282
        }
        if (keepersLen - skipCount < keeperData.threshold) {
            revert InvalidKeeperSignature();
        }
    }

    function _approveKey(address sender, bytes32 hash) private pure returns (bytes32 key) {
        key = keccak256(abi.encode(sender, hash));
    }

    function _checkKeeperHash(address wallet, bytes32 keeperHash) internal view {
        if (socialRecoveryInfo[wallet].keeperHash != keeperHash) {
            revert("Invalid keeper hash");
        }
    }
    /**
     * @notice This function is executed during extension uninstallation.
     * @dev Even during uninstallation, the nonce data is not cleared to prevent replay of historical data once reinstall this moudule agian.
     * The nonce is permanently incrementing. Other variables can be reset.
     * @param wallet The address of the wallet for which the social recovery info is to be cleared.
     */

    function _clearWalletSocialRecoveryInfo(address wallet) internal {
        _increaseNonce(wallet);
        socialRecoveryInfo[wallet].keeperHash = bytes32(0);
        socialRecoveryInfo[wallet].delayPeriod = 0;
    }

    function _getKeeperHash(bytes calldata rawKeeper) internal pure returns (bytes32 keeperHash) {
        return keccak256(rawKeeper);
    }

    function _setTimeStamp(address wallet, bytes32 id) internal returns (uint256) {
        uint256 scheduleTime = block.timestamp + socialRecoveryInfo[wallet].delayPeriod;
        socialRecoveryInfo[wallet].operationValidAt[id] = scheduleTime;
        return scheduleTime;
    }

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _increaseNonce(address wallet) internal {
        uint256 _newNonce = walletNonce(wallet) + 1;
        socialRecoveryInfo[wallet].nonce = _newNonce;
    }

    function _setKeeperHash(address wallet, bytes32 keeperHash) internal {
        socialRecoveryInfo[wallet].keeperHash = keeperHash;
    }

    function _setDelayPeriod(address wallet, uint256 delayPeriod) internal {
        socialRecoveryInfo[wallet].delayPeriod = delayPeriod;
    }

    /**
     * @param   wallet  the address to recover
     * @param   nonce  Add a nonce for the hash operation. When recovery is cancelled or the keeper is modified, the nonce can automatically invalidate the previous operation
     * @return  bytes32  return recoveryId
     */
    function hashOperation(address wallet, uint256 nonce, bytes memory data) internal view virtual returns (bytes32) {
        return keccak256(abi.encode(wallet, nonce, data, address(this), block.chainid));
    }

    function _encodeStateBitmap(OperationState operationState) internal pure returns (bytes32) {
        return bytes32(1 << uint8(operationState));
    }

    function _parseKeeperData(bytes calldata rawKeeper) internal pure returns (KeeperData memory) {
        (address[] memory keepers, uint256 threshold, uint256 salt) =
            abi.decode(rawKeeper, (address[], uint256, uint256));
        return KeeperData({keepers: keepers, threshold: threshold, salt: salt});
    }
}
