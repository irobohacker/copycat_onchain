import "PythPriceFeed"
import "FlowToken"
import "FungibleToken"

access(all) contract SocialTrading {

    // Events
    access(all) event PortfolioCreated(owner: Address, portfolioId: UInt64)
    access(all) event TradeExecuted(trader: Address, portfolioId: UInt64, asset: String, amount: UFix64, price: UFix64, action: String)
    access(all) event FollowTrader(follower: Address, following: Address)
    access(all) event UnfollowTrader(follower: Address, unfollowing: Address)
    access(all) event CopyTrade(copier: Address, original: Address, asset: String, amount: UFix64)
    access(all) event ActionCreated(actionId: String, creator: Address, actionType: String)
    access(all) event ActionExecuted(actionId: String, executor: Address, result: String)

    // Flow Action Types (FLIP-338)
    access(all) enum ActionType: UInt8 {
        access(all) case BUY
        access(all) case SELL
        access(all) case FOLLOW_TRADER
        access(all) case CREATE_PORTFOLIO
        access(all) case COPY_TRADE
    }

    // Portfolio holding structure
    access(all) struct AssetHolding {
        access(all) let asset: String
        access(all) var quantity: UFix64
        access(all) var avgBuyPrice: UFix64
        access(all) let firstPurchase: UFix64

        init(asset: String, quantity: UFix64, avgBuyPrice: UFix64) {
            self.asset = asset
            self.quantity = quantity
            self.avgBuyPrice = avgBuyPrice
            self.firstPurchase = UFix64(getCurrentBlock().timestamp)
        }

        access(all) fun updateHolding(newQuantity: UFix64, newAvgPrice: UFix64) {
            self.quantity = newQuantity
            self.avgBuyPrice = newAvgPrice
        }
    }

    // Flow Action struct (FLIP-338 implementation)
    access(all) struct FlowAction {
        access(all) let actionId: String
        access(all) let actionType: ActionType
        access(all) let creator: Address
        access(all) let timestamp: UFix64
        access(all) let parameters: {String: AnyStruct}
        access(all) var executed: Bool
        access(all) var executionResult: String?

        init(actionId: String, actionType: ActionType, creator: Address, parameters: {String: AnyStruct}) {
            self.actionId = actionId
            self.actionType = actionType
            self.creator = creator
            self.parameters = parameters
            self.timestamp = UFix64(getCurrentBlock().timestamp)
            self.executed = false
            self.executionResult = nil
        }

        access(all) fun markExecuted(result: String) {
            self.executed = true
            self.executionResult = result
        }
    }

    // Public interface for trading portfolio
    access(all) resource interface TradingPortfolioPublic {
        access(all) fun getPerformance(): {String: UFix64}
        access(all) fun addFollower(followerAddress: Address)
        access(all) fun removeFollower(followerAddress: Address)
        access(all) let portfolioId: UInt64
        access(all) fun getOwner(): Address
        access(all) var socialScore: UInt64
    }

    // Trading Portfolio Resource
    access(all) resource TradingPortfolio: TradingPortfolioPublic {
        access(all) let portfolioId: UInt64
        access(all) let owner: Address
        access(all) var holdings: {String: AssetHolding}
        access(all) var flowBalance: UFix64
        access(all) var totalValue: UFix64
        access(all) var socialScore: UInt64
        access(all) var followers: {Address: Bool}
        access(all) var following: {Address: Bool}
        access(all) var tradeHistory: [String]
        access(self) var pendingActions: {String: FlowAction}

        init(owner: Address) {
            self.portfolioId = self.uuid
            self.owner = owner
            self.holdings = {}
            self.flowBalance = 0.0
            self.totalValue = 0.0
            self.socialScore = 0
            self.followers = {}
            self.following = {}
            self.tradeHistory = []
            self.pendingActions = {}
        }

        // Flow Actions Implementation (FLIP-338)
        access(all) fun createAction(actionType: ActionType, parameters: {String: AnyStruct}): String {
            let actionId = "action_".concat(self.portfolioId.toString()).concat("_").concat(UFix64(getCurrentBlock().timestamp).toString())
            let action = FlowAction(
                actionId: actionId,
                actionType: actionType,
                creator: self.owner,
                parameters: parameters
            )
            self.pendingActions[actionId] = action
            emit ActionCreated(actionId: actionId, creator: self.owner, actionType: actionType.rawValue.toString())
            return actionId
        }

        access(all) fun executeAction(actionId: String): String {
            pre {
                self.pendingActions[actionId] != nil: "Action not found"
                !self.pendingActions[actionId]!.executed: "Action already executed"
            }

            let action = self.pendingActions[actionId]!
            var result = "failed"

            switch action.actionType {
                case ActionType.BUY:
                    if let asset = action.parameters["asset"] as? String {
                        if let amount = action.parameters["amount"] as? UFix64 {
                            result = self.executeBuyAction(asset: asset, amount: amount)
                        }
                    }
                case ActionType.SELL:
                    if let asset = action.parameters["asset"] as? String {
                        if let quantity = action.parameters["quantity"] as? UFix64 {
                            result = self.executeSellAction(asset: asset, quantity: quantity)
                        }
                    }
                case ActionType.FOLLOW_TRADER:
                    if let traderAddress = action.parameters["traderAddress"] as? Address {
                        result = self.executeFollowAction(traderAddress: traderAddress)
                    }
                case ActionType.CREATE_PORTFOLIO:
                    result = "portfolio_already_exists"
                case ActionType.COPY_TRADE:
                    if let originalTrader = action.parameters["originalTrader"] as? Address {
                        if let asset = action.parameters["asset"] as? String {
                            if let amount = action.parameters["amount"] as? UFix64 {
                                result = self.executeCopyTradeAction(originalTrader: originalTrader, asset: asset, amount: amount)
                            }
                        }
                    }
            }

            // Mark action as executed
            self.pendingActions[actionId]!.markExecuted(result: result)
            emit ActionExecuted(actionId: actionId, executor: self.owner, result: result)
            return result
        }

        // Execute buy action
        access(self) fun executeBuyAction(asset: String, amount: UFix64): String {
            let priceData = SocialTrading.getAssetPrice(asset: asset)
            if priceData == nil {
                return "price_not_available"
            }

            let price = priceData!.getFormattedPrice()
            let cost = amount * price

            if cost > self.flowBalance {
                return "insufficient_balance"
            }

            // Update balance and holdings
            self.flowBalance = self.flowBalance - cost

            if let existingHolding = self.holdings[asset] {
                let totalQuantity = existingHolding.quantity + amount
                let totalCost = (existingHolding.quantity * existingHolding.avgBuyPrice) + cost
                let newAvgPrice = totalCost / totalQuantity

                existingHolding.updateHolding(newQuantity: totalQuantity, newAvgPrice: newAvgPrice)
            } else {
                self.holdings[asset] = AssetHolding(asset: asset, quantity: amount, avgBuyPrice: price)
            }

            self.updateTotalValue()
            self.tradeHistory.append("BUY ".concat(amount.toString()).concat(" ").concat(asset).concat(" at ").concat(price.toString()))

            emit TradeExecuted(trader: self.owner, portfolioId: self.portfolioId, asset: asset, amount: amount, price: price, action: "BUY")
            return "success"
        }

        // Execute sell action
        access(self) fun executeSellAction(asset: String, quantity: UFix64): String {
            if let holding = self.holdings[asset] {
                if holding.quantity < quantity {
                    return "insufficient_quantity"
                }

                let priceData = SocialTrading.getAssetPrice(asset: asset)
                if priceData == nil {
                    return "price_not_available"
                }

                let price = priceData!.getFormattedPrice()
                let revenue = quantity * price

                // Update holdings and balance
                let newQuantity = holding.quantity - quantity
                if newQuantity == 0.0 {
                    self.holdings.remove(key: asset)
                } else {
                    holding.updateHolding(newQuantity: newQuantity, newAvgPrice: holding.avgBuyPrice)
                }

                self.flowBalance = self.flowBalance + revenue
                self.updateTotalValue()
                self.tradeHistory.append("SELL ".concat(quantity.toString()).concat(" ").concat(asset).concat(" at ").concat(price.toString()))

                emit TradeExecuted(trader: self.owner, portfolioId: self.portfolioId, asset: asset, amount: quantity, price: price, action: "SELL")
                return "success"
            }
            return "asset_not_held"
        }

        // Execute follow action
        access(self) fun executeFollowAction(traderAddress: Address): String {
            self.following[traderAddress] = true
            emit FollowTrader(follower: self.owner, following: traderAddress)
            return "success"
        }

        // Execute copy trade action
        access(self) fun executeCopyTradeAction(originalTrader: Address, asset: String, amount: UFix64): String {
            let result = self.executeBuyAction(asset: asset, amount: amount)
            if result == "success" {
                emit CopyTrade(copier: self.owner, original: originalTrader, asset: asset, amount: amount)
            }
            return result
        }

        // Add follower
        access(all) fun addFollower(followerAddress: Address) {
            self.followers[followerAddress] = true
            self.socialScore = self.socialScore + 1
        }

        // Remove follower
        access(all) fun removeFollower(followerAddress: Address) {
            self.followers.remove(key: followerAddress)
            if self.socialScore > 0 {
                self.socialScore = self.socialScore - 1
            }
        }

        // Deposit FLOW tokens (simplified)
        access(all) fun depositFlow(amount: UFix64) {
            self.flowBalance = self.flowBalance + amount
            self.updateTotalValue()
        }

        // Withdraw FLOW tokens (simplified)
        access(all) fun withdrawFlow(amount: UFix64): UFix64 {
            pre {
                amount <= self.flowBalance: "Insufficient balance"
            }
            self.flowBalance = self.flowBalance - amount
            self.updateTotalValue()
            return amount
        }

        // Update total portfolio value
        access(self) fun updateTotalValue() {
            var totalAssetValue = 0.0
            for asset in self.holdings.keys {
                if let holding = self.holdings[asset] {
                    if let priceData = SocialTrading.getAssetPrice(asset: asset) {
                        let currentPrice = priceData.getFormattedPrice()
                        totalAssetValue = totalAssetValue + (holding.quantity * currentPrice)
                    }
                }
            }
            self.totalValue = self.flowBalance + totalAssetValue
        }

        // Get portfolio performance
        access(all) fun getPerformance(): {String: UFix64} {
            self.updateTotalValue()
            return {
                "totalValue": self.totalValue,
                "flowBalance": self.flowBalance,
                "socialScore": UFix64(self.socialScore),
                "followersCount": UFix64(self.followers.length),
                "followingCount": UFix64(self.following.length)
            }
        }

        // Get holdings info
        access(all) fun getHoldings(): {String: AssetHolding} {
            return self.holdings
        }

        // Get trade history
        access(all) fun getTradeHistory(): [String] {
            return self.tradeHistory
        }

        // Get owner address (for interface compliance)
        access(all) fun getOwner(): Address {
            return self.owner
        }
    }

    // Storage paths
    access(all) let PortfolioStoragePath: StoragePath
    access(all) let PortfolioPublicPath: PublicPath

    // Contract state
    access(all) var totalPortfolios: UInt64

    // Create a new trading portfolio
    access(all) fun createPortfolio(owner: Address): @TradingPortfolio {
        let portfolio <- create TradingPortfolio(owner: owner)
        let portfolioId = portfolio.portfolioId
        self.totalPortfolios = self.totalPortfolios + 1
        emit PortfolioCreated(owner: owner, portfolioId: portfolioId)
        return <- portfolio
    }

    // Get asset price from Pyth feed
    access(all) fun getAssetPrice(asset: String): PythPriceFeed.PriceData? {
        return PythPriceFeed.getLatestPrice(feedId: asset)
    }

    // Get portfolio by address (public access)
    access(all) fun getPortfolioPerformance(address: Address): {String: UFix64}? {
        let account = getAccount(address)
        if let portfolioRef = account.capabilities.borrow<&{TradingPortfolioPublic}>(self.PortfolioPublicPath) {
            return portfolioRef.getPerformance()
        }
        return nil
    }

    // Get total number of portfolios
    access(all) fun getTotalPortfolios(): UInt64 {
        return self.totalPortfolios
    }

    init() {
        self.totalPortfolios = 0

        // Set storage paths
        self.PortfolioStoragePath = /storage/SocialTradingPortfolioV1
        self.PortfolioPublicPath = /public/SocialTradingPortfolioV1
    }
}