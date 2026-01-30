/**
 * Stacks Transactions Integration
 * 
 * This module provides utilities for building and broadcasting
 * transactions using @stacks/transactions
 */

import {
  AnchorMode,
  PostConditionMode,
  broadcastTransaction,
  makeContractCall,
  makeContractDeploy,
  makeSTXTokenTransfer,
  createAddress,
  getAddressFromPrivateKey,
  TransactionVersion,
  ClarityValue,
  uintCV,
  intCV,
  boolCV,
  bufferCV,
  stringAsciiCV,
  stringUtf8CV,
  listCV,
  tupleCV,
  standardPrincipalCV,
  contractPrincipalCV,
  responseOkCV,
  responseErrorCV,
  someCV,
  noneCV,
  cvToJSON,
  cvToValue,
} from '@stacks/transactions';
import {
  fetchReadOnlyFunctionCall,
} from '@stacks/transactions';
import {
  StacksMainnet,
  StacksTestnet,
  StacksNetwork,
  StacksDevnet,
} from '@stacks/network';
import { NetworkType, getNetwork } from './stacks-connect';

/**
 * Transaction options
 */
export interface TransactionOptions {
  network?: StacksNetwork;
  anchorMode?: AnchorMode;
  postConditionMode?: PostConditionMode;
  fee?: bigint;
  nonce?: number;
  memo?: string;
  sponsored?: boolean;
}

/**
 * Contract call parameters
 */
export interface ContractCallParams {
  contractAddress: string;
  contractName: string;
  functionName: string;
  functionArgs: ClarityValue[];
  senderKey: string;
  options?: TransactionOptions;
}

/**
 * Contract deploy parameters
 */
export interface ContractDeployParams {
  contractName: string;
  codeBody: string;
  senderKey: string;
  options?: TransactionOptions;
}

/**
 * STX transfer parameters
 */
export interface STXTransferParams {
  recipient: string;
  amount: bigint;
  senderKey: string;
  options?: TransactionOptions;
}

/**
 * Read-only function call parameters
 */
export interface ReadOnlyCallParams {
  contractAddress: string;
  contractName: string;
  functionName: string;
  functionArgs: ClarityValue[];
  network?: StacksNetwork;
  senderAddress?: string;
}

/**
 * Build contract call transaction
 */
export async function buildContractCall(
  params: ContractCallParams
): Promise<any> {
  const {
    contractAddress,
    contractName,
    functionName,
    functionArgs,
    senderKey,
    options = {},
  } = params;

  const network = options.network || getNetwork(NetworkType.TESTNET);
  const senderAddress = getAddressFromPrivateKey(senderKey, TransactionVersion.Testnet);

  // Get nonce if not provided
  let nonce = options.nonce;
  if (nonce === undefined) {
    nonce = await getNonce(senderAddress, network);
  }

  const txOptions = {
    contractAddress,
    contractName,
    functionName,
    functionArgs,
    senderKey,
    network,
    anchorMode: options.anchorMode || AnchorMode.Any,
    postConditionMode: options.postConditionMode || PostConditionMode.Deny,
    fee: options.fee,
    nonce,
    memo: options.memo,
    sponsored: options.sponsored || false,
  };

  return await makeContractCall(txOptions);
}

/**
 * Build contract deploy transaction
 */
export async function buildContractDeploy(
  params: ContractDeployParams
): Promise<any> {
  const {
    contractName,
    codeBody,
    senderKey,
    options = {},
  } = params;

  const network = options.network || getNetwork(NetworkType.TESTNET);
  const senderAddress = getAddressFromPrivateKey(senderKey, TransactionVersion.Testnet);

  // Get nonce if not provided
  let nonce = options.nonce;
  if (nonce === undefined) {
    nonce = await getNonce(senderAddress, network);
  }

  const txOptions = {
    contractName,
    codeBody,
    senderKey,
    network,
    anchorMode: options.anchorMode || AnchorMode.Any,
    postConditionMode: options.postConditionMode || PostConditionMode.Deny,
    fee: options.fee,
    nonce,
    sponsored: options.sponsored || false,
  };

  return await makeContractDeploy(txOptions);
}

/**
 * Build STX transfer transaction
 */
export async function buildSTXTransfer(
  params: STXTransferParams
): Promise<any> {
  const {
    recipient,
    amount,
    senderKey,
    options = {},
  } = params;

  const network = options.network || getNetwork(NetworkType.TESTNET);
  const senderAddress = getAddressFromPrivateKey(senderKey, TransactionVersion.Testnet);

  // Get nonce if not provided
  let nonce = options.nonce;
  if (nonce === undefined) {
    nonce = await getNonce(senderAddress, network);
  }

  const txOptions = {
    recipient,
    amount,
    senderKey,
    network,
    anchorMode: options.anchorMode || AnchorMode.Any,
    postConditionMode: options.postConditionMode || PostConditionMode.Deny,
    fee: options.fee,
    nonce,
    memo: options.memo,
    sponsored: options.sponsored || false,
  };

  return await makeSTXTokenTransfer(txOptions);
}

