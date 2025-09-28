# Deployment Scripts

This directory contains scripts for deploying and managing the ProfitableSaucerSwap and SwapLottery contracts.

## Configuration

The deployment scripts use `config/network-config.json` which contains:
- Real SaucerSwap V2 contract addresses for mainnet and testnet
- Pyth Network contract addresses
- Lottery configuration parameters

**IMPORTANT**: These are real contract addresses, not simulation or dummy data.

## Scripts

### 1. deploy-profitable-swap.js
Deploys both contracts and sets up their connections:
- Deploys SwapLottery contract
- Deploys ProfitableSaucerSwap contract
- Connects the contracts to each other
- Saves deployment summary to `deployments/` folder

### 2. verify-deployment.js
Verifies that the deployed contracts are working correctly:
- Tests contract responsiveness
- Verifies contract configurations
- Checks contract connections
- Tests Pyth Entropy integration

## Usage

### Deploy to Testnet
```bash
npx hardhat run scripts/deploy-profitable-swap.js --network testnet
```

### Deploy to Mainnet
```bash
npx hardhat run scripts/deploy-profitable-swap.js --network mainnet
```

### Verify Deployment
```bash
npx hardhat run scripts/verify-deployment.js --network testnet
# or
npx hardhat run scripts/verify-deployment.js --network mainnet
```

## Network Configuration

### Mainnet Addresses (Real Production Addresses)
- SaucerSwap V2 Router: `0.0.3949434`
- SaucerSwap V2 QuoterV2: `0.0.3949424`
- WHBAR: `0.0.1456985`

### Testnet Addresses (Real Testnet Addresses)
- SaucerSwap V2 Router: `0.0.1414040`
- SaucerSwap V2 QuoterV2: `0.0.1390002`
- WHBAR: `0.0.15057`

## Contract Functions

### ProfitableSaucerSwap
- Tracks round-trip profits automatically
- Charges 10% on profits (8% to lottery pool)
- Integrates with SaucerSwap V2 for real swaps
- Enters profitable users in lottery

### SwapLottery
- Uses Pyth Entropy for random number generation
- Manages lottery rounds with configurable duration
- Assigns random ticket numbers to participants
- Selects winners based on closest ticket to winning number

## Output

Deployment creates:
- `deployments/{network}-deployment.json` with contract addresses
- Verification logs showing contract status
- Contract interaction confirmations

## Security Notes

- All addresses are from official SaucerSwap documentation
- Pyth Network integration uses official contracts
- No simulation or test data used in production deployments
- Ownership and admin functions properly configured