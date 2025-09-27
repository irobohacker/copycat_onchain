import "SocialTrading"

// Transaction to create and execute a trade action using Flow Actions (FLIP-338)
transaction(actionType: UInt8, asset: String, amount: UFix64) {

    let portfolioRef: &SocialTrading.TradingPortfolio

    prepare(signer: auth(Storage) &Account) {
        // Get reference to the trading portfolio
        self.portfolioRef = signer.borrow<&SocialTrading.TradingPortfolio>(from: SocialTrading.PortfolioStoragePath)
            ?? panic("Could not borrow trading portfolio reference")
    }

    execute {
        // Create parameters for the action
        let parameters: {String: AnyStruct} = {
            "asset": asset,
            "amount": amount
        }

        // Convert UInt8 to ActionType
        let actionTypeEnum = SocialTrading.ActionType(rawValue: actionType)
            ?? panic("Invalid action type")

        // Create the Flow Action
        let actionId = self.portfolioRef.createAction(
            actionType: actionTypeEnum,
            parameters: parameters
        )

        log("Created Flow Action with ID: ".concat(actionId))

        // Execute the action immediately
        let result = self.portfolioRef.executeAction(actionId: actionId)

        log("Action executed with result: ".concat(result))

        if result == "success" {
            log("Trade executed successfully!")

            // Update portfolio performance
            let performance = self.portfolioRef.getPerformance()
            log("New portfolio value: ".concat(performance["totalValue"]?.toString() ?? "0"))
        } else {
            log("Trade failed: ".concat(result))
        }
    }
}