/**
 * Broadcast transaction
 */
export async function broadcastTx(
  transaction: any,
  network?: StacksNetwork
): Promise<any> {
  const stacksNetwork = network || getNetwork(NetworkType.TESTNET);
  return await broadcastTransaction(transaction, stacksNetwork);
}

/**
 * Call read-only function
 */
export async function callReadOnly(
  params: ReadOnlyCallParams
): Promise<ClarityValue> {
  const {
    contractAddress,
    contractName,
    functionName,
    functionArgs,
    network,
    senderAddress,
  } = params;

  const stacksNetwork = network || getNetwork(NetworkType.TESTNET);
  const sender = senderAddress || createAddress(contractAddress);

  return await callReadOnlyFunction({
    contractAddress,
    contractName,
    functionName,
    functionArgs,
    network: stacksNetwork,
    senderAddress: sender,
  });
}

/**
 * Estimate transaction fee
 */
export async function estimateFee(
  transaction: any,
  network?: StacksNetwork
): Promise<bigint> {
  const stacksNetwork = network || getNetwork(NetworkType.TESTNET);
  
  if (transaction.payloadType === 0) {
    // STX transfer
    return await estimateTransfer(transaction, stacksNetwork);
  } else if (transaction.payloadType === 1) {
    // Contract call
    return await estimateContractFunctionCall(transaction, stacksNetwork);
  } else if (transaction.payloadType === 2) {
    // Contract deploy
    return await estimateContractDeploy(transaction, stacksNetwork);
  }
  
  throw new Error('Unsupported transaction type for fee estimation');
}

/**
 * Convert Clarity value to JSON
 */
export function clarityValueToJSON(value: ClarityValue): any {
  return cvToJSON(value);
}

/**
 * Convert Clarity value to JavaScript value
 */
export function clarityValueToJS(value: ClarityValue): any {
  return cvToValue(value);
}

/**
 * Transaction builder utility class
 */
export class TransactionBuilder {
  private network: StacksNetwork;
  private defaultOptions: TransactionOptions;

  constructor(networkType: NetworkType = NetworkType.TESTNET) {
    this.network = getNetwork(networkType);
    this.defaultOptions = {
      network: this.network,
      anchorMode: AnchorMode.Any,
      postConditionMode: PostConditionMode.Deny,
    };
  }

  /**
   * Set default network
   */
  setNetwork(networkType: NetworkType): void {
    this.network = getNetwork(networkType);
    this.defaultOptions.network = this.network;
  }

  /**
   * Build and broadcast contract call
   */
  async callContract(
    params: Omit<ContractCallParams, 'options'>,
    options?: TransactionOptions
  ): Promise<any> {
    const transaction = await buildContractCall({
      ...params,
      options: { ...this.defaultOptions, ...options },
    });
    return await broadcastTx(transaction, this.network);
  }

  /**
   * Build and broadcast contract deploy
   */
  async deployContract(
    params: Omit<ContractDeployParams, 'options'>,
    options?: TransactionOptions
  ): Promise<any> {
    const transaction = await buildContractDeploy({
      ...params,
      options: { ...this.defaultOptions, ...options },
    });
    return await broadcastTx(transaction, this.network);
  }

  /**
   * Build and broadcast STX transfer
   */
  async transferSTX(
    params: Omit<STXTransferParams, 'options'>,
    options?: TransactionOptions
  ): Promise<any> {
    const transaction = await buildSTXTransfer({
      ...params,
      options: { ...this.defaultOptions, ...options },
    });
    return await broadcastTx(transaction, this.network);
  }

  /**
   * Call read-only function
   */
  async readOnlyCall(
    params: ReadOnlyCallParams
  ): Promise<ClarityValue> {
    return await callReadOnly({
      ...params,
      network: this.network,
    });
  }
}

/**
 * Helper functions for creating Clarity values
 */
export const ClarityValueHelpers = {
  uint: uintCV,
  int: intCV,
  bool: boolCV,
  buffer: bufferCV,
  stringAscii: stringAsciiCV,
  stringUtf8: stringUtf8CV,
  list: listCV,
  tuple: tupleCV,
  principal: standardPrincipalCV,
  contractPrincipal: contractPrincipalCV,
  responseOk: responseOkCV,
  responseError: responseErrorCV,
  some: someCV,
  none: noneCV,
};
