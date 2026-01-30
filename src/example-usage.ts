/**
 * Example Usage of StackInsure Integration
 * 
 * This file demonstrates how to use the integrated @stacks/connect
 * and @stacks/transactions libraries with StackInsure
 */

import { StackInsureIntegration } from './stackinsure-integration';
import { WalletConnectionManager, NetworkType } from './stacks-connect';
import { TransactionBuilder } from './stacks-transactions';

/**
 * Example 1: Basic Wallet Connection
 */
export async function exampleWalletConnection() {
  // Initialize wallet connection manager
  const walletManager = new WalletConnectionManager('StackInsure', NetworkType.TESTNET);

  // Connect wallet
  await walletManager.connect(
    (payload) => {
      console.log('Wallet connected:', payload);
      console.log('User address:', walletManager.getUserAddress());
    },
    () => {
      console.log('User cancelled connection');
    }
  );

  // Check authentication status
  if (walletManager.isAuthenticated()) {
    console.log('User is authenticated');
    console.log('Address:', walletManager.getUserAddress());
  }

  // Sign out
  // walletManager.signOut();
}

/**
 * Example 2: Using StackInsure Integration (UI-based transactions)
 */
export async function exampleStackInsureUI() {
  // Initialize integration
  const stackInsure = new StackInsureIntegration(NetworkType.TESTNET);

  // Connect wallet first
  await stackInsure.connectWallet(
    (data) => {
      console.log('Connected:', data);
    },
    () => {
      console.log('Connection cancelled');
    }
  );

  if (!stackInsure.isAuthenticated()) {
    console.error('User must be authenticated');
    return;
  }

  // Example: Calculate premium
  try {
    await stackInsure.calculatePremiumUI(
      BigInt(1000000), // 1 STX coverage
      'medium',        // risk category
      BigInt(365)      // 365 days
    );
  } catch (error) {
    console.error('Error calculating premium:', error);
  }

  // Example: Create a policy
  try {
    const now = BigInt(Math.floor(Date.now() / 1000));
    const oneYearLater = now + BigInt(31536000); // 1 year in seconds

    await stackInsure.createPolicyUI(
      BigInt(1000000),  // coverage amount (1 STX)
      BigInt(120000),   // premium amount (0.12 STX)
      now,              // start date
      oneYearLater,     // end date
      'medium'          // risk category
    );
  } catch (error) {
    console.error('Error creating policy:', error);
  }

  // Example: Deposit liquidity
  try {
    await stackInsure.depositLiquidityUI(
      BigInt(10000000) // 10 STX
    );
  } catch (error) {
    console.error('Error depositing liquidity:', error);
  }

  // Example: Submit a claim
  try {
    const evidenceHash = new Uint8Array(32);
    // Fill with actual evidence hash
    crypto.getRandomValues(evidenceHash);

    await stackInsure.submitClaimUI(
      BigInt(1),           // policy ID
      BigInt(500000),      // claim amount (0.5 STX)
      'Property damage occurred', // description
      evidenceHash         // evidence hash
    );
  } catch (error) {
    console.error('Error submitting claim:', error);
  }
}

/**
 * Example 3: Read-only Contract Calls
 */
export async function exampleReadOnlyCalls() {
  const stackInsure = new StackInsureIntegration(NetworkType.TESTNET);

  try {
    // Get policy information
    const policy = await stackInsure.getPolicy(BigInt(1));
    console.log('Policy:', policy);

    // Calculate premium (read-only)
    const premium = await stackInsure.calculatePremium(
      BigInt(1000000),
      'medium',
      BigInt(365)
    );
    console.log('Premium:', premium);

    // Get underwriter balance
    const address = stackInsure.getUserAddress();
    if (address) {
      const balance = await stackInsure.getUnderwriterBalance(address);
      console.log('Balance:', balance);
    }

    // Get claim information
    const claim = await stackInsure.getClaim(BigInt(1));
    console.log('Claim:', claim);
  } catch (error) {
    console.error('Error in read-only calls:', error);
  }
}

/**
 * Example 4: Programmatic Transactions (using private key)
 * 
 * WARNING: Only use this in backend/server environments.
 * Never expose private keys in frontend code!
 */
export async function exampleProgrammaticTransactions() {
  // This example shows how to use @stacks/transactions directly
  // for programmatic transactions (e.g., in a backend service)

  // const txBuilder = new TransactionBuilder(NetworkType.TESTNET);

  // Example: Call contract function programmatically
  // const senderKey = 'your-private-key-here'; // NEVER expose in frontend!
  // 
  // try {
  //   const result = await txBuilder.callContract({
  //     contractAddress: 'ST000000000000000000002AMW42H',
  //     contractName: 'policy-registry',
  //     functionName: 'create-policy',
  //     functionArgs: [
  //       ClarityValueHelpers.uint(BigInt(1000000)),
  //       ClarityValueHelpers.uint(BigInt(120000)),
  //       ClarityValueHelpers.uint(BigInt(Math.floor(Date.now() / 1000))),
  //       ClarityValueHelpers.uint(BigInt(Math.floor(Date.now() / 1000) + 31536000)),
  //       ClarityValueHelpers.stringAscii('medium'),
  //     ],
  //     senderKey,
  //   });
  //   console.log('Transaction result:', result);
  // } catch (error) {
  //   console.error('Error:', error);
  // }
}

/**
 * Example 5: Complete Workflow
 */
export async function exampleCompleteWorkflow() {
  const stackInsure = new StackInsureIntegration(NetworkType.TESTNET);

  // Step 1: Connect wallet
  console.log('Step 1: Connecting wallet...');
  await stackInsure.connectWallet(
    () => {
      console.log('✓ Wallet connected');
    },
    () => {
      console.log('✗ Connection cancelled');
      return;
    }
  );

  if (!stackInsure.isAuthenticated()) {
    console.error('User not authenticated');
    return;
  }

  // Step 2: Calculate premium
  console.log('Step 2: Calculating premium...');
  try {
    const premium = await stackInsure.calculatePremium(
      BigInt(1000000), // 1 STX
      'medium',
      BigInt(365)
    );
    console.log('✓ Premium calculated:', premium);
  } catch (error) {
    console.error('✗ Error calculating premium:', error);
  }

  // Step 3: Create policy (UI-based)
  console.log('Step 3: Creating policy...');
  try {
    const now = BigInt(Math.floor(Date.now() / 1000));
    await stackInsure.createPolicyUI(
      BigInt(1000000),
      BigInt(120000),
      now,
      now + BigInt(31536000),
      'medium'
    );
    console.log('✓ Policy creation initiated');
  } catch (error) {
    console.error('✗ Error creating policy:', error);
  }

  // Step 4: Check policy status
  console.log('Step 4: Checking policy status...');
  try {
    const policy = await stackInsure.getPolicy(BigInt(1));
    console.log('✓ Policy retrieved:', policy);
  } catch (error) {
    console.error('✗ Error retrieving policy:', error);
  }
}

// Export all examples for easy access
export const examples = {
  walletConnection: exampleWalletConnection,
  stackInsureUI: exampleStackInsureUI,
  readOnlyCalls: exampleReadOnlyCalls,
  programmaticTransactions: exampleProgrammaticTransactions,
  completeWorkflow: exampleCompleteWorkflow,
};
