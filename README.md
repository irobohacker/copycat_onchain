# 🎰 COPYCAT - On-Chain Trading & Lottery Platform

A comprehensive decentralized application combining AI-powered trading strategies, fair lottery systems, and advanced zero-knowledge proofs on the Hedera blockchain.

## 🚀 **Live Demo**

**Frontend**: [http://localhost:3000](http://localhost:3000)  
**Contract**: [0x6d721f50535259e039c811e934e3d51b41caf3774d451a9ec542c5952985c15b](https://eth-sepolia.blockscout.com/tx/0x6d721f50535259e039c811e934e3d51b41caf3774d451a9ec542c5952985c15b)
https://eth-sepolia.blockscout.com/tx/0x27ff740d492a62ee9d3bd4a519bc7c0f161c7fb9c5359d5abb86a536ce18365c  
**Network**: Ethereum Sepolia Testnet

### **Hedera Contracts**

- **[0.0.6917343](https://hashscan.io/testnet/contract/0.0.6917343/calls)** - Lottery Contract
- **[0.0.6917342](https://hashscan.io/testnet/contract/0.0.6917342/calls)** - Trading Strategy Contract

### **Flow Contracts**

- **Counter**: [0x990440cb0ee9e385](https://flow-view-testnet.blockscout.com/contract/0x990440cb0ee9e385)
- **PythPriceFeed**: [0x990440cb0ee9e385](https://flow-view-testnet.blockscout.com/contract/0x990440cb0ee9e385)
- **TestablePythIntegration**: [0x990440cb0ee9e385](https://flow-view-testnet.blockscout.com/contract/0x990440cb0ee9e385)
- **TestablePythTrading**: [0x990440cb0ee9e385](https://flow-view-testnet.blockscout.com/contract/0x990440cb0ee9e385)


## ✨ **Features**

### 🤖 **AI-Powered Trading**
- **OpenAI Integration** - Advanced AI assistant for market analysis
- **Strategy Generation** - AI creates custom trading strategies
- **Portfolio Management** - Intelligent portfolio review and optimization
- **Risk Assessment** - AI-powered risk analysis and mitigation

### 🎰 **Fair Lottery System**
- **Pyth Entropy** - Provably fair randomness using Pyth Entropy
- **Real-time Participation** - Join lotteries with ETH
- **Automatic Winner Selection** - Fair winner selection via blockchain
- **Prize Distribution** - Secure prize claiming system

### 🔍 **Trading Discovery**
- **Top Groups** - Discover best performing trading groups
- **Real Performance Data** - Live PnL, win rates, and scam rates
- **Group Analytics** - Detailed group statistics and rankings
- **Copy Trading** - Follow successful traders automatically

### 🎯 **Strategy Management**
- **Custom Strategies** - Create and manage trading strategies
- **Template Library** - Pre-built strategy templates
- **Performance Tracking** - Monitor strategy performance
- **Risk Management** - Built-in stop losses and position sizing

### 🔐 **Zero-Knowledge Proofs**
- **ZK Circuits** - Compiled and ready for verification
- **Trading Group Verification** - Prove membership without revealing identity
- **Privacy Protection** - Secure trading group participation
- **Verification Keys** - Ready for on-chain verification

## 🏗️ **Architecture**

### **Frontend (React + TypeScript)**
```
frontend/
├── src/
│   ├── components/          # React components
│   ├── services/           # API and blockchain services
│   ├── contexts/           # React contexts
│   ├── config/             # Configuration files
│   └── contracts/          # Contract ABIs
├── public/
│   └── circuits/           # ZK circuit artifacts
└── circom/                 # ZK circuit source code
```

### **Smart Contracts (Solidity)**
```
contracts/
├── contracts/              # Solidity contracts
│   ├── COPYCATLottery.sol  # Lottery contract with Pyth Entropy
│   ├── Topic.sol          # Hedera topic management
│   ├── PythPriceFeed.sol  # Price feed integration
│   └── HbarPythSwap.sol   # HBAR swap functionality
├── scripts/               # Deployment scripts
└── test/                  # Contract tests
```

### **ZK Circuits (Circom)**
```
circom/
├── contractProof.circom    # Main ZK circuit
├── TradingGroupVerifier.sol # Solidity verifier
└── verification_key.json   # Verification key
```

## 🚀 **Quick Start**

### **Prerequisites**
- Node.js 18+
- npm or yarn
- MetaMask wallet
- Git

### **Installation**

1. **Clone the repository**
```bash
git clone <repository-url>
cd blackrock_onchain
```

2. **Install dependencies**
```bash
# Frontend
cd frontend
npm install

# Contracts
cd ../contracts
npm install
```

3. **Environment Setup**
```bash
# Copy environment template
cp frontend/.env.example frontend/.env

# Add your API keys
VITE_OPENAI_API_KEY=your_openai_key
VITE_GEMINI_API_KEY=your_gemini_key
```

4. **Start development server**
```bash
cd frontend
npm run dev
```

5. **Access the application**
Open [http://localhost:3000](http://localhost:3000)

## 🔧 **Configuration**

### **AI Services**
```bash
# OpenAI (Primary)
VITE_OPENAI_API_KEY=sk-...

# Gemini (Alternative)
VITE_GEMINI_API_KEY=AI...
```

### **Blockchain Networks**
```typescript
// Ethereum Sepolia (Lottery)
Chain ID: 11155111
RPC: https://sepolia.infura.io/v3/YOUR_KEY

// Hedera Testnet (Trading)
Network: testnet
Chain ID: 296
```

### **Contract Addresses**
```typescript
// Lottery Contract (Ethereum Sepolia)
LOTTERY_CONTRACT: 0x6d721f50535259e039c811e934e3d51b41caf3774d451a9ec542c5952985c15b

// Pyth Entropy
ENTROPY_CONTRACT: 0x41c9e39574F40Ad34c79f1C99B66A45eFB830d4c
ENTROPY_PROVIDER: 0x6CC14824Ea2918f5De5C2f75A9Da968ad4BD6344
```

## 📱 **Usage**

### **AI Assistant**
1. Navigate to "AI Assistant"
2. Ask questions like:
   - "Give me a market analysis"
   - "Generate a trading strategy"
   - "Who are the top traders?"
   - "Show 7 day PnL for $AVNT"

### **Lottery Participation**
1. Go to "Lottery" page
2. Connect your wallet
3. View active lotteries
4. Join by paying entry fee
5. Claim prizes if you win

### **Strategy Management**
1. Visit "Strategies" page
2. Choose from templates or create custom
3. Set parameters (amounts, gains, stop losses)
4. Activate and monitor performance

### **Discover Trading Groups**
1. Check "Discover" page
2. Browse top performing groups
3. View performance metrics
4. Copy successful strategies

## 🎯 **Key Components**

### **AI Services**
- **OpenAI Integration** - GPT-4 powered trading insights
- **Strategy Generation** - AI creates custom trading strategies
- **Market Analysis** - Real-time market insights
- **Risk Assessment** - Intelligent risk management

### **Lottery System**
- **Fair Randomness** - Pyth Entropy ensures fairness
- **Smart Contracts** - Automated lottery management
- **Prize Distribution** - Secure winner selection
- **User Statistics** - Track participation and winnings

### **Trading Features**
- **Group Discovery** - Find top performing traders
- **Copy Trading** - Follow successful strategies
- **Performance Analytics** - Detailed trading metrics
- **Risk Management** - Built-in safety features

### **ZK Proofs**
- **Circuit Compilation** - Ready-to-use ZK circuits
- **Verification** - On-chain proof verification
- **Privacy** - Secure group membership
- **Integration** - Seamless frontend integration

## 🔒 **Security**

### **Smart Contract Security**
- **Audited Contracts** - Thoroughly tested smart contracts
- **Access Controls** - Proper permission management
- **Emergency Functions** - Owner controls for emergencies
- **Fee Validation** - Proper fee handling

### **Frontend Security**
- **Wallet Integration** - Secure MetaMask connection
- **API Key Management** - Environment variable protection
- **Input Validation** - Proper user input handling
- **Error Handling** - Graceful error management

### **ZK Proof Security**
- **Trusted Setup** - Secure parameter generation
- **Verification** - Cryptographic proof verification
- **Privacy** - Zero-knowledge property maintained
- **Integration** - Secure on-chain verification

## 📊 **Performance**

### **Frontend Performance**
- **React Optimization** - Efficient component rendering
- **Lazy Loading** - On-demand component loading
- **Caching** - Smart data caching strategies
- **Responsive Design** - Mobile-first approach

### **Blockchain Performance**
- **Gas Optimization** - Efficient smart contract execution
- **Batch Operations** - Optimized transaction batching
- **Event Listening** - Real-time blockchain events
- **Error Recovery** - Robust error handling

## 🧪 **Testing**

### **Frontend Testing**
```bash
cd frontend
npm test
```

### **Contract Testing**
```bash
cd contracts
npx hardhat test
```

### **ZK Circuit Testing**
```bash
cd frontend
npm run test-circuits
```

## 🚀 **Deployment**

### **Frontend Deployment**
```bash
cd frontend
npm run build
npm run deploy
```

### **Contract Deployment**
```bash
cd contracts
npx hardhat run scripts/deploy-lottery.ts --network sepolia
```

### **Environment Variables**
```bash
# Production environment
VITE_OPENAI_API_KEY=your_production_key
VITE_GEMINI_API_KEY=your_production_key
```

## 📈 **Analytics**

### **User Analytics**
- **Participation Tracking** - Lottery participation metrics
- **Strategy Performance** - Trading strategy analytics
- **User Engagement** - Platform usage statistics
- **Revenue Metrics** - Platform revenue tracking

### **Blockchain Analytics**
- **Transaction Volume** - On-chain transaction metrics
- **Gas Usage** - Smart contract gas consumption
- **Event Tracking** - Blockchain event monitoring
- **Performance Metrics** - Contract performance data

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### **Development Guidelines**
- Follow TypeScript best practices
- Write comprehensive tests
- Document new features
- Follow the existing code style

## 📄 **License**

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

## 🆘 **Support**

### **Documentation**
- [AI Setup Guide](frontend/AI_SETUP.md)
- [ZK Circuits Guide](frontend/ZK_CIRCUITS_README.md)
- [Lottery Integration](frontend/LOTTERY_INTEGRATION.md)
- [Deployment Guide](frontend/DEPLOYMENT.md)

### **Troubleshooting**
- Check the [Issues](https://github.com/your-repo/issues) page
- Review the documentation
- Test on testnets first
- Verify environment variables

## 🎉 **Acknowledgments**

- **Pyth Network** - For providing fair randomness via Entropy
- **OpenAI** - For AI-powered trading insights
- **Hedera** - For blockchain infrastructure
- **Circom** - For zero-knowledge proof circuits

---

**🎰 Ready to experience the future of decentralized trading and fair gaming!**

**Built with ❤️ using React, Solidity, and Zero-Knowledge Proofs**