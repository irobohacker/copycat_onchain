//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract HbarPythSwap is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IPyth public pyth;

    // Price feed IDs for different assets
    bytes32 public ethUsdPriceId;
    bytes32 public solUsdPriceId;
    bytes32 public btcUsdPriceId;
    bytes32 public hbarUsdPriceId;

    // Asset token contracts
    IERC20Upgradeable public ethToken;
    IERC20Upgradeable public solToken;
    IERC20Upgradeable public btcToken;

    // Contract reserves for each asset
    mapping(Asset => uint256) public reserves;

    // Supported assets
    enum Asset { ETH, SOL, BTC, HBAR }

    // Swap configuration
    uint256 public maxPriceAge; // Maximum age of price data in seconds
    uint256 public slippageTolerance; // Basis points (e.g., 100 = 1%)
    uint256 public swapFee; // Basis points for swap fee

    // Events
    event SwapExecuted(
        address indexed user,
        Asset indexed fromAsset,
        Asset indexed toAsset,
        uint256 amountIn,
        uint256 amountOut,
        uint256 price,
        uint256 timestamp
    );

    event PriceUpdated(
        Asset indexed asset,
        uint256 price,
        uint256 timestamp
    );

    event LiquidityAdded(
        Asset indexed asset,
        uint256 amount,
        address indexed provider
    );

    event LiquidityRemoved(
        Asset indexed asset,
        uint256 amount,
        address indexed provider
    );

    // Errors
    error InvalidPriceData();
    error InsufficientBalance();
    error SlippageExceeded();
    error UnsupportedAsset();
    error PriceDataTooOld();
    error InvalidAmount();

    function initialize(
        address _pyth,
        bytes32 _ethUsdPriceId,
        bytes32 _solUsdPriceId,
        bytes32 _btcUsdPriceId,
        bytes32 _hbarUsdPriceId,
        address _ethToken,
        address _solToken,
        address _btcToken
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        pyth = IPyth(_pyth);
        ethUsdPriceId = _ethUsdPriceId;
        solUsdPriceId = _solUsdPriceId;
        btcUsdPriceId = _btcUsdPriceId;
        hbarUsdPriceId = _hbarUsdPriceId;

        // Set token contracts
        ethToken = IERC20Upgradeable(_ethToken);
        solToken = IERC20Upgradeable(_solToken);
        btcToken = IERC20Upgradeable(_btcToken);

        maxPriceAge = 60; // 1 minute
        slippageTolerance = 300; // 3%
        swapFee = 30; // 0.3%
    }

    function getPriceId(Asset asset) internal view returns (bytes32) {
        if (asset == Asset.ETH) return ethUsdPriceId;
        if (asset == Asset.SOL) return solUsdPriceId;
        if (asset == Asset.BTC) return btcUsdPriceId;
        if (asset == Asset.HBAR) return hbarUsdPriceId;
        revert UnsupportedAsset();
    }

    function getTokenContract(Asset asset) internal view returns (IERC20Upgradeable) {
        if (asset == Asset.ETH) return ethToken;
        if (asset == Asset.SOL) return solToken;
        if (asset == Asset.BTC) return btcToken;
        if (asset == Asset.HBAR) revert UnsupportedAsset(); // HBAR is native
        revert UnsupportedAsset();
    }

    function getAssetPrice(Asset asset) public view returns (uint256, int32) {
        bytes32 priceId = getPriceId(asset);
        PythStructs.Price memory price = pyth.getPriceNoOlderThan(priceId, maxPriceAge);

        if (price.price <= 0) {
            revert InvalidPriceData();
        }

        // Convert price to 18 decimals
        uint256 price18Decimals;
        if (price.expo >= 0) {
            price18Decimals = uint256(uint64(price.price)) * (10 ** uint32(price.expo)) * (10 ** 18);
        } else {
            price18Decimals = (uint256(uint64(price.price)) * (10 ** 18)) / (10 ** uint32(-1 * price.expo));
        }

        return (price18Decimals, price.expo);
    }

    function getAssetPriceUnsafe(Asset asset) public view returns (uint256, int32) {
        bytes32 priceId = getPriceId(asset);
        PythStructs.Price memory price = pyth.getPrice(priceId);

        if (price.price <= 0) {
            revert InvalidPriceData();
        }

        // Convert price to 18 decimals
        uint256 price18Decimals;
        if (price.expo >= 0) {
            price18Decimals = uint256(uint64(price.price)) * (10 ** uint32(price.expo)) * (10 ** 18);
        } else {
            price18Decimals = (uint256(uint64(price.price)) * (10 ** 18)) / (10 ** uint32(-1 * price.expo));
        }

        return (price18Decimals, price.expo);
    }

    function calculateSwapOutput(
        Asset fromAsset,
        Asset toAsset,
        uint256 amountIn
    ) public view returns (uint256 amountOut, uint256 fromPrice, uint256 toPrice) {
        if (amountIn == 0) revert InvalidAmount();

        (fromPrice,) = getAssetPrice(fromAsset);
        (toPrice,) = getAssetPrice(toAsset);

        // Calculate swap amount: (amountIn * fromPrice) / toPrice
        uint256 valueInUsd = (amountIn * fromPrice) / (10 ** 18);
        amountOut = (valueInUsd * (10 ** 18)) / toPrice;

        // Apply swap fee
        uint256 fee = (amountOut * swapFee) / 10000;
        amountOut = amountOut - fee;
    }

    function swapHbarForAsset(Asset toAsset) external payable nonReentrant {
        if (msg.value == 0) revert InvalidAmount();
        if (toAsset == Asset.HBAR) revert UnsupportedAsset();

        (uint256 amountOut, uint256 hbarPrice, uint256 toPrice) = calculateSwapOutput(
            Asset.HBAR,
            toAsset,
            msg.value
        );

        // Check if we have enough reserves
        if (reserves[toAsset] < amountOut) revert InsufficientBalance();

        // Update reserves
        reserves[Asset.HBAR] += msg.value;
        reserves[toAsset] -= amountOut;

        // Transfer tokens to user
        IERC20Upgradeable tokenContract = getTokenContract(toAsset);
        tokenContract.safeTransfer(msg.sender, amountOut);

        emit SwapExecuted(
            msg.sender,
            Asset.HBAR,
            toAsset,
            msg.value,
            amountOut,
            toPrice,
            block.timestamp
        );
    }

    function swapAssetForHbar(
        Asset fromAsset,
        uint256 amountIn,
        uint256 minHbarOut
    ) external nonReentrant {
        if (amountIn == 0) revert InvalidAmount();
        if (fromAsset == Asset.HBAR) revert UnsupportedAsset();

        (uint256 amountOut, uint256 fromPrice, uint256 hbarPrice) = calculateSwapOutput(
            fromAsset,
            Asset.HBAR,
            amountIn
        );

        if (amountOut < minHbarOut) revert SlippageExceeded();

        // Check if we have enough HBAR reserves
        if (reserves[Asset.HBAR] < amountOut) revert InsufficientBalance();

        // Transfer tokens from user to contract
        IERC20Upgradeable tokenContract = getTokenContract(fromAsset);
        tokenContract.safeTransferFrom(msg.sender, address(this), amountIn);

        // Update reserves
        reserves[fromAsset] += amountIn;
        reserves[Asset.HBAR] -= amountOut;

        // Send HBAR to user
        payable(msg.sender).transfer(amountOut);

        emit SwapExecuted(
            msg.sender,
            fromAsset,
            Asset.HBAR,
            amountIn,
            amountOut,
            hbarPrice,
            block.timestamp
        );
    }

    function updatePriceFeeds(bytes[] calldata priceUpdateData) external payable {
        uint256 updateFee = pyth.getUpdateFee(priceUpdateData);

        if (msg.value < updateFee) {
            revert InsufficientBalance();
        }

        pyth.updatePriceFeeds{value: updateFee}(priceUpdateData);

        // Emit events for updated prices
        for (uint i = 0; i < 4; i++) {
            Asset asset = Asset(i);
            try this.getAssetPriceUnsafe(asset) returns (uint256 price, int32) {
                emit PriceUpdated(asset, price, block.timestamp);
            } catch {
                // Price update failed for this asset, continue
            }
        }

        // Return excess fee
        if (msg.value > updateFee) {
            payable(msg.sender).transfer(msg.value - updateFee);
        }
    }

    function updateAndSwapHbarForAsset(
        bytes[] calldata priceUpdateData,
        Asset toAsset
    ) external payable nonReentrant {
        uint256 updateFee = pyth.getUpdateFee(priceUpdateData);

        if (msg.value <= updateFee) revert InsufficientBalance();

        // Update price feeds
        pyth.updatePriceFeeds{value: updateFee}(priceUpdateData);

        // Calculate swap with remaining value
        uint256 swapAmount = msg.value - updateFee;
        (uint256 amountOut, uint256 hbarPrice, uint256 toPrice) = calculateSwapOutput(
            Asset.HBAR,
            toAsset,
            swapAmount
        );

        emit SwapExecuted(
            msg.sender,
            Asset.HBAR,
            toAsset,
            swapAmount,
            amountOut,
            toPrice,
            block.timestamp
        );
    }

    // Liquidity management functions
    function addHbarLiquidity() external payable onlyOwner {
        reserves[Asset.HBAR] += msg.value;
        emit LiquidityAdded(Asset.HBAR, msg.value, msg.sender);
    }

    function addAssetLiquidity(Asset asset, uint256 amount) external onlyOwner {
        if (asset == Asset.HBAR) revert UnsupportedAsset();

        IERC20Upgradeable tokenContract = getTokenContract(asset);
        tokenContract.safeTransferFrom(msg.sender, address(this), amount);

        reserves[asset] += amount;
        emit LiquidityAdded(asset, amount, msg.sender);
    }

    function removeLiquidity(Asset asset, uint256 amount) external onlyOwner {
        if (reserves[asset] < amount) revert InsufficientBalance();

        reserves[asset] -= amount;

        if (asset == Asset.HBAR) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20Upgradeable tokenContract = getTokenContract(asset);
            tokenContract.safeTransfer(msg.sender, amount);
        }

        emit LiquidityRemoved(asset, amount, msg.sender);
    }

    // Admin functions
    function updateMaxPriceAge(uint256 _maxPriceAge) external onlyOwner {
        maxPriceAge = _maxPriceAge;
    }

    function updateSlippageTolerance(uint256 _slippageTolerance) external onlyOwner {
        slippageTolerance = _slippageTolerance;
    }

    function updateSwapFee(uint256 _swapFee) external onlyOwner {
        swapFee = _swapFee;
    }

    function updatePriceId(Asset asset, bytes32 newPriceId) external onlyOwner {
        if (asset == Asset.ETH) ethUsdPriceId = newPriceId;
        else if (asset == Asset.SOL) solUsdPriceId = newPriceId;
        else if (asset == Asset.BTC) btcUsdPriceId = newPriceId;
        else if (asset == Asset.HBAR) hbarUsdPriceId = newPriceId;
        else revert UnsupportedAsset();
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // View functions
    function getSwapParameters() external view returns (uint256, uint256, uint256) {
        return (maxPriceAge, slippageTolerance, swapFee);
    }

    function getAllPriceIds() external view returns (bytes32, bytes32, bytes32, bytes32) {
        return (ethUsdPriceId, solUsdPriceId, btcUsdPriceId, hbarUsdPriceId);
    }

    function getReserve(Asset asset) external view returns (uint256) {
        return reserves[asset];
    }

    function getAllReserves() external view returns (uint256, uint256, uint256, uint256) {
        return (reserves[Asset.ETH], reserves[Asset.SOL], reserves[Asset.BTC], reserves[Asset.HBAR]);
    }

    function getTokenAddresses() external view returns (address, address, address) {
        return (address(ethToken), address(solToken), address(btcToken));
    }

    receive() external payable {}

    // Required for UUPS upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}