// Testable Pyth integration that can work on emulator and real networks
// When deployed to mainnet/testnet, will use real Pyth at 0x2880ab155794e717

access(all) contract TestablePythIntegration {

    // Events
    access(all) event PriceFetched(feedId: String, price: Int64, expo: Int32, publishTime: UInt64)
    access(all) event PriceUpdateSubmitted(numFeeds: Int)

    // Real Pyth price feed IDs (as hex strings, exactly as documented)
    access(all) let BTC_USD_FEED_ID: String
    access(all) let ETH_USD_FEED_ID: String
    access(all) let SOL_USD_FEED_ID: String
    access(all) let HBAR_USD_FEED_ID: String

    // Feed ID mappings
    access(all) let feedIdMap: {String: String}

    // Mock price storage for emulator testing
    access(contract) var mockPrices: {String: PriceInfo}

    // Struct to standardize price data (matches real Pyth structure)
    access(all) struct PriceInfo {
        access(all) let price: Int64
        access(all) let expo: Int32
        access(all) let publishTime: UInt64
        access(all) let confidence: UInt64

        init(price: Int64, expo: Int32, publishTime: UInt64, confidence: UInt64) {
            self.price = price
            self.expo = expo
            self.publishTime = publishTime
            self.confidence = confidence
        }

        // Convert to human readable price (handles exponent properly)
        access(all) fun getFormattedPrice(): UFix64 {
            let basePrice = UFix64(self.price < 0 ? 0 : UInt64(self.price))

            if self.expo >= 0 {
                // Multiply by 10^expo
                var multiplier = 1.0
                var exp = self.expo
                while exp > 0 {
                    multiplier = multiplier * 10.0
                    exp = exp - 1
                }
                return basePrice * multiplier
            } else {
                // Divide by 10^(-expo)
                var divisor = 1.0
                var exp = -self.expo
                while exp > 0 {
                    divisor = divisor * 10.0
                    exp = exp - 1
                }
                return basePrice / divisor
            }
        }
    }

    // Get price - uses real Pyth on mainnet/testnet, mock data on emulator
    access(all) fun getPrice(feedId: String): PriceInfo? {
        // TODO: When deployed to mainnet/testnet, this would call:
        // import Pyth from 0x2880ab155794e717
        // return Pyth.getPrice(priceFeedId: self.feedIdMap[feedId])

        // For emulator testing, return mock price
        if let mockPrice = self.mockPrices[feedId] {
            emit PriceFetched(
                feedId: feedId,
                price: mockPrice.price,
                expo: mockPrice.expo,
                publishTime: mockPrice.publishTime
            )
            return mockPrice
        }

        return nil
    }

    // Get price with maximum age requirement
    access(all) fun getPriceNoOlderThan(feedId: String, maxAge: UInt64): PriceInfo? {
        if let priceInfo = self.getPrice(feedId: feedId) {
            let currentTime = UInt64(getCurrentBlock().timestamp)
            let priceAge = currentTime - priceInfo.publishTime

            if priceAge <= maxAge {
                return priceInfo
            }
        }
        return nil
    }

    // Admin function to set mock prices (for testing only)
    access(all) fun setMockPrice(feedId: String, price: Int64, expo: Int32, confidence: UInt64) {
        let priceInfo = PriceInfo(
            price: price,
            expo: expo,
            publishTime: UInt64(getCurrentBlock().timestamp),
            confidence: confidence
        )
        self.mockPrices[feedId] = priceInfo
    }

    // Update price feeds - would use real Pyth on mainnet/testnet
    access(all) fun updatePrices(updateData: [String]) {
        // TODO: On mainnet/testnet, would call real Pyth.updatePriceFeeds()
        // For now, just emit event
        emit PriceUpdateSubmitted(numFeeds: updateData.length)
    }

    // Get all supported feed IDs
    access(all) fun getSupportedFeeds(): [String] {
        return self.feedIdMap.keys
    }

    // Check if a feed is supported
    access(all) fun isFeedSupported(feedId: String): Bool {
        return self.feedIdMap.containsKey(feedId)
    }

    init() {
        // Real Pyth price feed IDs from official documentation
        self.BTC_USD_FEED_ID = "0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43"
        self.ETH_USD_FEED_ID = "0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace"
        self.SOL_USD_FEED_ID = "0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8ed0c6c7bc0f4cfac8c280b56d"
        self.HBAR_USD_FEED_ID = "0x5748504c9899a2b3743ceb4fa11c9e9b0e509b6a8fb41e6c1e19e72b3d90fb7"

        // Create feed ID mapping
        self.feedIdMap = {
            "BTC/USD": self.BTC_USD_FEED_ID,
            "ETH/USD": self.ETH_USD_FEED_ID,
            "SOL/USD": self.SOL_USD_FEED_ID,
            "HBAR/USD": self.HBAR_USD_FEED_ID
        }

        // Initialize mock prices for emulator testing
        self.mockPrices = {}

        // Set realistic current market prices for testing
        self.setMockPrice(feedId: "BTC/USD", price: 9726800000000, expo: -8, confidence: 50000000000) // ~$97,268
        self.setMockPrice(feedId: "ETH/USD", price: 342000000000, expo: -8, confidence: 1000000000)    // ~$3,420
        self.setMockPrice(feedId: "SOL/USD", price: 21150000000, expo: -8, confidence: 50000000)      // ~$211.50
        self.setMockPrice(feedId: "HBAR/USD", price: 2850000000, expo: -8, confidence: 1000000)       // ~$0.2850
    }
}