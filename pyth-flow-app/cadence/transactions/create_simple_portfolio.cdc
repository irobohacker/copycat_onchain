import "SimpleSocialTrading"

// Transaction to create a new trading portfolio
transaction() {

    let signerAccount: auth(Storage, Capabilities) &Account

    prepare(signer: auth(Storage, Capabilities) &Account) {
        self.signerAccount = signer
    }

    execute {
        // Create a new trading portfolio
        let portfolio <- SimpleSocialTrading.createPortfolio(owner: self.signerAccount.address)

        // Store the portfolio
        self.signerAccount.storage.save(<-portfolio, to: SimpleSocialTrading.PortfolioStoragePath)

        // Create and publish public capability
        let portfolioCapability = self.signerAccount.capabilities.storage.issue<&{SimpleSocialTrading.TradingPortfolioPublic}>(
            SimpleSocialTrading.PortfolioStoragePath
        )
        self.signerAccount.capabilities.publish(portfolioCapability, at: SimpleSocialTrading.PortfolioPublicPath)

        log("Simple trading portfolio created successfully")
    }
}