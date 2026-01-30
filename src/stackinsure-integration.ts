/**
 * StackInsure Integration Example
 * 
 * This module demonstrates how to integrate @stacks/connect and @stacks/transactions
 * to interact with StackInsure smart contracts
 */

import {
  WalletConnectionManager,
  NetworkType,
} from './stacks-connect';
import {
  TransactionBuilder,
  callReadOnly,
} from './stacks-transactions';
import {
  openContractCall,
} from '@stacks/connect';
import {
  AnchorMode,
  PostConditionMode,
  standardPrincipalCV,
  uintCV,
  stringAsciiCV,
  bufferCV,
} from '@stacks/transactions';

/**
 * StackInsure contract addresses (update these after deployment)
 */
export const STACKINSURE_CONTRACTS = {
  MAINNET: {
    POLICY_REGISTRY: 'SP000000000000000000002Q6VF78.policy-registry',
    PREMIUM_CALCULATOR: 'SP000000000000000000002Q6VF78.premium-calculator',
    LIQUIDITY_POOL: 'SP000000000000000000002Q6VF78.liquidity-pool',
    CLAIMS_PROCESSING: 'SP000000000000000000002Q6VF78.claims-processing',
    VOTING: 'SP000000000000000000002Q6VF78.voting',
    ORACLE_INTEGRATION: 'SP000000000000000000002Q6VF78.oracle-integration',
    STAKING: 'SP000000000000000000002Q6VF78.staking',
  },
  TESTNET: {
    POLICY_REGISTRY: 'ST000000000000000000002AMW42H.policy-registry',
    PREMIUM_CALCULATOR: 'ST000000000000000000002AMW42H.premium-calculator',
    LIQUIDITY_POOL: 'ST000000000000000000002AMW42H.liquidity-pool',
    CLAIMS_PROCESSING: 'ST000000000000000000002AMW42H.claims-processing',
    VOTING: 'ST000000000000000000002AMW42H.voting',
    ORACLE_INTEGRATION: 'ST000000000000000000002AMW42H.oracle-integration',
    STAKING: 'ST000000000000000000002AMW42H.staking',
  },
};

/**
 * StackInsure Integration Class
 * Combines wallet connection and transaction building
 */
export class StackInsureIntegration {
  private walletManager: WalletConnectionManager;
  private txBuilder: TransactionBuilder;
  private contracts: typeof STACKINSURE_CONTRACTS.TESTNET;

  constructor(
    networkType: NetworkType = NetworkType.TESTNET,
    contractAddress?: string
  ) {
    this.walletManager = new WalletConnectionManager('StackInsure', networkType);
    this.txBuilder = new TransactionBuilder(networkType);
    
    // Use provided contract address or default
    if (contractAddress) {
      this.contracts = this.createContractAddresses(contractAddress);
    } else {
      this.contracts = networkType === NetworkType.MAINNET
        ? STACKINSURE_CONTRACTS.MAINNET
        : STACKINSURE_CONTRACTS.TESTNET;
    }
  }

  /**
   * Create contract addresses from base address
   */
  private createContractAddresses(baseAddress: string) {
    const [address, _] = baseAddress.split('.');
    return {
      POLICY_REGISTRY: `${address}.policy-registry`,
      PREMIUM_CALCULATOR: `${address}.premium-calculator`,
      LIQUIDITY_POOL: `${address}.liquidity-pool`,
      CLAIMS_PROCESSING: `${address}.claims-processing`,
      VOTING: `${address}.voting`,
      ORACLE_INTEGRATION: `${address}.oracle-integration`,
      STAKING: `${address}.staking`,
    };
  }

  /**
   * Connect wallet
   */
  async connectWallet(
    onFinish?: (data: any) => void,
    onCancel?: () => void
  ): Promise<void> {
    await this.walletManager.connect(onFinish, onCancel);
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    return this.walletManager.isAuthenticated();
  }

  /**
   * Get user address
   */
  getUserAddress(): string | null {
    return this.walletManager.getUserAddress();
  }

  /**
   * Sign out
   */
  signOut(): void {
    this.walletManager.signOut();
  }

  /**
   * Calculate premium using wallet connection (UI-based)
   */
  async calculatePremiumUI(
    coverageAmount: bigint,
    riskCategory: string,
    durationDays: bigint
  ): Promise<void> {
    if (!this.isAuthenticated()) {
      throw new Error('User must be authenticated');
    }

    const [contractAddress, contractName] = this.contracts.PREMIUM_CALCULATOR.split('.');

    await openContractCall({
      contractAddress,
      contractName,
      functionName: 'calculate-premium',
      functionArgs: [
        uintCV(coverageAmount),
        stringAsciiCV(riskCategory),
        uintCV(durationDays),
      ],
      appDetails: {
        name: 'StackInsure',
        icon: window.location.origin + '/icon-192x192.png',
      },
      network: (this.walletManager.getAppConfig() as any).network,
      anchorMode: AnchorMode.Any,
      postConditionMode: PostConditionMode.Deny,
      onFinish: (data) => {
        console.log('Premium calculation transaction:', data);
      },
      onCancel: () => {
        console.log('User cancelled premium calculation');
      },
    });
  }

