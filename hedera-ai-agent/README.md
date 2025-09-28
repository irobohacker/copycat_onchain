# COPYCAT Hedera AI Agent 🤖

An advanced autonomous AI agent that integrates all COPYCAT trading services with Hedera Hashgraph using natural language. Powered by Hedera Agent Kit with comprehensive trading, sentiment analysis, and automation features.

## 🚀 New Integrated Features

### 🤖 AI Services Integration
- **OpenAI GPT-4**: Advanced trading advice and market analysis
- **Twitter Sentiment Analysis**: Real-time social sentiment via Gopher API
- **Web Scraping**: Market data collection with Masa AI
- **Trading Signal Generation**: AI-powered buy/sell/hold recommendations

### 📊 Trading & Analytics
- **Token Tracking**: Monitor specific wallets and token addresses
- **Automated Trading**: Configurable trading strategies and automation
- **Portfolio Analysis**: Performance tracking and optimization
- **Risk Management**: Stop-loss, take-profit, and risk assessment

### 🎰 Entertainment & Community
- **Auto Lottery System**: Provably fair lottery with 20 active players
- **Community Features**: Track top traders and performance metrics
- **Gamification**: Win/loss tracking and leaderboards

### ⚡ Hedera Native Features
- **HTS Integration**: Native Hedera Token Service support
- **Consensus Service**: Real-time finality for all operations
- **Price Feeds**: Pyth Network integration for accurate pricing
- **Fair Randomness**: Hedera's consensus for lottery fairness

## 🛠️ Quick Start

1. **Clone and Install**
   ```bash
   git clone <your-repo>
   cd hedera-ai-agent
   npm install
   ```

2. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

