# 🚀 Deploy COPYCAT Lottery Contract

## 📋 **Quick Fix for "Contract not initialized" Error**

The error you're seeing is because the lottery contract hasn't been deployed yet. Here's how to fix it:

### **Option 1: Deploy via Remix IDE (Easiest)**

1. **Go to Remix IDE**: [https://remix.ethereum.org](https://remix.ethereum.org)

2. **Create New File**: 
   - Create a file called `COPYCATLottery.sol`
   - Copy the contract code from `contracts/contracts/COPYCATLottery.sol`

3. **Install Dependencies**:
   - In Remix, go to "File Manager" → "Dependencies"
   - Add: `@pythnetwork/entropy-sdk-solidity`

4. **Compile Contract**:
   - Go to "Solidity Compiler"
   - Select compiler version 0.8.0+
   - Click "Compile COPYCATLottery.sol"

5. **Deploy Contract**:
   - Go to "Deploy & Run Transactions"
   - Select "Injected Provider - MetaMask"
   - Make sure you're on Ethereum Sepolia testnet
   - Add constructor parameters:
     - `_entropy`: `0x41c9e39574F40Ad34c79f1C99B66A45eFB830d4c`
     - `_entropyProvider`: `0x6CC14824Ea2918f5De5C2f75A9Da968ad4BD6344`
   - Click "Deploy"

6. **Copy Contract Address**:
   - After deployment, copy the contract address
   - Update `frontend/src/config/contracts.ts`:
   ```typescript
   LOTTERY_CONTRACT_ADDRESS: 'YOUR_DEPLOYED_CONTRACT_ADDRESS',
   ```

### **Option 2: Deploy via Hardhat**

1. **Setup Environment**:
   ```bash
   cd contracts
   cp .env.example .env
   # Add your private key and RPC URL to .env
   ```

2. **Deploy Contract**:
   ```bash
   npx hardhat run scripts/deploy-lottery-sepolia.ts --network sepolia
   ```

3. **Update Frontend**:
   - Copy the deployed contract address
   - Update `frontend/src/config/contracts.ts`

### **Option 3: Use Existing Contract (If Available)**

If you already have a deployed contract, just update the address in:
```typescript
// frontend/src/config/contracts.ts
LOTTERY_CONTRACT_ADDRESS: 'YOUR_CONTRACT_ADDRESS',
```

## 🔧 **After Deployment**

1. **Update Contract Address**:
   ```typescript
   // In frontend/src/config/contracts.ts
   LOTTERY_CONTRACT_ADDRESS: '0x...', // Your deployed address
   ```

2. **Refresh the Page**:
   - The lottery page should now work
   - You'll see contract stats and can create lotteries

3. **Test the Contract**:
   - Create a test lottery
   - Join with test ETH
   - Verify everything works

## 🎯 **Expected Result**

After deployment, you should see:
- ✅ Contract stats (Total Lotteries: 0, etc.)
- ✅ No more "Contract not initialized" error
- ✅ Ability to create and join lotteries
- ✅ Working lottery functionality

## 🆘 **Troubleshooting**

**Still getting errors?**
1. Check the contract address is correct
2. Make sure you're on Ethereum Sepolia testnet
3. Verify the contract was deployed successfully
4. Check browser console for detailed errors

**Need test ETH?**
- Get Sepolia ETH from: [https://sepoliafaucet.com](https://sepoliafaucet.com)

---

**Once deployed, your lottery will be fully functional!** 🎰
