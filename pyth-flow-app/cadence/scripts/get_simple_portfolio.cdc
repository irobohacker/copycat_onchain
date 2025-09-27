import "SimpleSocialTrading"

// Script to get simple portfolio performance for an address
access(all) fun main(address: Address): {String: UFix64}? {
    return SimpleSocialTrading.getPortfolioPerformance(address: address)
}