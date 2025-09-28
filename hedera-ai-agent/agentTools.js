// agentTools.js - Custom tools for Hedera AI Agent

const PriceService = require('./priceService');
const SwapService = require('./swapService');

class HederaAgentTools {
  constructor(client) {
    this.client = client;
    this.priceService = new PriceService(client);
    this.swapService = new SwapService(client);
  }

  async initialize() {
    await this.priceService.initialize();
    await this.swapService.initialize();
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