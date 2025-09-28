const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Load network configuration
function loadNetworkConfig() {
    const configPath = path.join(__dirname, "../config/network-config.json");
    return JSON.parse(fs.readFileSync(configPath, "utf8"));
}

// Convert Hedera account ID to EVM address
function hederaToEvmAddress(hederaId) {
    if (hederaId.startsWith("0x")) {
        return hederaId; // Already EVM address
    }

    // Extract the account number from Hedera ID (e.g., "0.0.1234567" -> 1234567)
    const accountNum = parseInt(hederaId.split('.').pop());

    // Convert to 20-byte EVM address with zero padding
    const evmAddress = "0x" + accountNum.toString(16).padStart(40, '0');
    return evmAddress;
}

async function deployContracts() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

    // Get network name from hardhat config
    const networkName = hre.network.name;
    console.log("Network:", networkName);

    // Load configuration
    const config = loadNetworkConfig();
    const networkConfig = config[networkName];

    if (!networkConfig) {
        throw new Error(`Network configuration not found for: ${networkName}`);
    }

    console.log("Using configuration for:", networkConfig.network);

    // Convert Hedera IDs to EVM addresses
    const swapRouterAddress = hederaToEvmAddress(networkConfig.saucerswap.swapRouter);
    const quoterAddress = hederaToEvmAddress(networkConfig.saucerswap.quoterV2);
    const whbarAddress = hederaToEvmAddress(networkConfig.saucerswap.whbar);
    const entropyAddress = hederaToEvmAddress(networkConfig.pyth.entropyContract);
    const entropyProvider = hederaToEvmAddress(networkConfig.pyth.entropyProvider);

    console.log("Contract addresses:");
    console.log("- SwapRouter:", swapRouterAddress);
    console.log("- QuoterV2:", quoterAddress);
    console.log("- WHBAR:", whbarAddress);
    console.log("- Entropy:", entropyAddress);
    console.log("- Entropy Provider:", entropyProvider);

    // Deploy SwapLottery first
    console.log("\nDeploying SwapLottery...");
    const SwapLottery = await ethers.getContractFactory("SwapLottery");
    const swapLottery = await SwapLottery.deploy(
        entropyAddress,
        entropyProvider,
        networkConfig.lottery.duration,
        networkConfig.lottery.minParticipants
    );

    await swapLottery.deployed();
    const swapLotteryAddress = swapLottery.address;
    console.log("SwapLottery deployed to:", swapLotteryAddress);

    // Deploy ProfitableSaucerSwap
    console.log("\nDeploying ProfitableSaucerSwap...");
    const ProfitableSaucerSwap = await ethers.getContractFactory("ProfitableSaucerSwap");
    const profitableSaucerSwap = await ProfitableSaucerSwap.deploy(
        swapRouterAddress,
        quoterAddress,
        whbarAddress,
        swapLotteryAddress // Use lottery contract as lottery pool initially
    );

    await profitableSaucerSwap.deployed();
    const profitableSaucerSwapAddress = profitableSaucerSwap.address;
    console.log("ProfitableSaucerSwap deployed to:", profitableSaucerSwapAddress);

    // Set the swap contract in the lottery
    console.log("\nSetting swap contract in lottery...");
    const setSwapContractTx = await swapLottery.setSwapContract(profitableSaucerSwapAddress);
    await setSwapContractTx.wait();
    console.log("Swap contract set in lottery");

    // Set the lottery contract in the swap contract
    console.log("Setting lottery contract in swap contract...");
    const setLotteryContractTx = await profitableSaucerSwap.setLotteryContract(swapLotteryAddress);
    await setLotteryContractTx.wait();
    console.log("Lottery contract set in swap contract");

    // Create deployment summary
    const deploymentSummary = {
        network: networkName,
        chainId: networkConfig.chainId,
        timestamp: new Date().toISOString(),
        deployer: deployer.address,
        contracts: {
            ProfitableSaucerSwap: profitableSaucerSwapAddress,
            SwapLottery: swapLotteryAddress
        },
        configuration: {
            swapRouter: swapRouterAddress,
            quoterV2: quoterAddress,
            whbar: whbarAddress,
            entropy: entropyAddress,
            entropyProvider: entropyProvider,
            lotteryDuration: networkConfig.lottery.duration,
            minParticipants: networkConfig.lottery.minParticipants
        }
    };

    // Save deployment summary
    const deploymentsDir = path.join(__dirname, "../deployments");
    if (!fs.existsSync(deploymentsDir)) {
        fs.mkdirSync(deploymentsDir, { recursive: true });
    }

    const summaryPath = path.join(deploymentsDir, `${networkName}-deployment.json`);
    fs.writeFileSync(summaryPath, JSON.stringify(deploymentSummary, null, 2));

    console.log("\n=== Deployment Summary ===");
    console.log("Network:", networkName);
    console.log("ProfitableSaucerSwap:", profitableSaucerSwapAddress);
    console.log("SwapLottery:", swapLotteryAddress);
    console.log("Deployment summary saved to:", summaryPath);

    return {
        profitableSaucerSwap,
        swapLottery,
        addresses: {
            profitableSaucerSwap: profitableSaucerSwapAddress,
            swapLottery: swapLotteryAddress
        }
    };
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    deployContracts()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}

module.exports = { deployContracts };