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
  getStacksProvider,
  StacksProvider
} from '@stacks/connect';
import { 
  StacksNetwork,
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
  // Use dynamic import to access network classes
  // These classes exist at runtime but TypeScript types may not expose them correctly
  const networkModule = '@stacks/network';
  
  switch (networkType) {
    case NetworkType.MAINNET:
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const { StacksMainnet } = require(networkModule);
      return new StacksMainnet();
    case NetworkType.TESTNET:
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const { StacksTestnet } = require(networkModule);
      return new StacksTestnet();
    case NetworkType.DEVNET:
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const { StacksDevnet } = require(networkModule);
      return new StacksDevnet();
    default:
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const { StacksTestnet: DefaultTestnet } = require(networkModule);
      return new DefaultTestnet();
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
    ...({ appName, appIconUrl: `${typeof window !== 'undefined' ? window.location.origin : ''}/icon-192x192.png`, network } as any),
  } as AppConfig;
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
      name: (appConfig as any).appName || 'StackInsure',
      icon: (appConfig as any).appIconUrl || '',
    },
    redirectTo: '/',
    onFinish: (payload) => {
      if (onFinish) {
        onFinish(payload);
      }
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
    const userData = session.loadUserData();
    const network = (appConfig as any).network;
    const chainId = network?.chainId || 'testnet';
    return userData.profile.stxAddress[chainId] || userData.profile.stxAddress.testnet || userData.profile.stxAddress.mainnet || null;
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