  /**
   * Create policy using wallet connection (UI-based)
   */
  async createPolicyUI(
    coverageAmount: bigint,
    premiumAmount: bigint,
    startDate: bigint,
    endDate: bigint,
    riskCategory: string
  ): Promise<void> {
    if (!this.isAuthenticated()) {
      throw new Error('User must be authenticated');
    }

    const [contractAddress, contractName] = this.contracts.POLICY_REGISTRY.split('.');

    await openContractCall({
      contractAddress,
      contractName,
      functionName: 'create-policy',
      functionArgs: [
        uintCV(coverageAmount),
        uintCV(premiumAmount),
        uintCV(startDate),
        uintCV(endDate),
        stringAsciiCV(riskCategory),
      ],
      appDetails: {
        name: 'StackInsure',
        icon: window.location.origin + '/icon-192x192.png',
      },
      network: (this.walletManager.getAppConfig() as any).network,
      anchorMode: AnchorMode.Any,
      postConditionMode: PostConditionMode.Deny,
      onFinish: (data) => {
        console.log('Policy creation transaction:', data);
      },
      onCancel: () => {
        console.log('User cancelled policy creation');
      },
    });
  }

  /**
   * Deposit liquidity using wallet connection (UI-based)
   */
  async depositLiquidityUI(amount: bigint): Promise<void> {
    if (!this.isAuthenticated()) {
      throw new Error('User must be authenticated');
    }

    const [contractAddress, contractName] = this.contracts.LIQUIDITY_POOL.split('.');

    await openContractCall({
      contractAddress,
      contractName,
      functionName: 'deposit-liquidity',
      functionArgs: [uintCV(amount)],
      appDetails: {
        name: 'StackInsure',
        icon: window.location.origin + '/icon-192x192.png',
      },
      network: (this.walletManager.getAppConfig() as any).network,
      anchorMode: AnchorMode.Any,
      postConditionMode: PostConditionMode.Deny,
      onFinish: (data) => {
        console.log('Liquidity deposit transaction:', data);
      },
      onCancel: () => {
        console.log('User cancelled liquidity deposit');
      },
    });
  }

  /**
   * Submit claim using wallet connection (UI-based)
   */
  async submitClaimUI(
    policyId: bigint,
    claimAmount: bigint,
    description: string,
    evidenceHash: Uint8Array
  ): Promise<void> {
    if (!this.isAuthenticated()) {
      throw new Error('User must be authenticated');
    }

    const [contractAddress, contractName] = this.contracts.CLAIMS_PROCESSING.split('.');

    await openContractCall({
      contractAddress,
      contractName,
      functionName: 'submit-claim',
      functionArgs: [
        uintCV(policyId),
        uintCV(claimAmount),
        stringAsciiCV(description),
        bufferCV(evidenceHash),
      ],
      appDetails: {
        name: 'StackInsure',
        icon: window.location.origin + '/icon-192x192.png',
      },
      network: (this.walletManager.getAppConfig() as any).network,
      anchorMode: AnchorMode.Any,
      postConditionMode: PostConditionMode.Deny,
      onFinish: (data) => {
        console.log('Claim submission transaction:', data);
      },
      onCancel: () => {
        console.log('User cancelled claim submission');
      },
    });
  }

  /**
   * Read-only: Get policy information
   */
  async getPolicy(policyId: bigint): Promise<any> {
    const [contractAddress, contractName] = this.contracts.POLICY_REGISTRY.split('.');
    
    const result = await callReadOnly({
      contractAddress,
      contractName,
      functionName: 'get-policy',
      functionArgs: [uintCV(policyId)],
      network: this.txBuilder['network'],
    });

    return result;
  }

  /**
   * Read-only: Calculate premium
   */
  async calculatePremium(
    coverageAmount: bigint,
    riskCategory: string,
    durationDays: bigint
  ): Promise<any> {
    const [contractAddress, contractName] = this.contracts.PREMIUM_CALCULATOR.split('.');
    
    const result = await callReadOnly({
      contractAddress,
      contractName,
      functionName: 'calculate-premium',
      functionArgs: [
        uintCV(coverageAmount),
        stringAsciiCV(riskCategory),
        uintCV(durationDays),
      ],
      network: this.txBuilder['network'],
    });

    return result;
  }

  /**
   * Read-only: Get underwriter balance
   */
  async getUnderwriterBalance(address: string): Promise<any> {
    const [contractAddress, contractName] = this.contracts.LIQUIDITY_POOL.split('.');
    
    const result = await callReadOnly({
      contractAddress,
      contractName,
      functionName: 'get-underwriter-balance',
      functionArgs: [standardPrincipalCV(address)],
      network: this.txBuilder['network'],
    });

    return result;
  }

  /**
   * Read-only: Get claim information
   */
  async getClaim(claimId: bigint): Promise<any> {
    const [contractAddress, contractName] = this.contracts.CLAIMS_PROCESSING.split('.');
    
    const result = await callReadOnly({
      contractAddress,
      contractName,
      functionName: 'get-claim',
      functionArgs: [uintCV(claimId)],
      network: this.txBuilder['network'],
    });

    return result;
  }

  /**
   * Get contract addresses
   */
  getContracts() {
    return this.contracts;
  }
}
