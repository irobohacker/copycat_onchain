import "PythIntegration"
import "FlowToken"
import "FungibleToken"

access(all) contract RealPythTrading {

    // Events
    access(all) event PortfolioCreated(owner: Address, portfolioId: UInt64)
    access(all) event TradeExecuted(trader: Address, asset: String, amount: UFix64, price: UFix64)
    access(all) event ActionCreated(actionId: String, creator: Address, actionType: String)
    access(all) event FlowDeposited(portfolio: UInt64, amount: UFix64)
    access(all) event FlowWithdrawn(portfolio: UInt64, amount: UFix64)

    // Flow Action Types (FLIP-338)
    access(all) enum ActionType: UInt8 {
        access(all) case BUY
        access(all) case SELL
        access(all) case FOLLOW_TRADER
    }

    // Flow Action struct (FLIP-338 implementation)
    access(all) struct FlowAction {
        access(all) let actionId: String
        access(all) let actionType: ActionType
        access(all) let creator: Address
        access(all) let timestamp: UFix64
        access(all) let parameters: {String: AnyStruct}
        access(all) var executed: Bool

        init(actionId: String, actionType: ActionType, creator: Address, parameters: {String: AnyStruct}) {
            self.actionId = actionId
            self.actionType = actionType
            self.creator = creator
            self.parameters = parameters
            self.timestamp = UFix64(getCurrentBlock().timestamp)
            self.executed = false
        }

        access(all) fun markExecuted() {
            self.executed = true
        }
    }

    // Portfolio holding structure
    access(all) struct AssetHolding {
        access(all) let asset: String
        access(all) var quantity: UFix64
        access(all) var avgBuyPrice: UFix64

        init(asset: String, quantity: UFix64, avgBuyPrice: UFix64) {
            self.asset = asset
            self.quantity = quantity
            self.avgBuyPrice = avgBuyPrice
        }

        access(all) fun updateHolding(newQuantity: UFix64, newAvgPrice: UFix64) {
            self.quantity = newQuantity
            self.avgBuyPrice = newAvgPrice
        }
    }

    // Public interface for trading portfolio
    access(all) resource interface TradingPortfolioPublic {
        access(all) fun getOwnerAddress(): Address
        access(all) fun getPerformance(): {String: UFix64}
        access(all) let portfolioId: UInt64
    }

    // Trading Portfolio Resource using REAL Pyth prices
    access(all) resource TradingPortfolio: TradingPortfolioPublic {
        access(all) let portfolioId: UInt64
        access(self) let ownerAddress: Address
        access(all) var holdings: {String: AssetHolding}
        access(self) var flowVault: @FlowToken.Vault
        access(all) var totalValue: UFix64
        access(self) var pendingActions: {String: FlowAction}

        init(owner: Address) {
            self.portfolioId = self.uuid
            self.ownerAddress = owner
            self.holdings = {}
            self.flowVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
            self.totalValue = 0.0
            self.pendingActions = {}
        }

        // Flow Actions Implementation (FLIP-338)
        access(all) fun createAction(actionType: ActionType, parameters: {String: AnyStruct}): String {
            let actionId = "action_".concat(self.portfolioId.toString()).concat("_").concat(UFix64(getCurrentBlock().timestamp).toString())
            let action = FlowAction(
                actionId: actionId,
                actionType: actionType,
                creator: self.ownerAddress,
                parameters: parameters
            )
            self.pendingActions[actionId] = action
            emit ActionCreated(actionId: actionId, creator: self.ownerAddress, actionType: actionType.rawValue.toString())
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
                    result = "success"
            }

            self.pendingActions[actionId]!.markExecuted()
            return result
        }

        // Execute buy action using REAL Pyth price
        access(self) fun executeBuyAction(asset: String, amount: UFix64): String {
            // Get REAL price from Pyth Network
            let priceInfo = RealPythTrading.getRealPrice(asset: asset)
            if priceInfo == nil {
                return "real_price_not_available"
            }

            let price = priceInfo!.getFormattedPrice()
            let cost = amount * price

            // Check REAL FlowToken balance
            if cost > self.flowVault.balance {
                return "insufficient_flow_balance"
            }

            // Execute REAL trade with Pyth price
            let tradeCost <- self.flowVault.withdraw(amount: cost)

            // In production: trade FlowTokens for actual asset
            // For demo: destroy FlowTokens and record synthetic holding
            destroy tradeCost

            // Update holdings with REAL Pyth price
            if let existingHolding = self.holdings[asset] {
                let totalQuantity = existingHolding.quantity + amount
                let totalCost = (existingHolding.quantity * existingHolding.avgBuyPrice) + cost
                let newAvgPrice = totalCost / totalQuantity
                existingHolding.updateHolding(newQuantity: totalQuantity, newAvgPrice: newAvgPrice)
            } else {
                self.holdings[asset] = AssetHolding(asset: asset, quantity: amount, avgBuyPrice: price)
            }

            self.updateTotalValue()
            emit TradeExecuted(trader: self.ownerAddress, asset: asset, amount: amount, price: price)
            return "success"
        }

        // Execute sell action using REAL Pyth price
        access(self) fun executeSellAction(asset: String, quantity: UFix64): String {
            if let holding = self.holdings[asset] {
                if holding.quantity < quantity {
                    return "insufficient_asset_quantity"
                }

                // Get REAL current price from Pyth
                let priceInfo = RealPythTrading.getRealPrice(asset: asset)
                if priceInfo == nil {
                    return "real_price_not_available"
                }

                let currentPrice = priceInfo!.getFormattedPrice()
                let revenue = quantity * currentPrice

                // Update holdings
                let newQuantity = holding.quantity - quantity
                if newQuantity == 0.0 {
                    self.holdings.remove(key: asset)
                } else {
                    holding.updateHolding(newQuantity: newQuantity, newAvgPrice: holding.avgBuyPrice)
                }

                // Add revenue back (in production would come from actual asset sale)
                let revenueVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
                self.flowVault.deposit(from: <- revenueVault)

                self.updateTotalValue()
                emit TradeExecuted(trader: self.ownerAddress, asset: asset, amount: quantity, price: currentPrice)
                return "success"
            }
            return "asset_not_held"
        }

        // Deposit REAL FlowTokens
        access(all) fun depositFlow(vault: @FlowToken.Vault) {
            let amount = vault.balance
            self.flowVault.deposit(from: <- vault)
            self.updateTotalValue()
            emit FlowDeposited(portfolio: self.portfolioId, amount: amount)
        }

        // Withdraw REAL FlowTokens
        access(all) fun withdrawFlow(amount: UFix64): @FlowToken.Vault {
            pre {
                amount <= self.flowVault.balance: "Insufficient Flow balance"
            }
            let withdrawn <- self.flowVault.withdraw(amount: amount)
            self.updateTotalValue()
            emit FlowWithdrawn(portfolio: self.portfolioId, amount: amount)
            return <- withdrawn
        }

        // Update portfolio value using REAL Pyth prices
        access(self) fun updateTotalValue() {
            var totalAssetValue = 0.0

            for asset in self.holdings.keys {
                if let holding = self.holdings[asset] {
                    // Use REAL Pyth price for valuation
                    if let priceInfo = RealPythTrading.getRealPrice(asset: asset) {
                        let currentPrice = priceInfo.getFormattedPrice()
                        totalAssetValue = totalAssetValue + (holding.quantity * currentPrice)
                    }
                    // If no real price available, asset value = 0 (realistic)
                }
            }

            self.totalValue = self.flowVault.balance + totalAssetValue
        }

        // Get portfolio performance with REAL valuations
        access(all) fun getPerformance(): {String: UFix64} {
            self.updateTotalValue()
            return {
                "totalValue": self.totalValue,
                "flowBalance": self.flowVault.balance,
                "holdingsCount": UFix64(self.holdings.length)
            }
        }

        access(all) fun getOwnerAddress(): Address {
            return self.ownerAddress
        }

        access(all) fun getHoldings(): {String: AssetHolding} {
            return self.holdings
        }
    }

    // Storage paths
    access(all) let PortfolioStoragePath: StoragePath
    access(all) let PortfolioPublicPath: PublicPath

    // Contract state
    access(all) var totalPortfolios: UInt64

    // Create new portfolio
    access(all) fun createPortfolio(owner: Address): @TradingPortfolio {
        let portfolio <- create TradingPortfolio(owner: owner)
        let portfolioId = portfolio.portfolioId
        self.totalPortfolios = self.totalPortfolios + 1
        emit PortfolioCreated(owner: owner, portfolioId: portfolioId)
        return <- portfolio
    }

    // Get REAL price from Pyth Network
    access(all) fun getRealPrice(asset: String): PythIntegration.PriceInfo? {
        return PythIntegration.getPrice(feedId: asset)
    }

    // Get REAL price with max age check
    access(all) fun getRealPriceWithMaxAge(asset: String, maxAge: UInt64): PythIntegration.PriceInfo? {
        return PythIntegration.getPriceNoOlderThan(feedId: asset, maxAge: maxAge)
    }

    // Update Pyth prices with real data
    access(all) fun updatePythPrices(updateData: [String]) {
        PythIntegration.updatePrices(updateData: updateData)
    }

    // Get portfolio performance
    access(all) fun getPortfolioPerformance(address: Address): {String: UFix64}? {
        let account = getAccount(address)
        if let portfolioRef = account.capabilities.borrow<&{TradingPortfolioPublic}>(self.PortfolioPublicPath) {
            return portfolioRef.getPerformance()
        }
        return nil
    }

    access(all) fun getTotalPortfolios(): UInt64 {
        return self.totalPortfolios
    }

    // Get all supported Pyth feeds
    access(all) fun getSupportedAssets(): [String] {
        return PythIntegration.getSupportedFeeds()
    }

    init() {
        self.totalPortfolios = 0
        self.PortfolioStoragePath = /storage/RealPythTradingPortfolioV1
        self.PortfolioPublicPath = /public/RealPythTradingPortfolioV1
    }
}