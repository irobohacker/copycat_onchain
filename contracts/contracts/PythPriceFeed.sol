//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "./Topic.sol";

contract PythPriceFeed is Topic, UUPSUpgradeable {
    IPyth public pyth;

    // Price feed IDs for different assets
    mapping(string => bytes32) public priceIds;

    // Supported asset names
    string[] public supportedAssets;

    // Events
    event PriceFetched(string asset, uint256 price, int32 expo, uint256 timestamp);
    event AssetAdded(string asset, bytes32 priceId);

    // Errors
    error AssetNotSupported();
    error InvalidPriceData();
    error PriceUpdateFailed();

    function initializePythPriceFeed(
        string memory topicId,
        address _pyth
    ) public initializer {
        initialize(topicId);
        pyth = IPyth(_pyth);

        // Add default assets with their Pyth price feed IDs
        _addAsset("ETH/USD", 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace);
        _addAsset("SOL/USD", 0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8ed0c6c7bc0f4cfac8c280b56d);
        _addAsset("BTC/USD", 0xf9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b);
        _addAsset("HBAR/USD", 0x0000000000000000000000000000000000000000000000000000000000000001); // Placeholder - update with actual HBAR price ID
    }

    function _addAsset(string memory asset, bytes32 priceId) internal {
        priceIds[asset] = priceId;
        supportedAssets.push(asset);
        emit AssetAdded(asset, priceId);
    }

    function addAsset(string memory asset, bytes32 priceId) external {
        _addAsset(asset, priceId);
    }

    function getPrice(string memory asset) external view returns (uint256 price, int32 expo, uint256 publishTime) {
        bytes32 priceId = priceIds[asset];
        if (priceId == bytes32(0)) revert AssetNotSupported();

        PythStructs.Price memory priceData = pyth.getPrice(priceId);
        if (priceData.price <= 0) revert InvalidPriceData();

        return (uint256(uint64(priceData.price)), priceData.expo, priceData.publishTime);
    }

    function getPriceNoOlderThan(string memory asset, uint256 maxAge) external view returns (uint256 price, int32 expo, uint256 publishTime) {
        bytes32 priceId = priceIds[asset];
        if (priceId == bytes32(0)) revert AssetNotSupported();

        PythStructs.Price memory priceData = pyth.getPriceNoOlderThan(priceId, maxAge);
        if (priceData.price <= 0) revert InvalidPriceData();

        return (uint256(uint64(priceData.price)), priceData.expo, priceData.publishTime);
    }

    function getPriceFormatted(string memory asset) external view returns (uint256 formattedPrice) {
        bytes32 priceId = priceIds[asset];
        if (priceId == bytes32(0)) revert AssetNotSupported();

        PythStructs.Price memory priceData = pyth.getPrice(priceId);
        if (priceData.price <= 0) revert InvalidPriceData();

        // Convert price to 18 decimals format
        if (priceData.expo >= 0) {
            formattedPrice = uint256(uint64(priceData.price)) * (10 ** uint32(priceData.expo)) * (10 ** 18);
        } else {
            formattedPrice = (uint256(uint64(priceData.price)) * (10 ** 18)) / (10 ** uint32(-1 * priceData.expo));
        }

        return formattedPrice;
    }

    function updatePriceFeeds(bytes[] calldata priceUpdateData) external payable {
        uint256 updateFee = pyth.getUpdateFee(priceUpdateData);

        if (msg.value < updateFee) {
            revert PriceUpdateFailed();
        }

        pyth.updatePriceFeeds{value: updateFee}(priceUpdateData);

        // Return excess fee
        if (msg.value > updateFee) {
            payable(msg.sender).transfer(msg.value - updateFee);
        }

        // Emit events for all supported assets
        for (uint i = 0; i < supportedAssets.length; i++) {
            try this.getPrice(supportedAssets[i]) returns (uint256 price, int32 expo, uint256 publishTime) {
                emit PriceFetched(supportedAssets[i], price, expo, block.timestamp);
            } catch {
                // Price fetch failed for this asset, continue
            }
        }
    }

    function calculateHbarValue(string memory asset, uint256 assetAmount) external view returns (uint256 hbarValue) {
        uint256 assetPrice = this.getPriceFormatted(asset);
        uint256 hbarPrice = this.getPriceFormatted("HBAR/USD");

        // Calculate HBAR equivalent: (assetAmount * assetPrice) / hbarPrice
        hbarValue = (assetAmount * assetPrice) / hbarPrice;
        return hbarValue;
    }

    function getSupportedAssets() external view returns (string[] memory) {
        return supportedAssets;
    }

    function getPriceId(string memory asset) external view returns (bytes32) {
        return priceIds[asset];
    }

    // Required for UUPS upgrades
    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}