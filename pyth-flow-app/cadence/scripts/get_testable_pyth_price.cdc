import "TestablePythIntegration"

// Script to get price from testable Pyth integration (real format)
access(all) fun main(feedId: String): TestablePythIntegration.PriceInfo? {
    return TestablePythIntegration.getPrice(feedId: feedId)
}