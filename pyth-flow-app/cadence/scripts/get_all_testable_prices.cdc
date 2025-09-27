import "TestablePythIntegration"

// Script to get all testable Pyth prices (real format)
access(all) fun main(): {String: TestablePythIntegration.PriceInfo?} {
    let supportedFeeds = TestablePythIntegration.getSupportedFeeds()
    let result: {String: TestablePythIntegration.PriceInfo?} = {}

    for feed in supportedFeeds {
        result[feed] = TestablePythIntegration.getPrice(feedId: feed)
    }

    return result
}