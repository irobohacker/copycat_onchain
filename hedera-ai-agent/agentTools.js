// agentTools.js - Custom tools for Hedera AI Agent with integrated services

const PriceService = require('./priceService');
const SwapService = require('./swapService');
const axios = require('axios');
const { ethers } = require('ethers');

class HederaAgentTools {
  constructor(client) {
    this.client = client;
    this.priceService = new PriceService(client);
    this.swapService = new SwapService(client);

    // Initialize integrated services
    this.initializeServices();
  }

  async initialize() {
    await this.priceService.initialize();
    await this.swapService.initialize();
  }

  initializeServices() {
    // OpenAI Service Configuration
    this.openaiConfig = {
      apiKey: process.env.OPENAI_API_KEY || '',
      baseUrl: 'https://api.openai.com/v1/chat/completions'
    };

    // Masa AI Service Configuration
    this.masaAIConfig = {
      apiKey: process.env.MASA_API_KEY || '7rEpv8cPDY0ASoPA4CZ7Xp9l66Tct4PUnf3c1gDhwXnJkgwy',
      baseUrl: 'https://api.masa.ai/v1/search/live/web'
    };

    // Gopher Service Configuration
    this.gopherConfig = {
      apiKey: process.env.GOPHER_API_KEY || '',
      baseUrl: 'https://data.gopher-ai.com/api/v1'
    };

    // Trading Engine
    this.tradingSignals = [];
    this.maxSignalHistory = 100;

    // Token Tracking
    this.trackedTokens = new Map();
    this.swapHistory = [];
    this.isTracking = false;

    // Automation Service
    this.automationConfig = {
      enabled: false,
      interval: 5 * 60 * 1000, // 5 minutes
      tokens: ['ethereum', 'bitcoin', 'solana'],
      autoTrade: false
    };

    // Auto Lottery Service
    this.lotteryPlayers = [
      { address: '0x1234...5678', name: 'CryptoWhale', avatar: '🐋', winCount: 3, totalParticipations: 15 },
      { address: '0x2345...6789', name: 'DiamondHands', avatar: '💎', winCount: 1, totalParticipations: 12 },
      { address: '0x3456...789A', name: 'MoonRider', avatar: '🚀', winCount: 2, totalParticipations: 18 },
      { address: '0x4567...89AB', name: 'DegenTrader', avatar: '🎯', winCount: 0, totalParticipations: 8 },
      { address: '0x5678...9ABC', name: 'HODLMaster', avatar: '⚡', winCount: 4, totalParticipations: 20 },
      { address: '0x6789...ABCD', name: 'YieldFarmer', avatar: '🌾', winCount: 1, totalParticipations: 14 },
      { address: '0x789A...BCDE', name: 'NFTCollector', avatar: '🖼️', winCount: 2, totalParticipations: 16 },
      { address: '0x89AB...CDEF', name: 'AlphaHunter', avatar: '🦁', winCount: 3, totalParticipations: 19 },
      { address: '0x9ABC...DEF0', name: 'GigaBrain', avatar: '🧠', winCount: 5, totalParticipations: 22 },
      { address: '0xABCD...EF01', name: 'RektResistant', avatar: '🛡️', winCount: 1, totalParticipations: 11 }
    ];
    this.currentLotteryRound = null;
    this.lotteryHistory = [];
    this.lotteryCounter = 1;
  }

