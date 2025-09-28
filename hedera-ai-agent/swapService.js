// swapService.js - Swap service for Hedera AI Agent

const { Contract, Hbar } = require('@hashgraph/sdk');
const { CONTRACT_ADDRESSES, CONTRACT_ABIS, ASSETS } = require('./contracts');

class SwapService {
  constructor(client) {
    this.client = client;
    this.swapContract = null;
  }

  // Initialize the swap contract
  async initialize() {
    if (CONTRACT_ADDRESSES.HBAR_PYTH_SWAP) {
      this.swapContract = new Contract({
        contractId: CONTRACT_ADDRESSES.HBAR_PYTH_SWAP,
        abi: CONTRACT_ABIS.HbarPythSwap
      });
    }
  }

  // Get asset price
  async getAssetPrice(asset) {
    if (!this.swapContract) {
      throw new Error('Swap contract not initialized');
    }

    try {
      const assetEnum = ASSETS[asset.toUpperCase()];
      if (assetEnum === undefined) {
        throw new Error(`Unsupported asset: ${asset}`);
      }

      const result = await this.swapContract.call('getAssetPrice', [assetEnum]);
      return {
        price: result[0],
        expo: result[1]
      };
    } catch (error) {
      console.error(`Error getting asset price for ${asset}:`, error);
      throw error;
    }
  }

  // Calculate swap output
  async calculateSwapOutput(fromAsset, toAsset, amountIn) {
    if (!this.swapContract) {
      throw new Error('Swap contract not initialized');
    }

    try {
      const fromAssetEnum = ASSETS[fromAsset.toUpperCase()];
      const toAssetEnum = ASSETS[toAsset.toUpperCase()];

      if (fromAssetEnum === undefined || toAssetEnum === undefined) {
        throw new Error(`Unsupported asset: ${fromAsset} or ${toAsset}`);
      }

      const result = await this.swapContract.call('calculateSwapOutput', [
        fromAssetEnum,
        toAssetEnum,
        amountIn
      ]);

      return {
        amountOut: result[0],
        fromPrice: result[1],
        toPrice: result[2]
      };
    } catch (error) {
      console.error(`Error calculating swap output:`, error);
      throw error;
    }
  }

  // Swap HBAR for asset
  async swapHbarForAsset(toAsset, hbarAmount) {
    if (!this.swapContract) {
      throw new Error('Swap contract not initialized');
    }

    try {
      const toAssetEnum = ASSETS[toAsset.toUpperCase()];
      if (toAssetEnum === undefined) {
        throw new Error(`Unsupported asset: ${toAsset}`);
      }

      const transaction = await this.swapContract.execute('swapHbarForAsset', [toAssetEnum], {
        value: Hbar.fromTinybars(hbarAmount)
      });

      const receipt = await transaction.getReceipt(this.client);
      return {
        transactionId: transaction.transactionId.toString(),
        status: receipt.status.toString()
      };
    } catch (error) {
      console.error(`Error swapping HBAR for ${toAsset}:`, error);
      throw error;
    }
  }

  // Swap asset for HBAR
  async swapAssetForHbar(fromAsset, amountIn, minHbarOut) {
    if (!this.swapContract) {
      throw new Error('Swap contract not initialized');
    }

    try {
      const fromAssetEnum = ASSETS[fromAsset.toUpperCase()];
      if (fromAssetEnum === undefined) {
        throw new Error(`Unsupported asset: ${fromAsset}`);
      }

      const transaction = await this.swapContract.execute('swapAssetForHbar', [
        fromAssetEnum,
        amountIn,
        minHbarOut
      ]);

      const receipt = await transaction.getReceipt(this.client);
      return {
        transactionId: transaction.transactionId.toString(),
        status: receipt.status.toString()
      };
    } catch (error) {
      console.error(`Error swapping ${fromAsset} for HBAR:`, error);
      throw error;
    }
  }

  // Get reserves for all assets
  async getAllReserves() {
    if (!this.swapContract) {
      throw new Error('Swap contract not initialized');
    }

    try {
      const result = await this.swapContract.call('getAllReserves', []);
      return {
        ETH: result[0],
        SOL: result[1],
        BTC: result[2],
        HBAR: result[3]
      };
    } catch (error) {
      console.error('Error getting reserves:', error);
      throw error;
    }
  }

  // Get reserve for specific asset
  async getReserve(asset) {
    if (!this.swapContract) {
      throw new Error('Swap contract not initialized');
    }

    try {
      const assetEnum = ASSETS[asset.toUpperCase()];
      if (assetEnum === undefined) {
        throw new Error(`Unsupported asset: ${asset}`);
      }

      const result = await this.swapContract.call('getReserve', [assetEnum]);
      return result;
    } catch (error) {
      console.error(`Error getting reserve for ${asset}:`, error);
      throw error;
    }
  }

  // Format swap output for display
  formatSwapOutput(output) {
    return {
      amountOut: output.amountOut.toString(),
      fromPrice: this.formatPrice(output.fromPrice),
      toPrice: this.formatPrice(output.toPrice)
    };
  }

  // Format price for display
  formatPrice(price) {
    // Assuming 18 decimal places
    return (price / Math.pow(10, 18)).toFixed(6);
  }
}

module.exports = SwapService;