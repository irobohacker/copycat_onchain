# Real HBAR ⟷ Asset Swapping Guide

The HbarPythSwap contract now supports **REAL asset swapping** with actual token transfers, not just simulations!

## 🔄 How It Works

### **1. Liquidity Management**
The contract maintains reserves of HBAR and other assets (ETH, SOL, BTC tokens) that enable real swaps.

### **2. Real Asset Transfers**
- **HBAR → Asset**: Users send HBAR, receive ERC20 tokens
- **Asset → HBAR**: Users send ERC20 tokens, receive HBAR
- **All transfers are atomic** - either the swap succeeds completely or fails

### **3. Live Price Feeds**
Swap rates are calculated using real-time Pyth Network price feeds

## 🚀 Usage Examples

### **Adding Liquidity (Owner Only)**

```solidity
// Add HBAR liquidity
await swapContract.addHbarLiquidity({ value: ethers.utils.parseEther("100") });

// Add ETH token liquidity (requires pre-approval)
await ethToken.approve(swapContract.address, ethers.utils.parseEther("50"));
await swapContract.addAssetLiquidity(0, ethers.utils.parseEther("50")); // 0 = ETH
```

### **Real HBAR → ETH Swap**

```solidity
// User swaps 1 HBAR for ETH tokens
// Price is calculated using live Pyth feeds
await swapContract.swapHbarForAsset(0, {
  value: ethers.utils.parseEther("1")
});

// ETH tokens are automatically transferred to user's wallet
```

### **Real ETH → HBAR Swap**

```solidity
// User swaps ETH tokens for HBAR
const ethAmount = ethers.utils.parseEther("0.1");
const minHbarOut = ethers.utils.parseEther("0.95"); // 5% slippage tolerance

// First approve the swap contract to spend ETH tokens
await ethToken.approve(swapContract.address, ethAmount);

// Execute the swap
await swapContract.swapAssetForHbar(0, ethAmount, minHbarOut);

// HBAR is automatically transferred to user's wallet
```

### **Swap with Price Updates**

```solidity
// Get fresh price data from Pyth API
const priceUpdateData = await fetchPythPriceUpdates();

// Swap with price update in same transaction
await swapContract.updateAndSwapHbarForAsset(priceUpdateData, 1, {
  value: ethers.utils.parseEther("2") // 1 HBAR for swap + update fee
});
```

## 🔧 Contract Functions

### **Swap Functions**
- `swapHbarForAsset(Asset toAsset)` - Send HBAR, get tokens
- `swapAssetForHbar(Asset fromAsset, uint256 amountIn, uint256 minHbarOut)` - Send tokens, get HBAR
- `updateAndSwapHbarForAsset(bytes[] priceUpdateData, Asset toAsset)` - Update prices and swap

### **Liquidity Functions (Owner Only)**
- `addHbarLiquidity()` - Add HBAR to reserves
- `addAssetLiquidity(Asset asset, uint256 amount)` - Add asset tokens to reserves
- `removeLiquidity(Asset asset, uint256 amount)` - Remove assets from reserves

### **View Functions**
- `calculateSwapOutput(Asset fromAsset, Asset toAsset, uint256 amountIn)` - Preview swap amounts
- `getReserve(Asset asset)` - Check individual reserve
- `getAllReserves()` - Check all reserves
- `getAssetPrice(Asset asset)` - Get current Pyth price

## ⚡ Key Features

### **✅ Real Asset Transfers**
- Actual ERC20 token transfers
- Native HBAR transfers
- No more simulations!

### **✅ Reserve Management**
- Contract maintains liquidity pools
- Owner can add/remove liquidity
- Automatic reserve updates

### **✅ Slippage Protection**
- Minimum output amounts
- Configurable slippage tolerance
- Transaction reverts on excessive slippage

### **✅ Safety Checks**
- Insufficient balance protection
- Price data freshness validation
- Reentrancy guards

### **✅ Live Pricing**
- Real-time Pyth price feeds
- Configurable max price age
- Price update integration

## 🛠 Setup for Production

### **1. Deploy Asset Token Contracts**
Deploy ERC20 contracts for wrapped ETH, SOL, BTC on Hedera:

```solidity
// Example: Deploy WETH token contract
const WETH = await ethers.getContractFactory('ERC20');
const weth = await WETH.deploy('Wrapped Ethereum', 'WETH');
```

### **2. Deploy HbarPythSwap**
```bash
# Set token addresses in environment
export ETH_TOKEN_ADDRESS=0x...
export SOL_TOKEN_ADDRESS=0x...
export BTC_TOKEN_ADDRESS=0x...

# Deploy the swap contract
npx hardhat run scripts/deploy-hbar-swap.ts --network hedera-testnet
```

### **3. Add Initial Liquidity**
```solidity
// Owner adds initial liquidity
await swapContract.addHbarLiquidity({ value: ethers.utils.parseEther("1000") });
await swapContract.addAssetLiquidity(0, ethers.utils.parseEther("500")); // ETH
await swapContract.addAssetLiquidity(1, ethers.utils.parseEther("10000")); // SOL
```

### **4. Frontend Integration**
```javascript
// Check if swap is possible
const [amountOut, fromPrice, toPrice] = await contract.calculateSwapOutput(
  fromAsset, toAsset, amountIn
);

// Execute swap with proper approvals
if (fromAsset !== HBAR) {
  await tokenContract.approve(swapContract.address, amountIn);
}
await swapContract.swapHbarForAsset(toAsset, { value: amountIn });
```

## 🎯 Benefits

1. **Real Utility**: Actual asset swapping, not just price calculations
2. **Decentralized**: No external DEX dependencies
3. **Live Pricing**: Real-time Pyth price feeds
4. **Slippage Protection**: Built-in slippage controls
5. **Owner Controlled**: Liquidity management by contract owner
6. **Upgradeable**: UUPS proxy pattern for future improvements

## ⚠️ Important Notes

- **Requires Liquidity**: Contract needs adequate reserves for swaps
- **ERC20 Approvals**: Users must approve token spending before asset→HBAR swaps
- **Price Updates**: Fresh price data recommended for large swaps
- **Gas Fees**: Consider transaction costs in swap calculations
- **Slippage**: Set appropriate minimum output amounts

Your HBAR ⟷ Asset swapping is now **REAL and READY**! 🚀