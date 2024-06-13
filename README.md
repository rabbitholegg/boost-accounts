# Boost Accounts

Boost Accounts is an extensible smart account system for EVM-based networks powered by [ERC-4337 account abstraction](https://eips.ethereum.org/EIPS/eip-4337). It was built for Boost Protocol, but it's designed to be generalized enough for other applications as well. Its unopinionated modular architecture enables a high degree of flexibility and supports a wide range of use cases, from simple multi-chain smart wallets to autonomously run treasuries. Some examples of the flexibility enabled by extensions can be found in the `src/capabilities` directory.

## Design Principles

- **ERC-4337 Compliance**: Boost Accounts is designed to be fully compliant with the ERC-4337 account abstraction spec. It's built on top of the spec's reference implementation ([eth-infinitism/account-abstraction](https://github.com/eth-infinitism/account-abstraction)) and extends it with additional features.

- **Modular Architecture**: The base account is designed to be modular and extensible. It provides a minimal implementation and allows developers to add, remove and upgrade custom functionality through **extensions**, **hooks** and **validators**. The extension system is unopinionated and doesn't enforce any specific design patterns beyond the generic calldata requirements.

- **Security**: The system takes a minimalistic approach to reduce the attack surface and provides a set of built-in security features that can be extended as needed. The base account is designed to be secure by default, and custom security checks can be added through **validators** and pre/post **hooks**.

- **Efficient**: We've taken an aggressive approach to optimizing internal logic to reduce the gas costs of using Boost Accounts. The gas costs of the base account are kept to a minimum, and the extension system adds minimal overhead. The goal is to make Boost Accounts as efficient as possible while maintaining a high degree of flexibility (and sanity).

- **Developer Experience**: Boost Accounts are designed to be developer-friendly and easy to use. The extension system is simple and intuitive, and the base account provides a clean and consistent API. The goal is to make it easy for developers to build complex applications on top of Boost Accounts without getting stuck in the weeds.

## Project Structure

- **`src/`**: Contains all the Solidity contracts for Boost Accounts, including the base account, extensions, hooks, validators, and some examples.
  - **`base/`**: Contains the abstract bases used in account implementation and some standard extensions, hooks, and validators.
  - **`capabilities/`**: Contains various capabilities that can be added to the base account, including the ability to install/uninstall custom extensions, hooks and validators, manage ownership, delegate unhandled calls, and more.
  - **`core/`**: Contains the core logic for various aspects of the account system, including authorization, extensions, validation, and hooks.
  - **`extensions/`**: Contains various extensions for the base account, including social recovery, upgradeability, and an abstract base for building new extensions.
  - **`factory/`**: Contains the account factory contract that can be used to deploy new accounts with custom extensions, hooks, and validators. Note that it is not necessary to use the factory to deploy accounts; it's just a convenience feature.
  - **`hooks/`**: Contains various hooks for the base account, including a simple two-factor authentication hook (sort of like multisig, but without necessarily giving that signer any ownership or control), and an abstract base for building new hooks.
  - **`installers/`**: Contains the abstract installers for extensions, hooks, and validators.
  - **`interfaces/`**: Contains the interfaces for the base account, extensions, hooks, validators, and installers.
  - **`paymaster/`**: Contains paymasters that can be used to pay for gas for userOps. It includes a simple ERC20 token paymaster, a more robustly permissioned "limiting" paymaster (based on Base's implementation), and an abstract base for building new paymasters.
  - **`utils/`**: Contains utility functions used throughout the project.
  - **`validators/`**: Contains various validators for the base account, including a simple EOA signature-based validator, a more complex ACL-enabled validator that supports FIDO/WebAuthn with capacity for other advanced authentication methods, and an abstract base for building new validators.
  - **`BaseAccount.sol`**: The main contract that implements the base account logic.
