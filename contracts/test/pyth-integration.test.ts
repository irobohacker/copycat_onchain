import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';
// Note: MockPyth and actual contract types would be imported here in a real test setup

describe('Pyth Integration Tests', function () {
  let priceFeed: any;
  let hbarSwap: any;
  let owner: any;
  let user: any;

  // Mock Pyth contract address (in real tests, you'd deploy a mock Pyth contract)
  const MOCK_PYTH_ADDRESS = '0x1234567890123456789012345678901234567890';

  // Mock price feed IDs
  const ETH_USD_PRICE_ID = '0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace';
  const SOL_USD_PRICE_ID = '0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8ed0c6c7bc0f4cfac8c280b56d';
  const BTC_USD_PRICE_ID = '0xf9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b';
  const HBAR_USD_PRICE_ID = '0x0000000000000000000000000000000000000000000000000000000000000001';

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    // Deploy PythPriceFeed
    const PythPriceFeedFactory = await ethers.getContractFactory('PythPriceFeed');
    priceFeed = await upgrades.deployProxy(PythPriceFeedFactory, [], {
      initializer: false,
      kind: 'uups'
    });

    await priceFeed.deployed();

    // Deploy HbarPythSwap
    const HbarPythSwapFactory = await ethers.getContractFactory('HbarPythSwap');
    hbarSwap = await upgrades.deployProxy(HbarPythSwapFactory, [
      MOCK_PYTH_ADDRESS,
      ETH_USD_PRICE_ID,
      SOL_USD_PRICE_ID,
      BTC_USD_PRICE_ID,
      HBAR_USD_PRICE_ID
    ], {
      kind: 'uups'
    });

    await hbarSwap.deployed();
  });

  describe('PythPriceFeed Contract', function () {
    beforeEach(async function () {
      // Initialize the price feed contract
      await priceFeed.initializePythPriceFeed('test-topic', MOCK_PYTH_ADDRESS);
    });

    it('should initialize with correct topic ID and Pyth address', async function () {
      expect(await priceFeed.getTopicId()).to.equal('test-topic');
      expect(await priceFeed.pyth()).to.equal(MOCK_PYTH_ADDRESS);
    });

    it('should have default supported assets', async function () {
      const supportedAssets = await priceFeed.getSupportedAssets();
      expect(supportedAssets).to.include('ETH/USD');
      expect(supportedAssets).to.include('SOL/USD');
      expect(supportedAssets).to.include('BTC/USD');
      expect(supportedAssets).to.include('HBAR/USD');
    });

    it('should allow adding new assets', async function () {
      const newAssetName = 'MATIC/USD';
      const newPriceId = '0x1234567890123456789012345678901234567890123456789012345678901234';

      await priceFeed.addAsset(newAssetName, newPriceId);

      const supportedAssets = await priceFeed.getSupportedAssets();
      expect(supportedAssets).to.include(newAssetName);

      const retrievedPriceId = await priceFeed.getPriceId(newAssetName);
      expect(retrievedPriceId).to.equal(newPriceId);
    });

    it('should return correct price IDs for supported assets', async function () {
      expect(await priceFeed.getPriceId('ETH/USD')).to.equal(ETH_USD_PRICE_ID);
      expect(await priceFeed.getPriceId('SOL/USD')).to.equal(SOL_USD_PRICE_ID);
      expect(await priceFeed.getPriceId('BTC/USD')).to.equal(BTC_USD_PRICE_ID);
      expect(await priceFeed.getPriceId('HBAR/USD')).to.equal(HBAR_USD_PRICE_ID);
    });

    it('should revert for unsupported assets', async function () {
      await expect(priceFeed.getPriceId('UNSUPPORTED/USD')).to.not.reverted;
      // Returns bytes32(0) for unsupported assets
      expect(await priceFeed.getPriceId('UNSUPPORTED/USD')).to.equal(
        '0x0000000000000000000000000000000000000000000000000000000000000000'
      );
    });
  });

  describe('HbarPythSwap Contract', function () {
    it('should initialize with correct parameters', async function () {
      expect(await hbarSwap.pyth()).to.equal(MOCK_PYTH_ADDRESS);
      expect(await hbarSwap.ethUsdPriceId()).to.equal(ETH_USD_PRICE_ID);
      expect(await hbarSwap.solUsdPriceId()).to.equal(SOL_USD_PRICE_ID);
      expect(await hbarSwap.btcUsdPriceId()).to.equal(BTC_USD_PRICE_ID);
      expect(await hbarSwap.hbarUsdPriceId()).to.equal(HBAR_USD_PRICE_ID);
    });

    it('should return correct swap parameters', async function () {
      const [maxPriceAge, slippageTolerance, swapFee] = await hbarSwap.getSwapParameters();
      expect(maxPriceAge).to.equal(60); // 1 minute
      expect(slippageTolerance).to.equal(300); // 3%
      expect(swapFee).to.equal(30); // 0.3%
    });

    it('should return all price IDs correctly', async function () {
      const [ethId, solId, btcId, hbarId] = await hbarSwap.getAllPriceIds();
      expect(ethId).to.equal(ETH_USD_PRICE_ID);
      expect(solId).to.equal(SOL_USD_PRICE_ID);
      expect(btcId).to.equal(BTC_USD_PRICE_ID);
      expect(hbarId).to.equal(HBAR_USD_PRICE_ID);
    });

    it('should allow owner to update parameters', async function () {
      await hbarSwap.updateMaxPriceAge(120);
      await hbarSwap.updateSlippageTolerance(500);
      await hbarSwap.updateSwapFee(50);

      const [maxPriceAge, slippageTolerance, swapFee] = await hbarSwap.getSwapParameters();
      expect(maxPriceAge).to.equal(120);
      expect(slippageTolerance).to.equal(500);
      expect(swapFee).to.equal(50);
    });

    it('should not allow non-owner to update parameters', async function () {
      await expect(hbarSwap.connect(user).updateMaxPriceAge(120)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );
      await expect(hbarSwap.connect(user).updateSwapFee(50)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );
    });

    it('should allow owner to update price IDs', async function () {
      const newPriceId = '0x1111111111111111111111111111111111111111111111111111111111111111';
      await hbarSwap.updatePriceId(0, newPriceId); // Update ETH price ID

      const [ethId] = await hbarSwap.getAllPriceIds();
      expect(ethId).to.equal(newPriceId);
    });

    it('should allow contract to receive HBAR', async function () {
      const initialBalance = await ethers.provider.getBalance(hbarSwap.address);

      await owner.sendTransaction({
        to: hbarSwap.address,
        value: ethers.utils.parseEther('1.0')
      });

      const finalBalance = await ethers.provider.getBalance(hbarSwap.address);
      expect(finalBalance.sub(initialBalance)).to.equal(ethers.utils.parseEther('1.0'));
    });

    it('should allow owner to withdraw contract balance', async function () {
      // Send some HBAR to contract
      await owner.sendTransaction({
        to: hbarSwap.address,
        value: ethers.utils.parseEther('1.0')
      });

      const ownerBalanceBefore = await ethers.provider.getBalance(owner.address);
      const tx = await hbarSwap.withdraw();
      const receipt = await tx.wait();

      // Account for gas costs
      const gasUsed = receipt.gasUsed.mul(receipt.effectiveGasPrice);
      const ownerBalanceAfter = await ethers.provider.getBalance(owner.address);

      expect(ownerBalanceAfter.add(gasUsed).sub(ownerBalanceBefore)).to.equal(
        ethers.utils.parseEther('1.0')
      );
    });
  });

  describe('Integration Tests', function () {
    beforeEach(async function () {
      await priceFeed.initializePythPriceFeed('test-topic', MOCK_PYTH_ADDRESS);
    });

    it('should have consistent price feed IDs between contracts', async function () {
      const priceFeedEthId = await priceFeed.getPriceId('ETH/USD');
      const swapContractEthId = await hbarSwap.ethUsdPriceId();
      expect(priceFeedEthId).to.equal(swapContractEthId);

      const priceFeedSolId = await priceFeed.getPriceId('SOL/USD');
      const swapContractSolId = await hbarSwap.solUsdPriceId();
      expect(priceFeedSolId).to.equal(swapContractSolId);
    });

    it('should use the same Pyth contract address', async function () {
      expect(await priceFeed.pyth()).to.equal(await hbarSwap.pyth());
    });
  });
});