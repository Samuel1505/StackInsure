/**
 * StackInsure Integration Library
 * 
 * Main entry point for StackInsure integration with @stacks/connect and @stacks/transactions
 */

// Export Stacks Connect utilities
export {
  WalletConnectionManager,
  NetworkType,
  createAppConfig,
  connectWallet,
  getUserSession,
  isAuthenticated,
  getUserAddress,
  signOut,
  getProvider,
  getNetwork,
} from './stacks-connect';

// Export Stacks Transactions utilities
export {
  TransactionBuilder,
  ClarityValueHelpers,
  buildContractCall,
  buildContractDeploy,
  buildSTXTransfer,
  broadcastTx,
  callReadOnly,
  estimateFee,
  clarityValueToJSON,
  clarityValueToJS,
  type TransactionOptions,
  type ContractCallParams,
  type ContractDeployParams,
  type STXTransferParams,
  type ReadOnlyCallParams,
} from './stacks-transactions';

// Export StackInsure integration
export {
  StackInsureIntegration,
  STACKINSURE_CONTRACTS,
} from './stackinsure-integration';

// Export example usage
export * from './example-usage';
