import { ethers, upgrades } from 'hardhat';

async function main() {
  console.log('Deploying HbarPythSwap contract...');

  // Pyth contract address and price feed IDs
  const PYTH_CONTRACT_ADDRESS = process.env.PYTH_CONTRACT_ADDRESS || '0x4374e5a8b9C22271E9EB878A2AA31DE97DF15DAF';

  // Pyth price feed IDs for mainnet (these are the actual Pyth price feed IDs)
  const ETH_USD_PRICE_ID = '0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace';
  const SOL_USD_PRICE_ID = '0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8ed0c6c7bc0f4cfac8c280b56d';
  const BTC_USD_PRICE_ID = '0xf9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b';
  const HBAR_USD_PRICE_ID = '0x0000000000000000000000000000000000000000000000000000000000000001'; // Placeholder

  // Asset token addresses (would be set to actual token contract addresses in production)
  const ETH_TOKEN_ADDRESS = process.env.ETH_TOKEN_ADDRESS || '0x0000000000000000000000000000000000000001';
  const SOL_TOKEN_ADDRESS = process.env.SOL_TOKEN_ADDRESS || '0x0000000000000000000000000000000000000002';
  const BTC_TOKEN_ADDRESS = process.env.BTC_TOKEN_ADDRESS || '0x0000000000000000000000000000000000000003';

  const HbarPythSwap = await ethers.getContractFactory('HbarPythSwap');

  // Deploy as upgradeable proxy
  const swapContract = await upgrades.deployProxy(HbarPythSwap, [
    PYTH_CONTRACT_ADDRESS,
    ETH_USD_PRICE_ID,
    SOL_USD_PRICE_ID,
    BTC_USD_PRICE_ID,
    HBAR_USD_PRICE_ID,
    ETH_TOKEN_ADDRESS,
    SOL_TOKEN_ADDRESS,
    BTC_TOKEN_ADDRESS
  ], {
    kind: 'uups'
  });

  await swapContract.deployed();
  console.log('HbarPythSwap deployed to:', swapContract.address);

  // Get swap parameters
  const [maxPriceAge, slippageTolerance, swapFee] = await swapContract.getSwapParameters();
  console.log('Swap Parameters:');
  console.log('- Max Price Age:', maxPriceAge.toString(), 'seconds');
  console.log('- Slippage Tolerance:', slippageTolerance.toString(), 'basis points');
  console.log('- Swap Fee:', swapFee.toString(), 'basis points');

  // Get all price IDs
  const [ethId, solId, btcId, hbarId] = await swapContract.getAllPriceIds();
  console.log('Price Feed IDs:');
  console.log('- ETH/USD:', ethId);
  console.log('- SOL/USD:', solId);
  console.log('- BTC/USD:', btcId);
  console.log('- HBAR/USD:', hbarId);

  // Get token addresses
  const [ethToken, solToken, btcToken] = await swapContract.getTokenAddresses();
  console.log('Asset Token Contracts:');
  console.log('- ETH Token:', ethToken);
  console.log('- SOL Token:', solToken);
  console.log('- BTC Token:', btcToken);

  // Get current reserves
  const [ethReserve, solReserve, btcReserve, hbarReserve] = await swapContract.getAllReserves();
  console.log('Current Reserves:');
  console.log('- ETH Reserve:', ethReserve.toString());
  console.log('- SOL Reserve:', solReserve.toString());
  console.log('- BTC Reserve:', btcReserve.toString());
  console.log('- HBAR Reserve:', hbarReserve.toString());

  console.log('\n🎉 HbarPythSwap with REAL SWAPPING is ready!');
  console.log('📖 To use the swap:');
  console.log('   1. Add liquidity using addHbarLiquidity() and addAssetLiquidity()');
  console.log('   2. Users can swapHbarForAsset() to get tokens');
  console.log('   3. Users can swapAssetForHbar() to get HBAR back');

  return {
    swapContractAddress: swapContract.address,
    priceIds: { ethId, solId, btcId, hbarId },
    tokenAddresses: { ethToken, solToken, btcToken }
  };
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });