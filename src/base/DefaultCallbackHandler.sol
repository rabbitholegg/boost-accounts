// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title DefaultCallbackHandler
/// @notice Default callback handler contract for handling receipt of ERC721 and ERC1155 tokens.
/// @dev This contract is used as the default callback handler for the Boost Account contract.
contract DefaultCallbackHandler is IERC721Receiver, IERC1155Receiver {
    /// @notice Receive ERC721 tokens.
    /// @param operator The address which initiated the transfer.
    /// @param from The address from which the token was transferred.
    /// @param tokenId The token ID.
    /// @param data Additional data with no specified format.
    /// @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        override
        returns (bytes4)
    {
        (operator, from, tokenId, data);
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice Receive ERC1155 tokens.
    /// @param operator The address which initiated the transfer.
    /// @param from The address from which the token was transferred.
    /// @param id The token ID.
    /// @param amount The token amount.
    /// @param data Additional data with no specified format.
    /// @return bytes4 `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    function onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes calldata data)
        external
        pure
        override
        returns (bytes4)
    {
        (operator, from, id, amount, data);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /// @notice Receive a batch of ERC1155 tokens.
    /// @param operator The address which initiated the transfer.
    /// @param from The address from which the token was transferred.
    /// @param ids An array of token IDs.
    /// @param amounts An array of token amounts.
    /// @param data Additional data with no specified format.
    /// @return bytes4 `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external pure override returns (bytes4) {
        (operator, from, ids, amounts, data);
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /// @notice Check if the contract supports an interface.
    /// @param interfaceId The interface identifier.
    /// @return bool `true` if the contract supports `interfaceId`, `false` otherwise.
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    /// @notice Fallback function to receive Ether with no data.
    receive() external payable {}

    /// @notice Fallback function to receive Ether with calldata not otherwise handled.
    fallback() external payable {}
}
