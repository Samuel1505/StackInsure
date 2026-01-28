# StackInsure

A decentralized insurance platform built on the Stacks blockchain, providing transparent, trustless insurance services through smart contracts. StackInsure enables policy creation, premium calculation, claims processing, liquidity management, and governance through a comprehensive suite of Clarity smart contracts.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Smart Contracts](#smart-contracts)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Development](#development)
- [Testing](#testing)
- [Deployment](#deployment)
- [Usage Examples](#usage-examples)
- [Contract Interactions](#contract-interactions)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

StackInsure is a decentralized insurance protocol that leverages the Stacks blockchain to provide transparent and automated insurance services. The platform consists of seven interconnected smart contracts that handle different aspects of the insurance lifecycle:

- **Policy Management**: Create, update, and manage insurance policies
- **Premium Calculation**: Dynamic premium pricing based on risk factors
- **Liquidity Pool**: Manage underwriter capital and reserves
- **Claims Processing**: Submit, review, and process insurance claims
- **Voting System**: Decentralized governance for claim validation
- **Oracle Integration**: External data verification for claims
- **Staking**: Reward mechanism for underwriters

### Key Benefits

- **Transparency**: All operations are recorded on-chain
- **Trustless**: No need for intermediaries
- **Automated**: Smart contracts handle policy and claim processing
- **Decentralized Governance**: Community-driven decision making
- **Risk-Based Pricing**: Dynamic premium calculation based on multiple factors

## Architecture

StackInsure follows a modular architecture where each smart contract handles a specific domain:

```
┌─────────────────────────────────────────────────────────────┐
│                    StackInsure Platform                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Policy     │  │   Premium    │  │  Liquidity   │     │
│  │   Registry   │  │  Calculator  │  │     Pool     │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘             │
│                            │                                │
│  ┌──────────────┐  ┌──────┴───────┐  ┌──────────────┐     │
│  │   Claims     │  │    Voting    │  │   Oracle     │     │
│  │  Processing  │  │    System    │  │ Integration  │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘             │
│                            │                                │
│                    ┌───────┴───────┐                        │
│                    │    Staking    │                        │
│                    │    Contract   │                        │
│                    └───────────────┘                        │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Smart Contracts

### 1. Policy Registry (`policy-registry.clar`)

Manages the lifecycle of insurance policies.

**Key Functions:**
- `create-policy`: Create a new insurance policy
- `update-policy-status`: Update policy status (owner only)
- `cancel-policy`: Cancel an active policy (policy holder only)
- `get-policy`: Retrieve policy information
- `is-policy-active`: Check if a policy is currently active

**Policy Statuses:**
- `STATUS_ACTIVE` (u1): Policy is active and valid
- `STATUS_EXPIRED` (u2): Policy has expired
- `STATUS_CANCELLED` (u3): Policy was cancelled
- `STATUS_CLAIMED` (u4): Policy has an associated claim

**Data Structure:**
- Policy ID (auto-incremented)
- Policy holder (principal)
- Coverage amount (uint)
- Premium amount (uint)
- Start/end dates (uint)
- Status (uint)
- Risk category (string-ascii 20)
- Created timestamp (uint)

### 2. Premium Calculator (`premium-calculator.clar`)

Calculates insurance premiums based on risk factors and coverage parameters.

**Key Functions:**
- `calculate-premium`: Basic premium calculation
- `calculate-premium-advanced`: Advanced calculation with additional factors
- `calculate-premium-with-tier`: Premium with coverage tier multiplier
- `initialize-risk-factors`: Initialize risk category multipliers (owner only)
- `update-risk-multiplier`: Update risk multipliers (owner only)
- `get-risk-factor`: Get risk factor for a category

**Risk Categories:**
- `low`: Multiplier 0.8x (8000/10000)
- `medium`: Multiplier 1.2x (12000/10000)
- `high`: Multiplier 1.8x (18000/10000)
- `very_high`: Multiplier 2.5x (25000/10000)

**Coverage Tiers:**
- < 10,000: 1.0x multiplier
- 10,000 - 50,000: 1.1x multiplier
- 50,000 - 100,000: 1.2x multiplier
- 100,000 - 500,000: 1.5x multiplier
- ≥ 500,000: 2.0x multiplier

**Premium Formula:**
```
base_premium = coverage_amount × (base_rate / 10000)
risk_adjusted = base_premium × (risk_multiplier / 10000)
duration_adjusted = risk_adjusted × (1 + duration_days / 365)
final_premium = duration_adjusted × (tier_multiplier / 10000)
```

### 3. Liquidity Pool (`liquidity-pool.clar`)

Manages underwriter capital deposits, withdrawals, and reserves.

**Key Functions:**
- `deposit-liquidity`: Deposit funds into the pool
- `request-withdrawal`: Request withdrawal of funds
- `approve-withdrawal`: Approve withdrawal request (owner only)
- `reject-withdrawal`: Reject withdrawal request (owner only)
- `reserve-liquidity`: Reserve liquidity for claims
- `release-reserved-liquidity`: Release reserved liquidity
- `add-earnings`: Add earnings to underwriter (owner only)
- `get-underwriter-balance`: Get balance information
- `get-total-liquidity`: Get total pool liquidity
- `get-available-liquidity`: Get available (non-reserved) liquidity

**Minimum Deposit:** 1,000,000 microSTX (1 STX)

**Withdrawal Statuses:**
- `WITHDRAWAL_PENDING` (u1): Request pending approval
- `WITHDRAWAL_APPROVED` (u2): Request approved
- `WITHDRAWAL_REJECTED` (u3): Request rejected

**Balance Structure:**
- `deposited`: Total amount deposited
- `available`: Available for withdrawal
- `reserved`: Reserved for pending withdrawals/claims
- `total-earnings`: Total earnings accumulated

### 4. Claims Processing (`claims-processing.clar`)

Handles the submission, review, and processing of insurance claims.

**Key Functions:**
- `submit-claim`: Submit a new claim
- `update-claim-status`: Update claim status (owner only)
- `approve-claim`: Approve a claim (owner only)
- `reject-claim`: Reject a claim with reason (owner only)
- `mark-claim-under-review`: Mark claim as under review (owner only)
- `mark-claim-paid`: Mark approved claim as paid (owner only)
- `get-claim`: Retrieve claim information
- `is-claim-valid`: Check if claim is valid

**Claim Statuses:**
- `CLAIM_STATUS_SUBMITTED` (u1): Claim submitted
- `CLAIM_STATUS_UNDER_REVIEW` (u2): Claim under review
- `CLAIM_STATUS_APPROVED` (u3): Claim approved
- `CLAIM_STATUS_REJECTED` (u4): Claim rejected
- `CLAIM_STATUS_PAID` (u5): Claim paid out

**Minimum Claim Amount:** 1,000 microSTX

**Claim Data Structure:**
- Claim ID (auto-incremented)
- Policy ID (uint)
- Claimant (principal)
- Claim amount (uint)
- Description (string-ascii 200)
- Status (uint)
- Submission timestamp (uint)
- Review timestamp (optional uint)
- Resolution timestamp (optional uint)
- Evidence hash (buff 32)

### 5. Voting (`voting.clar`)

Decentralized voting mechanism for claim validation and governance.

**Key Functions:**
- `create-voting-session`: Create voting session for a claim (owner only)
- `cast-vote`: Cast a vote (approve/reject/abstain)
- `close-voting-session`: Close voting and determine result (owner only)
- `set-voter-weight`: Set voting weight for a voter (owner only)
- `get-voting-session`: Get session details
- `get-vote`: Get vote cast by a voter
- `is-voting-open`: Check if voting is still open
- `get-voting-result`: Get voting result

**Vote Options:**
- `VOTE_APPROVE` (u1): Approve the claim
- `VOTE_REJECT` (u2): Reject the claim
- `VOTE_ABSTAIN` (u3): Abstain from voting

**Voting Statuses:**
- `VOTING_OPEN` (u1): Voting is open
- `VOTING_CLOSED` (u2): Voting is closed
- `VOTING_RESOLVED` (u3): Voting is resolved

**Parameters:**
- Minimum voting period: 100 blocks
- Default voting period: 144 blocks (~24 hours)
- Minimum votes required: 3

**Voting Result:**
- Result is determined by majority of weighted votes
- Quorum must be met for valid result
- Ties result in abstain

### 6. Oracle Integration (`oracle-integration.clar`)

Integrates with external oracles to fetch real-world data for claim validation.

**Key Functions:**
- `request-oracle-data`: Request data from oracle
- `submit-oracle-data`: Submit data (oracle provider only)
- `verify-oracle-data`: Verify submitted data (owner only)
- `register-oracle-provider`: Register oracle provider (owner only)
- `update-provider-reputation`: Update provider reputation (owner only)
- `deactivate-oracle-provider`: Deactivate provider (owner only)
- `get-oracle-request`: Get request information
- `get-verified-data`: Get verified data by hash

**Data Types:**
- `DATA_TYPE_WEATHER` (u1): Weather data
- `DATA_TYPE_EVENT` (u2): Event data
- `DATA_TYPE_PRICE` (u3): Price data
- `DATA_TYPE_LOCATION` (u4): Location data
- `DATA_TYPE_TIMESTAMP` (u5): Timestamp data

**Data Statuses:**
- `DATA_STATUS_PENDING` (u1): Request pending
- `DATA_STATUS_VERIFIED` (u2): Data verified
- `DATA_STATUS_INVALID` (u3): Data invalid

**Provider Management:**
- Providers must be registered by contract owner
- Reputation system tracks provider performance
- Active/inactive status management
- Success rate tracking

### 7. Staking (`staking.clar`)

Manages underwriter staking and reward distribution.

**Key Functions:**
- `stake`: Deposit stake
- `initiate-unstaking`: Initiate unstaking process
- `withdraw-stake`: Complete unstaking and withdraw
- `claim-rewards`: Claim pending rewards
- `calculate-pending-rewards`: Calculate pending rewards
- `create-reward-pool`: Create reward pool (owner only)
- `update-reward-rate`: Update reward rate (owner only)
- `get-stake-info`: Get staker information
- `get-total-staked`: Get total staked amount

**Staking Statuses:**
- `STAKE_ACTIVE` (u1): Stake is active
- `STAKE_UNSTAKING` (u2): Unstaking in progress
- `STAKE_UNSTAKED` (u3): Stake withdrawn

**Parameters:**
- Minimum stake: 1,000,000 microSTX (1 STX)
- Unstaking period: 144 blocks (~24 hours)
- Base reward rate: 100 (configurable by owner)
- Reward calculation: Time-based with compounding

**Reward Calculation:**
```
base_reward = stake_amount × (reward_rate / 10000)
time_adjusted = base_reward × (time_diff / 86400)
```

## Features

### Core Features

1. **Policy Management**
   - Create insurance policies with customizable coverage
   - Track policy lifecycle (active, expired, cancelled, claimed)
   - Policy holder can cancel their own policies
   - Automatic status updates based on dates

2. **Dynamic Premium Calculation**
   - Risk-based pricing with multiple categories
   - Coverage tier multipliers
   - Duration-based adjustments
   - Advanced calculation with age and history factors

3. **Liquidity Management**
   - Underwriter capital pooling
   - Reserve management for claims
   - Withdrawal request system with approval workflow
   - Earnings tracking and distribution

4. **Claims Processing**
   - Submit claims with evidence hash
   - Multi-stage review process
   - Status tracking throughout lifecycle
   - Minimum claim amount enforcement

5. **Decentralized Governance**
   - Voting system for claim validation
   - Weighted voting support
   - Quorum-based decision making
   - Transparent voting records

6. **Oracle Integration**
   - Multiple data type support
   - Provider reputation system
   - Data verification and validation
   - Hash-based data integrity

7. **Staking & Rewards**
   - Stake tokens to participate as underwriter
   - Time-based reward calculation
   - Unstaking with cooldown period
   - Reward pool management

### Security Features

- Owner-only functions for critical operations
- One-time contract owner initialization
- Input validation on all functions
- Status checks before state transitions
- Minimum amount requirements
- Time-based validations

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** (v18 or higher)
- **npm** or **yarn**
- **Clarinet** (Stacks smart contract development tool)
- **Git**

### Installing Clarinet

```bash
# macOS
brew install clarinet

# Linux
curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz -o clarinet.tar.gz
tar -xzf clarinet.tar.gz
chmod +x clarinet
sudo mv clarinet /usr/local/bin/

# Windows (using Scoop)
scoop bucket add hiro https://github.com/hirosystems/scoop-bucket.git
scoop install clarinet
```

Verify installation:
```bash
clarinet --version
```

## Installation

1. **Clone the repository:**
```bash
git clone <repository-url>
cd StackInsure
```

2. **Install dependencies:**
```bash
npm install
```

3. **Verify Clarinet configuration:**
```bash
clarinet check
```

4. **Start local development environment:**
```bash
clarinet console
```

## Development

### Project Structure

```
StackInsure/
├── contracts/              # Clarity smart contracts
│   ├── stackin.clar       # Main entry contract
│   ├── policy-registry.clar
│   ├── premium-calculator.clar
│   ├── liquidity-pool.clar
│   ├── claims-processing.clar
│   ├── voting.clar
│   ├── oracle-integration.clar
│   └── staking.clar
├── tests/                  # Test files
│   └── stackin.test.ts
├── settings/               # Network configurations
│   ├── Devnet.toml
│   ├── Testnet.toml
│   └── Mainnet.toml
├── deployments/            # Deployment plans
│   └── default.mainnet-plan.yaml
├── Clarinet.toml          # Clarinet configuration
├── package.json           # Node.js dependencies
├── vitest.config.ts       # Test configuration
└── README.md              # This file
```

### Development Workflow

1. **Start Clarinet console:**
```bash
clarinet console
```

2. **Run tests:**
```bash
npm test
```

3. **Check contracts:**
```bash
clarinet check
# or use the wrapper script
./check-contracts.sh
```

4. **Check deployment readiness:**
```bash
./check-deployment-ready.sh
```

### Contract Owner Initialization

**Important:** After deploying contracts, you must initialize the contract owner for each contract. This is a one-time operation:

```clarity
;; Initialize owners (replace {your-principal} with your principal)
(contract-call? .policy-registry set-contract-owner {your-principal})
(contract-call? .premium-calculator set-contract-owner {your-principal})
(contract-call? .liquidity-pool set-contract-owner {your-principal})
(contract-call? .claims-processing set-contract-owner {your-principal})
(contract-call? .voting set-contract-owner {your-principal})
(contract-call? .oracle-integration set-contract-owner {your-principal})
(contract-call? .staking set-contract-owner {your-principal})
```

### Clarity Version

All contracts use **Clarity version 4** and are configured for the latest epoch.

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage and cost reports
npm run test:report

# Watch mode (auto-rerun on changes)
npm run test:watch
```

### Test Structure

Tests are written in TypeScript using Vitest and the Clarinet SDK. Example test structure:

```typescript
import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;

describe("Policy Registry Tests", () => {
  it("should create a policy", () => {
    // Test implementation
  });
});
```

### Writing Tests

When writing tests, consider:
- Testing all public functions
- Testing error conditions
- Testing access control (owner-only functions)
- Testing state transitions
- Testing edge cases

## Deployment

### Pre-Deployment Checklist

- [ ] All contracts compile successfully (`clarinet check`)
- [ ] All tests pass (`npm test`)
- [ ] Contract owners are identified
- [ ] Network configuration is correct
- [ ] Sufficient STX for deployment fees

### Deployment Steps

1. **Review deployment plan:**
```bash
cat deployments/default.mainnet-plan.yaml
```

2. **Check deployment readiness:**
```bash
./check-deployment-ready.sh
```

3. **Deploy to testnet first:**
```bash
clarinet deploy --testnet
```

4. **Initialize contract owners** (see [Contract Owner Initialization](#contract-owner-initialization))

5. **Verify deployment:**
   - Check transactions on [Stacks Explorer](https://explorer.stacks.co)
   - Verify contract addresses
   - Test contract functions

6. **Deploy to mainnet:**
```bash
clarinet deploy --mainnet
```

### Network Configuration

Network settings are configured in `settings/`:
- `Devnet.toml`: Local development
- `Testnet.toml`: Testnet deployment
- `Mainnet.toml`: Mainnet deployment

### Deployment Troubleshooting

See [DEPLOYMENT-TROUBLESHOOTING.md](./DEPLOYMENT-TROUBLESHOOTING.md) for common issues and solutions.

Common issues:
- Transactions not confirming (network congestion)
- Insufficient STX for fees
- Anchor block timing delays
- Contract size limits

## Usage Examples

### Creating an Insurance Policy

```clarity
;; 1. Calculate premium first
(contract-call? .premium-calculator calculate-premium
  u1000000  ;; coverage amount (1 STX)
  "medium"  ;; risk category
  u365      ;; duration in days
)

;; 2. Create policy
(contract-call? .policy-registry create-policy
  u1000000                    ;; coverage amount
  u120000                     ;; premium amount (from step 1)
  u1704067200                 ;; start date (Unix timestamp)
  u1740604800                 ;; end date (Unix timestamp)
  "medium"                    ;; risk category
)
```

### Depositing Liquidity

```clarity
;; Deposit liquidity as underwriter
(contract-call? .liquidity-pool deposit-liquidity
  u10000000  ;; 10 STX minimum
)
```

### Submitting a Claim

```clarity
;; Submit a claim
(contract-call? .claims-processing submit-claim
  u1                              ;; policy ID
  u500000                         ;; claim amount
  "Damage to property occurred"   ;; description
  0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef  ;; evidence hash
)
```

### Voting on a Claim

```clarity
;; 1. Create voting session (owner only)
(contract-call? .voting create-voting-session
  u1        ;; claim ID
  u144      ;; voting period (blocks)
  u3        ;; quorum
)

;; 2. Cast vote
(contract-call? .voting cast-vote
  u1        ;; session ID
  u1        ;; VOTE_APPROVE
)

;; 3. Close voting (owner only)
(contract-call? .voting close-voting-session
  u1        ;; session ID
)
```

### Staking

```clarity
;; 1. Stake tokens
(contract-call? .staking stake
  u10000000  ;; 10 STX minimum
)

;; 2. Claim rewards
(contract-call? .staking claim-rewards)

;; 3. Initiate unstaking
(contract-call? .staking initiate-unstaking
  u5000000  ;; 5 STX
)

;; 4. Withdraw after cooldown period
(contract-call? .staking withdraw-stake)
```

## Contract Interactions

### Reading Contract State

```clarity
;; Get policy information
(contract-call? .policy-registry get-policy u1)

;; Get underwriter balance
(contract-call? .liquidity-pool get-underwriter-balance {your-principal})

;; Get claim information
(contract-call? .claims-processing get-claim u1)

;; Get stake information
(contract-call? .staking get-stake-info {your-principal})

;; Get total liquidity
(contract-call? .liquidity-pool get-total-liquidity)
```

### Owner Functions

Many contracts have owner-only functions. Ensure you've initialized the contract owner before calling these:

**Policy Registry:**
- `update-policy-status`
- `set-contract-owner`

**Premium Calculator:**
- `initialize-risk-factors`
- `update-risk-multiplier`
- `set-contract-owner`

**Liquidity Pool:**
- `approve-withdrawal`
- `reject-withdrawal`
- `add-earnings`
- `set-contract-owner`

**Claims Processing:**
- `update-claim-status`
- `approve-claim`
- `reject-claim`
- `mark-claim-under-review`
- `mark-claim-paid`
- `set-contract-owner`

**Voting:**
- `create-voting-session`
- `close-voting-session`
- `set-voter-weight`
- `set-contract-owner`

**Oracle Integration:**
- `register-oracle-provider`
- `verify-oracle-data`
- `update-provider-reputation`
- `deactivate-oracle-provider`
- `set-contract-owner`

**Staking:**
- `create-reward-pool`
- `update-reward-rate`
- `set-contract-owner`

## Security Considerations

### Access Control

- All contracts implement owner-only functions for critical operations
- Contract owners must be initialized after deployment
- Owner initialization is one-time only (prevents re-initialization)

### Input Validation

- All functions validate inputs (amounts, dates, statuses)
- Minimum amounts enforced (deposits, stakes, claims)
- Date validations (end date > start date)
- Status transition validations

### State Management

- Proper state transitions enforced
- Reserved liquidity tracking prevents double-spending
- Unstaking cooldown prevents instant withdrawals
- Voting prevents double-voting

### Best Practices

1. **Always initialize contract owners** after deployment
2. **Test thoroughly** on testnet before mainnet deployment
3. **Monitor contract events** for important state changes
4. **Verify oracle data** before using in claims processing
5. **Use proper error handling** when calling contracts
6. **Keep contract owners secure** (use hardware wallets)

### Known Limitations

- Oracle data submission requires trusted providers
- Voting quorum must be carefully configured
- Unstaking period is fixed (144 blocks)
- Premium calculation multipliers are owner-configurable

## Troubleshooting

### Common Issues

**Contracts won't compile:**
```bash
# Check Clarity version compatibility
clarinet check

# Verify syntax
clarinet check --manifest ./Clarinet.toml
```

**Tests failing:**
```bash
# Clear cache and rerun
rm -rf .cache
npm test
```

**Deployment issues:**
- Check network status: https://status.hiro.so
- Verify sufficient STX balance
- Check transaction status on explorer
- Review [DEPLOYMENT-TROUBLESHOOTING.md](./DEPLOYMENT-TROUBLESHOOTING.md)

**Contract owner initialization:**
- Ensure you're calling `set-contract-owner` only once
- Verify you're using the correct principal
- Check that contract is deployed and confirmed

### Getting Help

- Check existing issues on GitHub
- Review Stacks documentation: https://docs.stacks.co
- Join Stacks community: https://discord.gg/stacks
- Review contract code comments

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Add tests** for new functionality
5. **Ensure all tests pass** (`npm test`)
6. **Check contracts compile** (`clarinet check`)
7. **Commit your changes** (`git commit -m 'Add amazing feature'`)
8. **Push to the branch** (`git push origin feature/amazing-feature`)
9. **Open a Pull Request**

### Code Style

- Follow Clarity best practices
- Add comments for complex logic
- Use descriptive variable names
- Include error codes in comments
- Write comprehensive tests

### Testing Requirements

- All new functions must have tests
- Test both success and error cases
- Test access control (owner-only functions)
- Test edge cases and boundary conditions

## License

[Specify your license here]

## Acknowledgments

- Built on the Stacks blockchain
- Uses Clarinet for development
- Clarity smart contract language

## Additional Resources

- [Stacks Documentation](https://docs.stacks.co)
- [Clarity Language Reference](https://docs.stacks.co/docs/clarity)
- [Clarinet Documentation](https://docs.hiro.so/clarinet)
- [Stacks Explorer](https://explorer.stacks.co)
- [Stacks Status](https://status.hiro.so)

---

**Note:** This is a comprehensive insurance platform. Always test thoroughly on testnet before deploying to mainnet. Ensure you understand the implications of deploying smart contracts that handle financial transactions.
