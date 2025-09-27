import "SocialTrading"

// Transaction to create a new trading portfolio
transaction(initialDeposit: UFix64) {

    let signerAccount: auth(Storage, Capabilities) &Account

    prepare(signer: auth(Storage, Capabilities) &Account) {
        self.signerAccount = signer
    }

    execute {
        // Create a new trading portfolio
        let portfolio <- SocialTrading.createPortfolio(owner: self.signerAccount.address)

        // If there's an initial deposit, add it to the portfolio
        if initialDeposit > 0.0 {
            portfolio.depositFlow(amount: initialDeposit)
        }

        // Store the portfolio
        self.signerAccount.storage.save(<-portfolio, to: SocialTrading.PortfolioStoragePath)

        // Create and publish public capability
        let portfolioCapability = self.signerAccount.capabilities.storage.issue<&{SocialTrading.TradingPortfolioPublic}>(
            SocialTrading.PortfolioStoragePath
        )
        self.signerAccount.capabilities.publish(portfolioCapability, at: SocialTrading.PortfolioPublicPath)

        log("Trading portfolio created successfully")
    }
}