import "SocialTrading"

// Transaction to follow a trader using Flow Actions
transaction(traderAddress: Address) {

    let portfolioRef: &SocialTrading.TradingPortfolio
    let targetPortfolioRef: &{SocialTrading.TradingPortfolioPublic}

    prepare(signer: auth(Storage) &Account) {
        // Get reference to our trading portfolio
        self.portfolioRef = signer.borrow<&SocialTrading.TradingPortfolio>(from: SocialTrading.PortfolioStoragePath)
            ?? panic("Could not borrow trading portfolio reference")

        // Get reference to the trader we want to follow
        let targetAccount = getAccount(traderAddress)
        self.targetPortfolioRef = targetAccount.capabilities.borrow<&{SocialTrading.TradingPortfolioPublic}>(SocialTrading.PortfolioPublicPath)
            ?? panic("Could not borrow target trader's portfolio reference")
    }

    execute {
        // Create parameters for the follow action
        let parameters: {String: AnyStruct} = {
            "traderAddress": traderAddress
        }

        // Create the Flow Action for following
        let actionId = self.portfolioRef.createAction(
            actionType: SocialTrading.ActionType.FOLLOW_TRADER,
            parameters: parameters
        )

        log("Created follow action with ID: ".concat(actionId))

        // Execute the follow action
        let result = self.portfolioRef.executeAction(actionId: actionId)

        if result == "success" {
            // Add ourselves as a follower to the target trader
            self.targetPortfolioRef.addFollower(followerAddress: self.portfolioRef.owner)

            log("Successfully followed trader: ".concat(traderAddress.toString()))

            // Log the target trader's performance
            let targetPerformance = self.targetPortfolioRef.getPerformance()
            log("Following trader with social score: ".concat(targetPerformance["socialScore"]?.toString() ?? "0"))
        } else {
            log("Failed to follow trader: ".concat(result))
        }
    }
}