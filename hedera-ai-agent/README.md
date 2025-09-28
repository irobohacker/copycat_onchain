# Hedera AI Agent

A LangChain-powered AI agent for interacting with Hedera contracts, including Pyth price feeds and swap functionality.

## Features

- **Price Feeds**: Get real-time cryptocurrency prices using Pyth Network
- **Swap Calculations**: Calculate swap outputs between different assets
- **Liquidity Information**: Check reserves and liquidity pools
- **Smart Contract Interaction**: Execute swaps and other contract functions
- **Multi-LLM Support**: Works with OpenAI, Anthropic, Groq, or local Ollama

## Setup

1. Install dependencies:
```bash
npm install
```

2. Configure environment variables in `.env`:
```env
# Hedera Configuration
HEDERA_ACCOUNT_ID=your_account_id
HEDERA_PRIVATE_KEY=your_private_key

# AI Provider (choose one)
OPENAI_API_KEY=your_openai_key
ANTHROPIC_API_KEY=your_anthropic_key
GROQ_API_KEY=your_groq_key
```

3. Update contract addresses in `contracts.js` after deployment

## Usage

Run the agent:
```bash
node index.js
```

## Available Tools

The agent provides the following tools:

- `get_price`: Get current price of cryptocurrency assets
- `calculate_swap`: Calculate swap output between assets
- `get_reserves`: Get current liquidity reserves
- `execute_swap_hbar_to_asset`: Execute HBAR to asset swaps
- `get_supported_assets`: List supported assets
- `calculate_hbar_value`: Calculate HBAR equivalent value

## File Structure

- `index.js`: Main agent entry point
- `contracts.js`: Contract addresses and ABIs
- `priceService.js`: Price feed service wrapper
- `swapService.js`: Swap functionality service
- `agentTools.js`: Custom LangChain tools

## Contract Integration

The agent integrates with the following contracts:

- **PythPriceFeed**: Real-time price feeds from Pyth Network
- **HbarPythSwap**: Asset swapping with HBAR
- **ProfitableSaucerSwap**: Advanced swap strategies
- **SwapLottery**: Lottery-based swapping
- **COPYCATLottery**: Copy trading lottery system

## Example Queries

- "What's the current price of ETH?"
- "How much SOL would I get for 1000 HBAR?"
- "What are the current reserves?"
- "Execute a swap of 100 HBAR for ETH"
- "Show me all supported assets"

## Notes

- Update Pyth price feed IDs in `contracts.js` with actual values
- Deploy contracts and update addresses before using swap functionality
- Ensure sufficient HBAR balance for transaction fees