3. **Set up Hedera Account** (Required)
   - Get free testnet account at [Hedera Portal](https://portal.hedera.com/dashboard)
   - Add your Account ID and ECDSA Private Key to `.env`

4. **Choose AI Provider** (Pick one or more)

   **OpenAI (Recommended for full features)**
   - Get API key from [OpenAI Platform](https://platform.openai.com/api-keys)
   - Add `OPENAI_API_KEY` to `.env`

   **Anthropic Claude**
   - Get API key from [Anthropic Console](https://console.anthropic.com)
   - Add `ANTHROPIC_API_KEY` to `.env`

   **Groq (Fast & Free)**
   - Get API key from [Groq Console](https://console.groq.com/keys)
   - Add `GROQ_API_KEY` to `.env`

   **Ollama (Local)**
   - Install [Ollama](https://ollama.com)
   - Run: `ollama pull llama3.2`

5. **Optional: Add Service API Keys** (for enhanced features)
   ```env
   GOPHER_API_KEY=""     # Twitter sentiment analysis
   MASA_API_KEY=""       # Web scraping (demo key included)
   ```

6. **Run the Enhanced Agent**
   ```bash
   node index.js
   ```

## 🎯 Example Queries

### 💰 Basic Hedera Operations
- "What's my HBAR balance?"
- "Get current price of ETH/USD"
- "Calculate swap: 1000 HBAR to SOL"

### 🤖 AI-Powered Analysis
- "Ask AI assistant: What's the best DeFi strategy for Hedera?"
- "Analyze Twitter sentiment for HBAR"
- "Generate trading signal for HBAR/USD"
- "Scrape market data for HBAR from coindesk"

### 📊 Trading & Automation
- "Start automation monitoring for ETH, BTC, and HBAR"
- "Track token 0x4675c7e5baafbffbca748158becba61ef3b0a263"
- "Analyze my trading history for the last 10 signals"
- "Get automation status"

### 🎰 Lottery & Entertainment
- "Check lottery status and current round"
- "Start a new lottery round"
- "Show top lottery players"
- "View recent lottery winners"

### 📈 Portfolio Management
- "Generate comprehensive market analysis"
- "What tokens should I track?"
- "Show trading signal analysis"
- "Get risk assessment for my portfolio"

## ⚙️ Configuration

### Required Environment Variables
```env
HEDERA_ACCOUNT_ID="0.0.xxxxx"
HEDERA_PRIVATE_KEY="0x..." # ECDSA encoded private key
```

### AI Provider Keys (choose one or more)
```env
OPENAI_API_KEY="sk-proj-..."
ANTHROPIC_API_KEY="sk-ant-..."
GROQ_API_KEY="gsk_..."
```

### Optional Service Keys (for enhanced features)
```env
MASA_API_KEY="7rEpv8cPDY0ASoPA4CZ7Xp9l66Tct4PUnf3c1gDhwXnJkgwy"
GOPHER_API_KEY=""
VITE_OPENAI_API_KEY=""
VITE_GOPHER_API_KEY=""
```

## 🏗️ Architecture

### Core Components
- **Enhanced Agent Tools**: 15+ integrated tools covering all COPYCAT services
- **Multi-AI Support**: OpenAI, Claude, Groq, and Ollama with intelligent fallbacks
- **Service Integration**: All frontend services ported to the Hedera AI environment
- **Real-time Features**: Live price feeds, sentiment analysis, and automation

### Integrated Services
1. **OpenAI Service**: GPT-4 powered trading advice and analysis
2. **Masa AI Service**: Web scraping for market data and price information
3. **Gopher Service**: Twitter sentiment analysis and social metrics
4. **Trading Engine**: AI-powered signal generation and analysis
5. **Token Tracking Service**: Wallet and token monitoring system
6. **Automation Service**: Configurable trading automation and monitoring
7. **Auto Lottery Service**: Fair lottery system with 20+ active players

## 🛡️ Available Tools

### Core Hedera Tools
- `get_price` - Real-time cryptocurrency prices
- `calculate_swap` - Token swap calculations
- `get_reserves` - Liquidity pool information
- `execute_swap_hbar_to_asset` - Execute swaps
- `calculate_hbar_value` - HBAR value calculations

### AI & Analytics Tools
- `ask_ai_assistant` - OpenAI GPT-4 powered advice
- `analyze_twitter_sentiment` - Social sentiment analysis
- `generate_trading_signal` - AI trading recommendations
- `scrape_market_data` - Real-time market data collection
- `analyze_trading_history` - Performance analytics

### Automation & Tracking
- `track_token` - Monitor tokens and wallets
- `automation_control` - Trading automation management
- `lottery_manager` - Lottery system management

## 🎰 Lottery System

The integrated lottery system features:
- **20 Active Players**: Unique personalities with win/loss tracking
- **30-minute Rounds**: Automated rounds every 30 minutes
- **Fair Randomness**: Powered by Hedera's consensus
- **Prize Pools**: Dynamic HBAR rewards based on participation
- **Leaderboards**: Track top winners and performance stats

## 📊 Trading Features

### Signal Generation
- Technical analysis integration
- Sentiment-based scoring
- Confidence levels (0-100%)
- Price targets and stop-losses
- Historical performance tracking

### Risk Management
- Conservative recommendations
- Stop-loss calculations
- Portfolio diversification advice
- Market sentiment integration
- Real-time alerts and notifications

## 🔧 Development

```bash
# Install dependencies
npm install

# Run in development mode
node index.js

# Test specific features
# Modify queries in index.js to test different tools
```

## 🚨 Troubleshooting

**"No AI provider configured"**
- Add at least one AI provider API key to `.env`
- Or install and run Ollama locally

**"Service integration error"**
- Check that axios and ethers are installed: `npm install axios ethers`
- Verify API keys are correctly formatted

**"Trading signals not working"**
- Ensure OpenAI API key is configured for full functionality
- Demo mode is available without API keys

**"Token tracking failed"**
- Check that the token/wallet addresses are valid
- Ensure network connectivity for blockchain queries

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add new tools to `agentTools.js`
4. Test with multiple AI providers
5. Update documentation
6. Submit a pull request

## 📜 License

MIT License - see LICENSE file for details

---

**Powered by Hedera Hashgraph** ⚡ **Enhanced with COPYCAT Trading Intelligence** 🤖