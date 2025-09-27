import "SimpleSocialTrading"

// Transaction to execute a buy action using Flow Actions (FLIP-338)
transaction(asset: String, amount: UFix64) {

    let portfolioRef: &SimpleSocialTrading.TradingPortfolio

    prepare(signer: auth(Storage) &Account) {
        // Get reference to the trading portfolio
        self.portfolioRef = signer.storage.borrow<&SimpleSocialTrading.TradingPortfolio>(from: SimpleSocialTrading.PortfolioStoragePath)
            ?? panic("Could not borrow trading portfolio reference")
    }

    execute {
        // Create parameters for the buy action
        let parameters: {String: AnyStruct} = {
            "asset": asset,
            "amount": amount
        }

        // Create the Flow Action
        let actionId = self.portfolioRef.createAction(
            actionType: SimpleSocialTrading.ActionType.BUY,
            parameters: parameters
        )

        log("Created Flow Action with ID: ".concat(actionId))

        // Execute the action immediately
        let result = self.portfolioRef.executeAction(actionId: actionId)

        log("Action executed with result: ".concat(result))

        if result == "success" {
            log("Trade executed successfully!")

            // Get updated portfolio performance
            let performance = self.portfolioRef.getPerformance()
            log("New portfolio value: ".concat(performance["totalValue"]?.toString() ?? "0"))
            log("Flow balance: ".concat(performance["flowBalance"]?.toString() ?? "0"))
        } else {
            log("Trade failed: ".concat(result))
        }
    }
}