import "PythPriceFeed"

// Script to get all available price feeds
access(all) fun main(): {String: PythPriceFeed.PriceData?} {
    let feeds = ["BTC/USD", "ETH/USD", "SOL/USD", "FLOW/USD", "HBAR/USD"]
    let result: {String: PythPriceFeed.PriceData?} = {}

    for feed in feeds {
        result[feed] = PythPriceFeed.getLatestPrice(feedId: feed)
    }

    return result
}