import "PythIntegration"

// Script to get REAL price from actual Pyth Network contract
access(all) fun main(feedId: String): PythIntegration.PriceInfo? {
    return PythIntegration.getPrice(feedId: feedId)
}