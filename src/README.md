# StackInsure Integration Library

This directory contains the integration code for using `@stacks/connect` and `@stacks/transactions` with the StackInsure smart contracts.

## Overview

The integration library provides:

1. **Wallet Connection** (`stacks-connect.ts`): Utilities for connecting to Stacks wallets and handling user authentication
2. **Transaction Building** (`stacks-transactions.ts`): Utilities for building and broadcasting transactions
3. **StackInsure Integration** (`stackinsure-integration.ts`): High-level API for interacting with StackInsure contracts
4. **Examples** (`example-usage.ts`): Usage examples demonstrating how to use the library

## Installation

The required packages are already installed:

```bash
npm install @stacks/connect @stacks/transactions
```

## Quick Start

### 1. Basic Wallet Connection

```typescript
import { WalletConnectionManager, NetworkType } from './src';

const walletManager = new WalletConnectionManager('StackInsure', NetworkType.TESTNET);

// Connect wallet
await walletManager.connect(
  (payload) => {
    console.log('Connected:', payload);
    console.log('Address:', walletManager.getUserAddress());
  },
  () => {
    console.log('Connection cancelled');
  }
);
```

### 2. Using StackInsure Integration

```typescript
import { StackInsureIntegration, NetworkType } from './src';

const stackInsure = new StackInsureIntegration(NetworkType.TESTNET);

// Connect wallet
await stackInsure.connectWallet();

// Calculate premium (read-only)
const premium = await stackInsure.calculatePremium(
  BigInt(1000000), // 1 STX
  'medium',        // risk category
  BigInt(365)      // 365 days
);

// Create policy (UI-based transaction)
await stackInsure.createPolicyUI(
  BigInt(1000000),  // coverage
  BigInt(120000),   // premium
  BigInt(Date.now() / 1000), // start date
  BigInt(Date.now() / 1000 + 31536000), // end date
  'medium'          // risk category
);
```

### 3. Read-Only Contract Calls

```typescript
// Get policy information
const policy = await stackInsure.getPolicy(BigInt(1));

// Get underwriter balance
const balance = await stackInsure.getUnderwriterBalance(address);

// Get claim information
const claim = await stackInsure.getClaim(BigInt(1));
```

## API Reference

### WalletConnectionManager

Manages wallet connections and user authentication.

**Methods:**
- `connect(onFinish?, onCancel?)`: Connect to Stacks wallet
- `isAuthenticated()`: Check if user is authenticated
- `getUserAddress()`: Get authenticated user's address
- `signOut()`: Sign out user
- `getSession()`: Get user session
- `getAppConfig()`: Get app configuration

### TransactionBuilder

Builds and broadcasts transactions programmatically.

**Methods:**
- `callContract(params, options?)`: Call contract function
- `deployContract(params, options?)`: Deploy contract
- `transferSTX(params, options?)`: Transfer STX
- `readOnlyCall(params)`: Call read-only function
- `setNetwork(networkType)`: Set network

### StackInsureIntegration

High-level API for StackInsure contract interactions.

**UI-Based Transactions (require wallet connection):**
- `calculatePremiumUI(coverageAmount, riskCategory, durationDays)`
- `createPolicyUI(coverageAmount, premiumAmount, startDate, endDate, riskCategory)`
- `depositLiquidityUI(amount)`
- `submitClaimUI(policyId, claimAmount, description, evidenceHash)`

**Read-Only Functions:**
- `getPolicy(policyId)`: Get policy information
- `calculatePremium(coverageAmount, riskCategory, durationDays)`: Calculate premium
- `getUnderwriterBalance(address)`: Get underwriter balance
- `getClaim(claimId)`: Get claim information

**Wallet Management:**
- `connectWallet(onFinish?, onCancel?)`: Connect wallet
- `isAuthenticated()`: Check authentication
- `getUserAddress()`: Get user address
- `signOut()`: Sign out

## Network Configuration

The library supports three networks:

```typescript
import { NetworkType } from './src';

NetworkType.MAINNET  // Stacks Mainnet
NetworkType.TESTNET  // Stacks Testnet
NetworkType.DEVNET   // Local development
```

## Contract Addresses

After deploying your contracts, update the contract addresses in `stackinsure-integration.ts`:

```typescript
export const STACKINSURE_CONTRACTS = {
  MAINNET: {
    POLICY_REGISTRY: 'SP...policy-registry',
    // ... other contracts
  },
  TESTNET: {
    POLICY_REGISTRY: 'ST...policy-registry',
    // ... other contracts
  },
};
```

Or pass the base contract address when initializing:

```typescript
const stackInsure = new StackInsureIntegration(
  NetworkType.TESTNET,
  'ST000000000000000000002AMW42H'
);
```

## Examples

See `example-usage.ts` for complete examples including:

- Basic wallet connection
- UI-based transactions
- Read-only contract calls
- Programmatic transactions (backend only)
- Complete workflow examples

## Security Notes

⚠️ **Important Security Considerations:**

1. **Never expose private keys** in frontend code
2. **Use UI-based transactions** (`openContractCall`, etc.) in frontend applications
3. **Programmatic transactions** (using private keys) should only be used in backend/server environments
4. **Always validate** user inputs before creating transactions
5. **Test thoroughly** on testnet before mainnet deployment

## TypeScript Support

The library is fully typed with TypeScript. All types are exported and can be imported:

```typescript
import type {
  TransactionOptions,
  ContractCallParams,
  ContractDeployParams,
  STXTransferParams,
  ReadOnlyCallParams,
} from './src';
```

## Error Handling

Always wrap transaction calls in try-catch blocks:

```typescript
try {
  await stackInsure.createPolicyUI(...);
} catch (error) {
  console.error('Transaction failed:', error);
  // Handle error appropriately
}
```

## Browser Compatibility

The library requires:
- Modern browser with ES6+ support
- Stacks wallet extension (Hiro Wallet, Xverse, etc.) for UI-based transactions

## Additional Resources

- [Stacks Connect Documentation](https://github.com/hirosystems/connect)
- [Stacks Transactions Documentation](https://github.com/hirosystems/stacks.js/tree/main/packages/transactions)
- [Stacks Documentation](https://docs.stacks.co)