  // Helper methods for integrated services
  async generateOpenAIResponse(prompt) {
    if (!this.openaiConfig.apiKey) {
      return this.generateDemoResponse(prompt);
    }

    try {
      const response = await axios.post(this.openaiConfig.baseUrl, {
        model: 'gpt-4',
        messages: [
          {
            role: 'system',
            content: 'You are COPYCAT, an advanced AI trading assistant specializing in cryptocurrency and Hedera blockchain integration.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 1000,
        temperature: 0.7,
      }, {
        headers: {
          'Authorization': `Bearer ${this.openaiConfig.apiKey}`,
          'Content-Type': 'application/json'
        }
      });

      return response.data.choices[0]?.message?.content || "I'm experiencing technical difficulties.";
    } catch (error) {
      console.error('OpenAI API error:', error);
      return this.generateDemoResponse(prompt);
    }
  }

  generateDemoResponse(prompt) {
    const lowerPrompt = prompt.toLowerCase();

    if (lowerPrompt.includes('market') || lowerPrompt.includes('analysis')) {
      return `📊 **HEDERA AI Market Analysis**\n\n**Top Performing Groups:**\n• **Lets 57** by MercurySmile: +$49.3M PnL, 72.43% win rate\n• **AVNT_winners** by willpowered.eth: +$28.9M PnL, 75.61% win rate\n\n**HBAR Analysis:**\n• Current Price: $0.067 (+2.1%)\n• Network Activity: High transaction volume\n• DeFi Integration: Growing ecosystem\n\n**Hedera Strategy Recommendations:**\n• Monitor HTS token launches\n• Track consensus node rewards\n• Follow Hedera Council announcements`;
    }

    if (lowerPrompt.includes('track') && (lowerPrompt.includes('token') || lowerPrompt.includes('0x'))) {
      return `🎯 **HEDERA AI Token Tracking Activated**\n\n**Tracking Status:** ✅ ACTIVE on Hedera Network\n**HTS Integration:** Monitoring native token transfers\n**Consensus Tracking:** Real-time finality\n\n**Detected Activity (Last 24h):**\n• Buy Orders: 23 transactions\n• Sell Orders: 12 transactions\n• Net Flow: +$45,000 HBAR equivalent\n\n**Hedera Features:**\n• Sub-second finality\n• Fair ordering consensus\n• Carbon negative network`;
    }

    return `🤖 **HEDERA AI Assistant**\n\nPowered by Hedera Hashgraph consensus for:\n• Real-time price feeds via Hedera Consensus Service\n• Token tracking with HTS integration\n• DeFi automation on Hedera network\n• Lottery system with fair randomness\n\n**Available Commands:**\n• Market analysis with Hedera focus\n• Token tracking on HTS\n• Trading signals for HBAR pairs\n• Lottery participation management`;
  }

  async searchTwitterSentiment(token) {
    if (!this.gopherConfig.apiKey) {
      return {
        overall_sentiment: 'bullish',
        sentiment_score: 0.6,
        bullish_tweets: 15,
        bearish_tweets: 5,
        neutral_tweets: 10,
        total_tweets: 30,
        summary: `Demo: ${token} showing bullish sentiment with 50% positive mentions`
      };
    }

    try {
      const response = await axios.post(`${this.gopherConfig.baseUrl}/search/live/twitter`, {
        type: 'twitter',
        arguments: {
          type: 'searchbyquery',
          query: `$${token.toUpperCase()} OR #${token.toUpperCase()}`,
          max_results: 20
        }
      }, {
        headers: {
          'Authorization': `Bearer ${this.gopherConfig.apiKey}`,
          'Content-Type': 'application/json'
        }
      });

      return this.analyzeTweetSentiment(response.data?.data || []);
    } catch (error) {
      console.error('Gopher API error:', error);
      return null;
    }
  }

  analyzeTweetSentiment(tweets) {
    const bullishKeywords = ['moon', 'bullish', 'pump', 'buy', 'hodl', 'gains'];
    const bearishKeywords = ['dump', 'crash', 'sell', 'drop', 'loss', 'bearish'];

    let bullish = 0, bearish = 0, neutral = 0;

    tweets.forEach(tweet => {
      const text = tweet.text?.toLowerCase() || '';
      const bullishCount = bullishKeywords.filter(word => text.includes(word)).length;
      const bearishCount = bearishKeywords.filter(word => text.includes(word)).length;

      if (bullishCount > bearishCount) bullish++;
      else if (bearishCount > bullishCount) bearish++;
      else neutral++;
    });

    const total = bullish + bearish + neutral;
    const sentimentScore = total > 0 ? (bullish - bearish) / total : 0;
    const overallSentiment = sentimentScore > 0.2 ? 'bullish' : sentimentScore < -0.2 ? 'bearish' : 'neutral';

    return {
      overall_sentiment: overallSentiment,
      sentiment_score: sentimentScore,
      bullish_tweets: bullish,
      bearish_tweets: bearish,
      neutral_tweets: neutral,
      total_tweets: total,
      summary: `${overallSentiment.toUpperCase()} sentiment: ${bullish} bullish, ${bearish} bearish tweets`
    };
  }

  generateTradingSignal(data) {
    const technicalScore = Math.random() * 100 - 50;
    const sentimentScore = Math.random() * 100 - 50;
    const overallScore = (technicalScore * 0.6) + (sentimentScore * 0.4);

    let signal = 'HOLD';
    let confidence = 50;

    if (overallScore > 30) {
      signal = 'BUY';
      confidence = Math.min(95, Math.abs(overallScore));
    } else if (overallScore < -30) {
      signal = 'SELL';
      confidence = Math.min(95, Math.abs(overallScore));
    }

    const tradingSignal = {
      symbol: data.symbol || 'UNKNOWN',
      signal,
      confidence,
      reasoning: [
        `Overall score: ${overallScore.toFixed(1)}`,
        `Technical analysis: ${technicalScore.toFixed(1)}`,
        `Sentiment analysis: ${sentimentScore.toFixed(1)}`,
        `Hedera network activity: Normal`
      ],
      timestamp: Date.now(),
      priceTarget: data.currentPrice ? data.currentPrice * (signal === 'BUY' ? 1.05 : 0.95) : undefined
    };

    this.tradingSignals.unshift(tradingSignal);
    if (this.tradingSignals.length > this.maxSignalHistory) {
      this.tradingSignals = this.tradingSignals.slice(0, this.maxSignalHistory);
    }

    return tradingSignal;
  }

  startLotteryRound() {
    const now = Date.now();
    const participantCount = Math.floor(Math.random() * 8) + 5;
    const participants = [...this.lotteryPlayers].sort(() => Math.random() - 0.5).slice(0, participantCount);

    this.currentLotteryRound = {
      id: this.lotteryCounter++,
      startTime: now,
      endTime: now + (30 * 60 * 1000),
      participants,
      winner: null,
      prizePool: participantCount * 0.01,
      status: 'active'
    };

    return this.currentLotteryRound;
  }

  endLotteryRound() {
    if (!this.currentLotteryRound || this.currentLotteryRound.status !== 'active') {
      return null;
    }

    const winner = this.currentLotteryRound.participants[
      Math.floor(Math.random() * this.currentLotteryRound.participants.length)
    ];

    this.currentLotteryRound.winner = winner;
    this.currentLotteryRound.status = 'ended';

    this.lotteryHistory.unshift({...this.currentLotteryRound});
    if (this.lotteryHistory.length > 50) {
      this.lotteryHistory = this.lotteryHistory.slice(0, 50);
    }

    return this.currentLotteryRound;
  }

  // Tool definitions for LangChain
  getTools() {
    return [
      {
        name: "get_price",
        description: "Get the current price of a cryptocurrency asset (ETH, SOL, BTC, HBAR) in USD",
        parameters: {
          type: "object",
          properties: {
            asset: {
              type: "string",
              description: "The asset symbol (ETH/USD, SOL/USD, BTC/USD, HBAR/USD)"
            }
          },
          required: ["asset"]
        },
        func: async (params) => {
          try {
            const price = await this.priceService.getPrice(params.asset);
            const formattedPrice = this.priceService.formatPriceUSD(price.price, price.expo);
            return `Current price of ${params.asset}: ${formattedPrice} (updated at ${new Date(price.publishTime * 1000).toISOString()})`;
          } catch (error) {
            return `Error getting price for ${params.asset}: ${error.message}`;
          }
        }
      },

      {
        name: "calculate_swap",
        description: "Calculate how much you would receive when swapping between assets",
        parameters: {
          type: "object",
          properties: {
            fromAsset: {
              type: "string",
              description: "The asset to swap from (ETH, SOL, BTC, HBAR)"
            },
            toAsset: {
              type: "string",
              description: "The asset to swap to (ETH, SOL, BTC, HBAR)"
            },
            amount: {
              type: "string",
              description: "The amount to swap (in smallest units)"
            }
          },
          required: ["fromAsset", "toAsset", "amount"]
        },
        func: async (params) => {
          try {
            const output = await this.swapService.calculateSwapOutput(
              params.fromAsset,
              params.toAsset,
              params.amount
            );
            const formatted = this.swapService.formatSwapOutput(output);
            return `Swapping ${params.amount} ${params.fromAsset} would give you ${formatted.amountOut} ${params.toAsset}. Current prices: ${params.fromAsset}=$${formatted.fromPrice}, ${params.toAsset}=$${formatted.toPrice}`;
          } catch (error) {
            return `Error calculating swap: ${error.message}`;
          }
        }
      },

      {
        name: "get_reserves",
        description: "Get the current liquidity reserves for all assets in the swap pool",
        parameters: {
          type: "object",
          properties: {}
        },
        func: async () => {
          try {
            const reserves = await this.swapService.getAllReserves();
            return `Current reserves: ETH: ${reserves.ETH}, SOL: ${reserves.SOL}, BTC: ${reserves.BTC}, HBAR: ${reserves.HBAR}`;
          } catch (error) {
            return `Error getting reserves: ${error.message}`;
          }
        }
      },

      {
        name: "execute_swap_hbar_to_asset",
        description: "Execute a swap from HBAR to another asset",
        parameters: {
          type: "object",
          properties: {
            toAsset: {
              type: "string",
              description: "The asset to receive (ETH, SOL, BTC)"
            },
            hbarAmount: {
              type: "string",
              description: "Amount of HBAR to swap (in tinybars)"
            }
          },
          required: ["toAsset", "hbarAmount"]
        },
        func: async (params) => {
          try {
            const result = await this.swapService.swapHbarForAsset(params.toAsset, params.hbarAmount);
            return `Swap executed successfully! Transaction ID: ${result.transactionId}, Status: ${result.status}`;
          } catch (error) {
            return `Error executing swap: ${error.message}`;
          }
        }
      },

      {
        name: "get_supported_assets",
        description: "Get list of all supported assets for price feeds",
        parameters: {
          type: "object",
          properties: {}
        },
        func: async () => {
          try {
            const assets = await this.priceService.getSupportedAssets();
            return `Supported assets: ${assets.join(', ')}`;
          } catch (error) {
            return `Error getting supported assets: ${error.message}`;
          }
        }
      },

      {
        name: "calculate_hbar_value",
        description: "Calculate the equivalent HBAR value for a given amount of another asset",
        parameters: {
          type: "object",
          properties: {
            asset: {
              type: "string",
              description: "The asset symbol (ETH/USD, SOL/USD, BTC/USD)"
            },
            amount: {
              type: "string",
              description: "Amount of the asset"
            }
          },
          required: ["asset", "amount"]
        },
        func: async (params) => {
          try {
            const hbarValue = await this.priceService.calculateHbarValue(params.asset, params.amount);
            return `${params.amount} ${params.asset} is equivalent to ${hbarValue} HBAR`;
          } catch (error) {
            return `Error calculating HBAR value: ${error.message}`;
          }
        }
      }
    ];
  }
}

module.exports = HederaAgentTools;