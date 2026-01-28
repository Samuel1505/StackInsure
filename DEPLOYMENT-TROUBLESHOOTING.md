# Deployment Troubleshooting

## Contracts Status
✅ All 7 contracts compile successfully
✅ No syntax errors
✅ All Clarity 4 syntax is correct
✅ No deprecated functions

## Why Transactions Might Not Confirm

If transactions are broadcast but not confirmed, it's usually due to:

### 1. Network Congestion
- Mainnet can be congested
- Transactions may take time to confirm
- Check transaction status on https://explorer.stacks.co

### 2. Transaction Fees
- Ensure you have sufficient STX for fees
- Each contract deployment costs STX (see deployment plan)

### 3. Anchor Block Timing
- Contracts with `anchor-block-only: true` must be included in an anchor block
- This can take longer (Bitcoin block time ~10 minutes)

### 4. Contract Size/Cost
- Large contracts may take longer to process
- Check if contracts exceed size limits

## Verification Steps

1. **Check transaction status:**
   ```bash
   # Check your transactions on Stacks Explorer
   # Search for your transaction IDs
   ```

2. **Verify contracts compile:**
   ```bash
   ./check-deployment-ready.sh
   ```

3. **Check network status:**
   - Visit https://status.hiro.so
   - Check if Stacks network is operational

4. **Wait for confirmation:**
   - Mainnet transactions can take 10-30 minutes
   - Anchor block transactions take longer

## Next Steps After Deployment

Once contracts are confirmed, initialize owners:
```clarity
(contract-call? .policy-registry set-contract-owner {your-principal})
(contract-call? .premium-calculator set-contract-owner {your-principal})
(contract-call? .liquidity-pool set-contract-owner {your-principal})
(contract-call? .claims-processing set-contract-owner {your-principal})
(contract-call? .voting set-contract-owner {your-principal})
(contract-call? .oracle-integration set-contract-owner {your-principal})
(contract-call? .staking set-contract-owner {your-principal})
```
