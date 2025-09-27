import "RealSocialTrading"
import "FlowToken"
import "FungibleToken"

// Transaction to create a real trading portfolio with actual FlowToken deposit
transaction(initialDepositAmount: UFix64) {

    let signerAccount: auth(Storage, Capabilities) &Account
    let flowVault: auth(FungibleToken.Withdraw) &FlowToken.Vault

    prepare(signer: auth(Storage, Capabilities) &Account) {
        self.signerAccount = signer

        // Get reference to the signer's Flow token vault
        self.flowVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow Flow vault reference")
    }

    execute {
        // Create a new trading portfolio
        let portfolio <- RealSocialTrading.createPortfolio(owner: self.signerAccount.address)

        // Deposit REAL FlowTokens if requested
        if initialDepositAmount > 0.0 {
            let depositVault <- self.flowVault.withdraw(amount: initialDepositAmount)
            portfolio.depositFlow(vault: <- (depositVault as! @FlowToken.Vault))
        }

        // Store the portfolio
        self.signerAccount.storage.save(<-portfolio, to: RealSocialTrading.PortfolioStoragePath)

        // Create and publish public capability
        let portfolioCapability = self.signerAccount.capabilities.storage.issue<&{RealSocialTrading.TradingPortfolioPublic}>(
            RealSocialTrading.PortfolioStoragePath
        )
        self.signerAccount.capabilities.publish(portfolioCapability, at: RealSocialTrading.PortfolioPublicPath)

        log("Real trading portfolio created with ".concat(initialDepositAmount.toString()).concat(" FLOW"))
    }
}