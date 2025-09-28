// priceService.js - Price feed service for Hedera AI Agent

const { Contract } = require('@hashgraph/sdk');
const { CONTRACT_ADDRESSES, CONTRACT_ABIS, PRICE_IDS } = require('./contracts');

class PriceService {
  constructor(client) {
    this.client = client;
    this.pythContract = null;
  }

  // Initialize the Pyth price feed contract
  async initialize() {
    if (CONTRACT_ADDRESSES.PYTH_PRICE_FEED) {
      this.pythContract = new Contract({
        contractId: CONTRACT_ADDRESSES.PYTH_PRICE_FEED,
        abi: CONTRACT_ABIS.PythPriceFeed
      });
    }
  }

  // Get current price for an asset
  async getPrice(asset) {
    if (!this.pythContract) {
      throw new Error('Price feed contract not initialized');
    }

    try {
      const result = await this.pythContract.call('getPrice', [asset]);
      return {
        price: result[0],
        expo: result[1],
        publishTime: result[2]
      };
    } catch (error) {
      console.error(`Error getting price for ${asset}:`, error);
      throw error;
    }
  }

  // Get formatted price (18 decimals)
  async getPriceFormatted(asset) {
    if (!this.pythContract) {
      throw new Error('Price feed contract not initialized');
    }

    try {
      const result = await this.pythContract.call('getPriceFormatted', [asset]);
      return result;
    } catch (error) {
      console.error(`Error getting formatted price for ${asset}:`, error);
      throw error;
    }
  }

  // Get all supported assets
  async getSupportedAssets() {
    if (!this.pythContract) {
      throw new Error('Price feed contract not initialized');
    }

    try {
      const result = await this.pythContract.call('getSupportedAssets', []);
      return result;
    } catch (error) {
      console.error('Error getting supported assets:', error);
      throw error;
    }
  }

  // Calculate HBAR value for a given asset amount
  async calculateHbarValue(asset, amount) {
    if (!this.pythContract) {
      throw new Error('Price feed contract not initialized');
    }

    try {
      const result = await this.pythContract.call('calculateHbarValue', [asset, amount]);
      return result;
    } catch (error) {
      console.error(`Error calculating HBAR value for ${asset}:`, error);
      throw error;
    }
  }

  // Get price feed ID for an asset
  getPriceId(asset) {
    return PRICE_IDS[asset] || null;
  }

  // Format price with decimals
  formatPrice(price, expo) {
    if (expo >= 0) {
      return price * Math.pow(10, expo);
    } else {
      return price / Math.pow(10, Math.abs(expo));
    }
  }

  // Convert price to USD string
  formatPriceUSD(price, expo) {
    const formattedPrice = this.formatPrice(price, expo);
    return `$${formattedPrice.toFixed(2)}`;
  }
}

module.exports = PriceService;