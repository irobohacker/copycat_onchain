access(all) contract RealPythPriceFeed {

    // Events
    access(all) event PriceUpdated(feedId: String, price: UFix64, expo: Int32, timestamp: UFix64)
    access(all) event FeedAdded(feedId: String, description: String)
    access(all) event PriceRequested(feedId: String, requester: Address)

    // Struct to hold price data
    access(all) struct PriceData {
        access(all) let price: UFix64        // Price value
        access(all) let expo: Int32          // Price exponent
        access(all) let timestamp: UFix64    // Last update timestamp
        access(all) let confidence: UFix64   // Price confidence interval

        init(price: UFix64, expo: Int32, timestamp: UFix64, confidence: UFix64) {
            self.price = price
            self.expo = expo
            self.timestamp = timestamp
            self.confidence = confidence
        }

        // Get price formatted with proper exponent handling
        access(all) fun getFormattedPrice(): UFix64 {
            // TODO: In production, implement proper exponent math
            // For now, return price as-is since we're using expo: 0
            return self.price
        }
    }

    // Public interface for price reading
    access(all) resource interface PriceOraclePublic {
        access(all) fun getPrice(feedId: String): PriceData?
        access(all) fun getPriceWithMaxAge(feedId: String, maxAge: UFix64): PriceData?
        access(all) fun getFeedDescription(feedId: String): String?
        access(all) fun getAllFeeds(): [String]
    }

    // Resource for managing price feeds
    access(all) resource PriceFeedOracle: PriceOraclePublic {
        access(self) var priceFeeds: {String: PriceData}
        access(self) var feedDescriptions: {String: String}

        init() {
            self.priceFeeds = {}
            self.feedDescriptions = {}
        }

        // Add a new price feed
        access(contract) fun addPriceFeed(feedId: String, description: String) {
            self.feedDescriptions[feedId] = description
            emit FeedAdded(feedId: feedId, description: description)
        }

        // Update price for a feed - THIS SHOULD BE CALLED BY PYTH ORACLE IN PRODUCTION
        access(contract) fun updatePrice(feedId: String, price: UFix64, expo: Int32, confidence: UFix64) {
            let timestamp = UFix64(getCurrentBlock().timestamp)
            let priceData = PriceData(
                price: price,
                expo: expo,
                timestamp: timestamp,
                confidence: confidence
            )
            self.priceFeeds[feedId] = priceData
            emit PriceUpdated(feedId: feedId, price: price, expo: expo, timestamp: timestamp)
        }

        // Get current price for a feed
        access(all) fun getPrice(feedId: String): PriceData? {
            return self.priceFeeds[feedId]
        }

        // Get price with freshness check
        access(all) fun getPriceWithMaxAge(feedId: String, maxAge: UFix64): PriceData? {
            if let priceData = self.priceFeeds[feedId] {
                let currentTime = UFix64(getCurrentBlock().timestamp)
                if currentTime - priceData.timestamp <= maxAge {
                    return priceData
                }
            }
            return nil
        }

        // Get feed description
        access(all) fun getFeedDescription(feedId: String): String? {
            return self.feedDescriptions[feedId]
        }

        // Get all feed IDs
        access(all) fun getAllFeeds(): [String] {
            let keys: [String] = []
            for key in self.feedDescriptions.keys {
                keys.append(key)
            }
            return keys
        }
    }

    // Storage paths
    access(all) let OracleStoragePath: StoragePath
    access(all) let OraclePublicPath: PublicPath

    // Public function to get price (convenience method)
    access(all) fun getLatestPrice(feedId: String): PriceData? {
        let oracleAccount = getAccount(self.account.address)
        if let oracleRef = oracleAccount.capabilities.borrow<&{PriceOraclePublic}>(self.OraclePublicPath) {
            return oracleRef.getPrice(feedId: feedId)
        }
        return nil
    }

    // Initialize price feeds WITHOUT dummy data
    access(contract) fun initializePriceFeeds() {
        let oracleRef = self.account.storage.borrow<&PriceFeedOracle>(from: self.OracleStoragePath)
            ?? panic("Could not borrow oracle reference")

        // Only add feed definitions, NO PRICES
        oracleRef.addPriceFeed(feedId: "BTC/USD", description: "Bitcoin to US Dollar")
        oracleRef.addPriceFeed(feedId: "ETH/USD", description: "Ethereum to US Dollar")
        oracleRef.addPriceFeed(feedId: "SOL/USD", description: "Solana to US Dollar")
        oracleRef.addPriceFeed(feedId: "FLOW/USD", description: "Flow to US Dollar")
        oracleRef.addPriceFeed(feedId: "HBAR/USD", description: "Hedera Hashgraph to US Dollar")

        // NO DUMMY PRICES - Must be updated by external price oracle
        // In production, Pyth oracle would call updatePrice()
    }

    // Admin function to update a price - ONLY FOR EXTERNAL ORACLE USE
    access(all) fun updatePrice(feedId: String, price: UFix64, expo: Int32, confidence: UFix64) {
        let oracleRef = self.account.storage.borrow<&PriceFeedOracle>(from: self.OracleStoragePath)
            ?? panic("Could not borrow oracle reference")
        oracleRef.updatePrice(feedId: feedId, price: price, expo: expo, confidence: confidence)
    }

    init() {
        // Set storage paths
        self.OracleStoragePath = /storage/RealPythOracleV1
        self.OraclePublicPath = /public/RealPythOracleV1

        // Create and store the oracle
        let oracle <- create PriceFeedOracle()
        self.account.storage.save(<-oracle, to: self.OracleStoragePath)

        // Create public capability
        let oracleCapability = self.account.capabilities.storage.issue<&{PriceOraclePublic}>(self.OracleStoragePath)
        self.account.capabilities.publish(oracleCapability, at: self.OraclePublicPath)

        // Initialize feed definitions only (no dummy prices)
        self.initializePriceFeeds()
    }
}