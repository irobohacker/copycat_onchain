import "RealPythPriceFeed"

// Transaction to update real price data (simulates Pyth oracle update)
// In production, this would be called by actual Pyth oracle
transaction(feedId: String, price: UFix64, expo: Int32, confidence: UFix64) {

    prepare(signer: auth(Storage) &Account) {
        // Only contract owner can update prices
        // In production, only Pyth oracle would have this permission
    }

    execute {
        // Update price with current timestamp
        RealPythPriceFeed.updatePrice(
            feedId: feedId,
            price: price,
            expo: expo,
            confidence: confidence
        )

        log("Price updated for ".concat(feedId).concat(": ").concat(price.toString()))
    }
}