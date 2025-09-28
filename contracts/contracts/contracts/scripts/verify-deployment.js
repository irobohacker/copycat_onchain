const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function verifyDeployment() {
    const networkName = hre.network.name;
    console.log("Verifying deployment on network:", networkName);

    // Load deployment summary
    const summaryPath = path.join(__dirname, "../deployments", `${networkName}-deployment.json`);

    if (!fs.existsSync(summaryPath)) {
        throw new Error(`Deployment summary not found for network: ${networkName}`);
    }

    const deploymentSummary = JSON.parse(fs.readFileSync(summaryPath, "utf8"));
    console.log("Loaded deployment summary from:", summaryPath);

    // Get contract instances
    const ProfitableSaucerSwap = await ethers.getContractFactory("ProfitableSaucerSwap");
    const SwapLottery = await ethers.getContractFactory("SwapLottery");

    const profitableSaucerSwap = ProfitableSaucerSwap.attach(deploymentSummary.contracts.ProfitableSaucerSwap);
    const swapLottery = SwapLottery.attach(deploymentSummary.contracts.SwapLottery);

    console.log("\n=== Verifying Contract Deployments ===");

    // Verify ProfitableSaucerSwap
    console.log("\nVerifying ProfitableSaucerSwap...");
    try {
        const contractInfo = await profitableSaucerSwap.getContractInfo();
        console.log("✓ ProfitableSaucerSwap is deployed and responsive");
        console.log("  - SwapRouter:", contractInfo[0]);
        console.log("  - QuoterV2:", contractInfo[1]);
        console.log("  - WHBAR:", contractInfo[2]);
        console.log("  - Owner:", contractInfo[3]);
        console.log("  - Lottery Pool:", contractInfo[4]);
        console.log("  - Lottery Contract:", contractInfo[5]);
    } catch (error) {
        console.error("✗ ProfitableSaucerSwap verification failed:", error.message);
    }

    // Verify SwapLottery
    console.log("\nVerifying SwapLottery...");
    try {
        const contractStats = await swapLottery.getContractStats();
        const currentLotteryInfo = await swapLottery.getLottery(contractStats[2]); // Current lottery ID

        console.log("✓ SwapLottery is deployed and responsive");
        console.log("  - Total Lotteries:", contractStats[0].toString());
        console.log("  - Total Prizes Distributed:", contractStats[1].toString());
        console.log("  - Current Lottery ID:", contractStats[2].toString());
        console.log("  - Current Prize Pool:", contractStats[3].toString());
        console.log("  - Lottery Duration:", contractStats[4].toString(), "seconds");
        console.log("  - Min Participants:", contractStats[5].toString());
        console.log("  - Current Lottery Active:", currentLotteryInfo[7]);
        console.log("  - Current Participants:", currentLotteryInfo[5].toString());
    } catch (error) {
        console.error("✗ SwapLottery verification failed:", error.message);
    }

    // Verify contract connections
    console.log("\n=== Verifying Contract Connections ===");

    try {
        const swapContractFromLottery = await swapLottery.swapContract();
        const lotteryContractFromSwap = (await profitableSaucerSwap.getContractInfo())[5];

        if (swapContractFromLottery.toLowerCase() === deploymentSummary.contracts.ProfitableSaucerSwap.toLowerCase()) {
            console.log("✓ SwapLottery correctly references ProfitableSaucerSwap");
        } else {
            console.log("✗ SwapLottery reference mismatch");
            console.log("  Expected:", deploymentSummary.contracts.ProfitableSaucerSwap);
            console.log("  Actual:", swapContractFromLottery);
        }

        if (lotteryContractFromSwap.toLowerCase() === deploymentSummary.contracts.SwapLottery.toLowerCase()) {
            console.log("✓ ProfitableSaucerSwap correctly references SwapLottery");
        } else {
            console.log("✗ ProfitableSaucerSwap reference mismatch");
            console.log("  Expected:", deploymentSummary.contracts.SwapLottery);
            console.log("  Actual:", lotteryContractFromSwap);
        }
    } catch (error) {
        console.error("✗ Contract connection verification failed:", error.message);
    }

    // Check entropy fee
    console.log("\n=== Checking Entropy Integration ===");
    try {
        const entropyFee = await swapLottery.getEntropyFee();
        console.log("✓ Entropy integration working");
        console.log("  - Current Entropy Fee:", entropyFee.toString(), "wei");
    } catch (error) {
        console.error("✗ Entropy integration check failed:", error.message);
    }

    console.log("\n=== Verification Complete ===");
    console.log("Deployment Summary:");
    console.log("- Network:", deploymentSummary.network);
    console.log("- Deployed:", deploymentSummary.timestamp);
    console.log("- ProfitableSaucerSwap:", deploymentSummary.contracts.ProfitableSaucerSwap);
    console.log("- SwapLottery:", deploymentSummary.contracts.SwapLottery);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    verifyDeployment()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}

module.exports = { verifyDeployment };