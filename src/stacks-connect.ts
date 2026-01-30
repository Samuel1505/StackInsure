/**
 * Stacks Connect Integration
 * 
 * This module provides utilities for connecting to Stacks wallets
 * and handling user authentication using @stacks/connect
 */

import { 
  AppConfig, 
  UserSession, 
  showConnect,
  openContractCall,
  openContractDeploy,
  openSTXTransfer,
  finished,
  getStacksProvider,
  StacksProvider
} from '@stacks/connect';
import { 
  StacksMainnet, 
  StacksTestnet, 
  StacksNetwork,
  StacksDevnet
} from '@stacks/network';

/**
 * Network configuration
 */
export enum NetworkType {
  MAINNET = 'mainnet',
  TESTNET = 'testnet',
  DEVNET = 'devnet'
}

/**
 * Get Stacks network instance based on network type
 */
export function getNetwork(networkType: NetworkType = NetworkType.TESTNET): StacksNetwork {
  switch (networkType) {
    case NetworkType.MAINNET:
      return new StacksMainnet();
    case NetworkType.TESTNET:
      return new StacksTestnet();
    case NetworkType.DEVNET:
      return new StacksDevnet();
    default:
      return new StacksTestnet();
  }
}

/**
 * Initialize Stacks Connect App Configuration
 */
export function createAppConfig(
  appName: string = 'StackInsure',
  networkType: NetworkType = NetworkType.TESTNET
): AppConfig {
  const network = getNetwork(networkType);
  
  return {
    appName,
    appIconUrl: `${window.location.origin}/icon-192x192.png`,
    network,
  };
}

/**
 * Connect to Stacks Wallet
 */
export async function connectWallet(
  appConfig: AppConfig,
  onFinish?: (data: any) => void,
  onCancel?: () => void
): Promise<void> {
  await showConnect({
    appDetails: {
      name: appConfig.appName,
      icon: appConfig.appIconUrl || '',
    },
    redirectTo: '/',
    onFinish: (payload) => {
      if (onFinish) {
        onFinish(payload);
      }
      finished(payload);
    },
    onCancel: () => {
      if (onCancel) {
        onCancel();
      }
    },
    userSession: new UserSession({ appConfig }),
  });
}

/**
 * Get current user session
 */
export function getUserSession(appConfig: AppConfig): UserSession {
  return new UserSession({ appConfig });
}

/**
 * Check if user is authenticated
 */
export function isAuthenticated(appConfig: AppConfig): boolean {
  const session = getUserSession(appConfig);
  return session.isUserSignedIn();
}

/**
 * Get authenticated user's address
 */
export function getUserAddress(appConfig: AppConfig): string | null {
  const session = getUserSession(appConfig);
  if (session.isUserSignedIn()) {
    return session.loadUserData().profile.stxAddress[appConfig.network?.chainId || 'testnet'];
  }
  return null;
}

/**
 * Sign out user
 */
export function signOut(appConfig: AppConfig): void {
  const session = getUserSession(appConfig);
  session.signUserOut();
}

/**
 * Get Stacks Provider (for programmatic wallet interactions)
 */
export function getProvider(): StacksProvider | null {
  try {
    return getStacksProvider();
  } catch (error) {
    console.error('Failed to get Stacks provider:', error);
    return null;
  }
}

/**
 * Wallet connection manager class
 */
export class WalletConnectionManager {
  private appConfig: AppConfig;
  private userSession: UserSession;

  constructor(
    appName: string = 'StackInsure',
    networkType: NetworkType = NetworkType.TESTNET
  ) {
    this.appConfig = createAppConfig(appName, networkType);
    this.userSession = getUserSession(this.appConfig);
  }

  /**
   * Connect wallet
   */
  async connect(onFinish?: (data: any) => void, onCancel?: () => void): Promise<void> {
    await connectWallet(this.appConfig, onFinish, onCancel);
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    return isAuthenticated(this.appConfig);
  }

  /**
   * Get user address
   */
  getUserAddress(): string | null {
    return getUserAddress(this.appConfig);
  }

  /**
   * Get user session
   */
  getSession(): UserSession {
    return this.userSession;
  }

  /**
   * Sign out
   */
  signOut(): void {
    signOut(this.appConfig);
  }

  /**
   * Get app config
   */
  getAppConfig(): AppConfig {
    return this.appConfig;
  }
}
