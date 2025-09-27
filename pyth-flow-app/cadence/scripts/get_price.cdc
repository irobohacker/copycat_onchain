import "PythPriceFeed"

// Script to get current price for an asset
access(all) fun main(feedId: String): PythPriceFeed.PriceData? {
    return PythPriceFeed.getLatestPrice(feedId: feedId)
}