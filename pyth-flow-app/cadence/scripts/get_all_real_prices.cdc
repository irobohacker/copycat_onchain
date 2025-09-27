import "PythIntegration"

// Script to get all REAL prices from Pyth Network
access(all) fun main(): {String: PythIntegration.PriceInfo?} {
    let supportedFeeds = PythIntegration.getSupportedFeeds()
    let result: {String: PythIntegration.PriceInfo?} = {}

    for feed in supportedFeeds {
        result[feed] = PythIntegration.getPrice(feedId: feed)
    }

    return result
}