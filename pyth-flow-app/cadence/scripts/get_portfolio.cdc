import "SocialTrading"

// Script to get portfolio performance for an address
access(all) fun main(address: Address): {String: UFix64}? {
    return SocialTrading.getPortfolioPerformance(address: address)
}