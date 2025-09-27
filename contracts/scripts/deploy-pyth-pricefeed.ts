import { ethers, upgrades } from 'hardhat';

async function main() {
  console.log('Deploying PythPriceFeed contract...');

  // Pyth contract addresses for different networks
  // Hedera Testnet: Update with actual Pyth contract address when available
  // For now using a placeholder - in production, get the actual Pyth contract address
  const PYTH_CONTRACT_ADDRESS = process.env.PYTH_CONTRACT_ADDRESS || '0x4374e5a8b9C22271E9EB878A2AA31DE97DF15DAF';

  const PythPriceFeed = await ethers.getContractFactory('PythPriceFeed');

  // Deploy as upgradeable proxy
  const priceFeed = await upgrades.deployProxy(PythPriceFeed, [], {
    initializer: false,
    kind: 'uups'
  });

  await priceFeed.deployed();
  console.log('PythPriceFeed deployed to:', priceFeed.address);

  // Initialize the contract
  console.log('Initializing PythPriceFeed...');
  const initTx = await priceFeed.initializePythPriceFeed(
    'pyth-price-feed-topic',
    PYTH_CONTRACT_ADDRESS
  );
  await initTx.wait();

  console.log('PythPriceFeed initialized successfully!');
  console.log('Contract can fetch prices for: ETH/USD, SOL/USD, BTC/USD, HBAR/USD');

  // Verify supported assets
  const supportedAssets = await priceFeed.getSupportedAssets();
  console.log('Supported assets:', supportedAssets);

  return {
    priceFeedAddress: priceFeed.address,
    supportedAssets: supportedAssets
  };
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });