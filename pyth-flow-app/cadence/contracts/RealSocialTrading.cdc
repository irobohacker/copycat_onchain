import "RealPythPriceFeed"
import "FlowToken"
import "FungibleToken"

access(all) contract RealSocialTrading {

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

    // Trading Portfolio Resource
    access(all) resource TradingPortfolio: TradingPortfolioPublic {
        access(all) let portfolioId: UInt64
        access(self) let ownerAddress: Address
        access(all) var holdings: {String: AssetHolding}
        access(self) var flowVault: @FlowToken.Vault  // REAL FlowToken vault
        access(all) var totalValue: UFix64
        access(self) var pendingActions: {String: FlowAction}

        init(owner: Address) {
            self.portfolioId = self.uuid
            self.ownerAddress = owner
            self.holdings = {}
            self.flowVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
            self.totalValue = 0.0  // NO DUMMY STARTING BALANCE
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

            // Mark action as executed
            self.pendingActions[actionId]!.markExecuted()
            return result
        }

        // Execute buy action with REAL price check
        access(self) fun executeBuyAction(asset: String, amount: UFix64): String {
            let priceData = RealSocialTrading.getAssetPrice(asset: asset)
            if priceData == nil {
                return "price_not_available_no_oracle_data"
            }

            let price = priceData!.getFormattedPrice()
            let cost = amount * price

            // Check REAL FlowToken balance
            if cost > self.flowVault.balance {
                return "insufficient_flow_balance"
            }

            // Withdraw REAL FlowTokens for the trade
            let tradeCost <- self.flowVault.withdraw(amount: cost)

            // In production, this would swap the FlowTokens for the asset
            // For now, destroy the FlowTokens and record the holdings
            destroy tradeCost

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

        // Execute sell action with REAL price check
        access(self) fun executeSellAction(asset: String, quantity: UFix64): String {
            if let holding = self.holdings[asset] {
                if holding.quantity < quantity {
                    return "insufficient_asset_quantity"
                }

                let priceData = RealSocialTrading.getAssetPrice(asset: asset)
                if priceData == nil {
                    return "price_not_available_no_oracle_data"
                }

                let price = priceData!.getFormattedPrice()
                let revenue = quantity * price

                // Update holdings
                let newQuantity = holding.quantity - quantity
                if newQuantity == 0.0 {
                    self.holdings.remove(key: asset)
                } else {
                    holding.updateHolding(newQuantity: newQuantity, newAvgPrice: holding.avgBuyPrice)
                }

                // Deposit REAL FlowTokens from the sale
                // In production, would receive FlowTokens from asset sale
                let revenueVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
                // NOTE: This is still simulated - would need real asset exchange
                self.flowVault.deposit(from: <- revenueVault)

                self.updateTotalValue()
                emit TradeExecuted(trader: self.ownerAddress, asset: asset, amount: quantity, price: price)
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

        // Update total portfolio value with REAL asset prices
        access(self) fun updateTotalValue() {
            var totalAssetValue = 0.0
            for asset in self.holdings.keys {
                if let holding = self.holdings[asset] {
                    if let priceData = RealSocialTrading.getAssetPrice(asset: asset) {
                        let currentPrice = priceData.getFormattedPrice()
                        totalAssetValue = totalAssetValue + (holding.quantity * currentPrice)
                    }
                    // If no price data available, asset value is 0 (realistic)
                }
            }
            self.totalValue = self.flowVault.balance + totalAssetValue
        }

        // Get portfolio performance
        access(all) fun getPerformance(): {String: UFix64} {
            self.updateTotalValue()
            return {
                "totalValue": self.totalValue,
                "flowBalance": self.flowVault.balance,
                "holdingsCount": UFix64(self.holdings.length)
            }
        }

        // Get owner address
        access(all) fun getOwnerAddress(): Address {
            return self.ownerAddress
        }

        // Get holdings
        access(all) fun getHoldings(): {String: AssetHolding} {
            return self.holdings
        }

        // Get real Flow balance
        access(all) fun getFlowBalance(): UFix64 {
            return self.flowVault.balance
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

    // Get asset price from REAL Pyth feed
    access(all) fun getAssetPrice(asset: String): RealPythPriceFeed.PriceData? {
        return RealPythPriceFeed.getLatestPrice(feedId: asset)
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
        self.PortfolioStoragePath = /storage/RealSocialTradingPortfolioV1
        self.PortfolioPublicPath = /public/RealSocialTradingPortfolioV1
    }

    destroy() {
        // Proper cleanup
    }
}