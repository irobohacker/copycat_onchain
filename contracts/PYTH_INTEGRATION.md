# Pyth Network Integration for Hedera

This project integrates Pyth Network's price feeds with Hedera smart contracts, enabling real-time asset price fetching and HBAR-based asset swapping functionality.

## Contracts

### 1. PythPriceFeed.sol
A contract that extends the Topic pattern and provides price feed functionality using Pyth Network.

**Features:**
- Fetch real-time prices for ETH, SOL, BTC, and HBAR
- Support for adding custom assets with their Pyth price feed IDs
- Price data validation and formatting
- HBAR value calculation for any supported asset

**Key Functions:**
- `getPrice(string asset)` - Get raw price data for an asset
- `getPriceNoOlderThan(string asset, uint256 maxAge)` - Get price data with freshness guarantee
- `getPriceFormatted(string asset)` - Get price formatted to 18 decimals
- `calculateHbarValue(string asset, uint256 assetAmount)` - Calculate HBAR equivalent value
- `updatePriceFeeds(bytes[] priceUpdateData)` - Update price feeds with Pyth data

### 2. HbarPythSwap.sol
A comprehensive swap contract that enables HBAR ⟷ Asset swapping using Pyth price feeds.

**Features:**
- Real-time price fetching for swap calculations
- Configurable slippage tolerance and swap fees
- Support for ETH, SOL, BTC swaps with HBAR
- Price update integration for accurate swaps
- Upgradeable proxy pattern

**Key Functions:**
- `swapHbarForAsset(Asset toAsset)` - Swap HBAR for specified asset
- `swapAssetForHbar(Asset fromAsset, uint256 amountIn, uint256 minHbarOut)` - Swap asset for HBAR
- `calculateSwapOutput(Asset fromAsset, Asset toAsset, uint256 amountIn)` - Calculate swap amounts
- `updateAndSwapHbarForAsset(bytes[] priceUpdateData, Asset toAsset)` - Update prices and swap in one transaction

## Supported Assets

| Asset | Price Feed ID (Mainnet) |
|-------|------------------------|
| ETH/USD | `0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace` |
| SOL/USD | `0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8ed0c6c7bc0f4cfac8c280b56d` |
| BTC/USD | `0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43` |
| HBAR/USD | `0x5748504c9899a2b3743ceb4fa11c9e9b0e509b6a8fb41e6c1e19e72b3d90fb7` |

## Deployment

### Prerequisites
1. Install dependencies:
```bash
cd contracts
npm install
```

2. Set up environment variables:
```bash
# .env file
PYTH_CONTRACT_ADDRESS=0x4374e5a8b9C22271E9EB878A2AA31DE97DF15DAF  # Update with actual Pyth address
```

### Deploy PythPriceFeed
```bash
npx hardhat run scripts/deploy-pyth-pricefeed.ts --network hedera-testnet
```

### Deploy HbarPythSwap
```bash
npx hardhat run scripts/deploy-hbar-swap.ts --network hedera-testnet
```

## Usage Examples

### Fetching Asset Prices
```solidity
// Get ETH price
(uint256 price, int32 expo, uint256 publishTime) = priceFeed.getPrice("ETH/USD");

// Get formatted ETH price (18 decimals)
uint256 formattedPrice = priceFeed.getPriceFormatted("ETH/USD");

// Calculate HBAR value for 1 ETH
uint256 hbarValue = priceFeed.calculateHbarValue("ETH/USD", 1 ether);
```

### Performing Swaps
```solidity
// Swap 1 HBAR for ETH (price will be fetched automatically)
hbarSwap.swapHbarForAsset{value: 1 ether}(HbarPythSwap.Asset.ETH);

// Update prices and swap in one transaction
bytes[] memory priceData = getPriceUpdateData(); // Get from Pyth API
hbarSwap.updateAndSwapHbarForAsset{value: 2 ether}(priceData, HbarPythSwap.Asset.SOL);
```

## Price Updates

To ensure accurate pricing, price feeds should be updated regularly:

1. **Automatic Updates**: The contracts support price updates via the `updatePriceFeeds()` function
2. **Update with Swap**: Use `updateAndSwapHbarForAsset()` to update prices and execute swap atomically
3. **Price Freshness**: Contracts can enforce maximum price age (default: 60 seconds)

## Integration with Frontend

The frontend can interact with these contracts to:
1. Display real-time asset prices
2. Calculate swap estimates
3. Execute HBAR ⟷ Asset swaps
4. Update price feeds when needed

Example integration points:
- Use Hedera wallet (HashPack, Blade, etc.) for transaction signing
- Fetch price update data from Pyth API
- Display swap rates and estimates to users
- Handle transaction confirmations and status updates

## Testing

Run the test suite:
```bash
npm test
```

The tests cover:
- Contract initialization and configuration
- Price feed functionality
- Swap calculations (with mocked Pyth data)
- Access control and security features
- Integration between PythPriceFeed and HbarPythSwap

## Security Considerations

1. **Price Validation**: All price data is validated before use
2. **Slippage Protection**: Configurable slippage tolerance prevents sandwich attacks
3. **Access Control**: Critical functions are protected by ownership
4. **Reentrancy Protection**: All swap functions use reentrancy guards
5. **Price Freshness**: Maximum price age prevents stale data usage

## Production Deployment

For production deployment:

1. **Update Pyth Contract Address**: Use the official Pyth contract address for your network
2. **Verify Price Feed IDs**: Ensure price feed IDs are current and accurate
3. **Set Appropriate Parameters**: Configure slippage, fees, and price age limits
4. **Security Audit**: Conduct thorough security audit before mainnet deployment
5. **Monitoring**: Implement monitoring for price updates and swap activities

## Resources

- [Pyth Network Documentation](https://docs.pyth.network/)
- [Pyth Solidity SDK](https://github.com/pyth-network/pyth-sdk-solidity)
- [Hedera Documentation](https://docs.hedera.com/)
- [Price Feed IDs](https://pyth.network/developers/price-feed-ids)