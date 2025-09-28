// contracts.js - Contract addresses and ABIs for Hedera AI Agent

// Contract addresses from deployment
const CONTRACT_ADDRESSES = {
  PYTH_PRICE_FEED: "0xa2aa501b19aff244d90cc15a4cf739d2725b5729", // Hedera testnet
  HBAR_PYTH_SWAP: "", // To be deployed
  PROFITABLE_SAUCER_SWAP: "", // To be deployed
  SWAP_LOTTERY: "", // To be deployed
  COPYCAT_LOTTERY: "", // To be deployed
};

// Asset enum mapping
const ASSETS = {
  ETH: 0,
  SOL: 1,
  BTC: 2,
  HBAR: 3
};

// Pyth price feed IDs - Update these with actual IDs
const PRICE_IDS = {
  "ETH/USD": "0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace",
  "SOL/USD": "0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8ed0c6c7bc0f4cfac8c280b56d",
  "BTC/USD": "0xf9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b",
  "HBAR/USD": "0x0000000000000000000000000000000000000000000000000000000000000001" // TODO: Update with actual HBAR price feed ID
};

// Simplified contract ABIs for key functions
const CONTRACT_ABIS = {
  PythPriceFeed: [
    "function getPrice(string memory asset) external view returns (uint256 price, int32 expo, uint256 publishTime)",
    "function getPriceFormatted(string memory asset) external view returns (uint256 formattedPrice)",
    "function getSupportedAssets() external view returns (string[] memory)",
    "function updatePriceFeeds(bytes[] calldata priceUpdateData) external payable",
    "function calculateHbarValue(string memory asset, uint256 assetAmount) external view returns (uint256 hbarValue)"
  ],

  HbarPythSwap: [
    "function swapHbarForAsset(uint8 toAsset) external payable",
    "function swapAssetForHbar(uint8 fromAsset, uint256 amountIn, uint256 minHbarOut) external",
    "function calculateSwapOutput(uint8 fromAsset, uint8 toAsset, uint256 amountIn) public view returns (uint256 amountOut, uint256 fromPrice, uint256 toPrice)",
    "function getAssetPrice(uint8 asset) public view returns (uint256, int32)",
    "function getReserve(uint8 asset) external view returns (uint256)",
    "function getAllReserves() external view returns (uint256, uint256, uint256, uint256)",
    "function updatePriceFeeds(bytes[] calldata priceUpdateData) external payable"
  ]
};

module.exports = {
  CONTRACT_ADDRESSES,
  ASSETS,
  PRICE_IDS,
  CONTRACT_ABIS
};