# 🎰 COPYCAT Lottery Contract

A decentralized lottery system using Pyth Entropy for fair and verifiable random number generation.

## 📋 **DEPLOYED CONTRACT DETAILS**

**🚀 Live Contract**: [0x6293ac0f22c6fee1d69d3e2a5464bdd616a58c75a1d1b616889dda69be5d4233](https://eth-sepolia.blockscout.com/tx/0x6293ac0f22c6fee1d69d3e2a5464bdd616a58c75a1d1b616889dda69be5d4233)

**Network**: Ethereum Sepolia Testnet  
**Entropy Contract**: `0x41c9e39574F40Ad34c79f1C99B66A45eFB830d4c`  
**Entropy Provider**: `0x6CC14824Ea2918f5De5C2f75A9Da968ad4BD6344`  
**Deployment Status**: ✅ **LIVE & FUNCTIONAL**

## 🚀 Features

### Core Functionality
- **Fair Randomness**: Uses Pyth Entropy for provably fair random number generation
- **Multiple Lottery Rounds**: Support for multiple concurrent lottery rounds
- **Flexible Parameters**: Configurable entry fees, participant limits, and duration
- **Automatic Execution**: Lotteries end automatically when max participants reached or time expires
- **Prize Distribution**: Automatic winner selection and prize claiming

### Security Features
- **Owner Controls**: Only owner can create lotteries
- **Fee Validation**: Proper entry fee validation
- **Participation Limits**: One entry per user per lottery
- **Time-based Security**: Lotteries have defined start/end times
- **Emergency Functions**: Owner can withdraw funds in emergencies

## 📋 Contract Functions

### Lottery Management
- `createLottery(uint256 _entryFee, uint256 _maxParticipants, uint256 _duration)` - Create new lottery
- `joinLottery(uint256 _lotteryId)` - Join a lottery by paying entry fee
- `endLottery(uint256 _lotteryId)` - Manually end a lottery

### Information Retrieval
- `getLottery(uint256 _lotteryId)` - Get complete lottery information
- `getLotteryParticipants(uint256 _lotteryId)` - Get list of participants
- `getUserStats(address _user)` - Get user's winnings and participation count
- `getContractStats()` - Get overall contract statistics

### Prize Management
- `claimPrize(uint256 _lotteryId)` - Winner claims their prize
- `getEntropyFee()` - Get current entropy fee

## 🎯 Lottery Parameters

### Entry Fee
- **Minimum**: 0.001 ETH
- **Maximum**: 1 ETH
- **Default**: 0.01 ETH (for testing)

### Participants
- **Minimum**: 2 participants
- **Maximum**: 1000 participants
- **Default**: 10 participants (for testing)

### Duration
- **Minimum**: 1 hour
- **Maximum**: 7 days
- **Default**: 24 hours

## 🔧 Deployment

### Prerequisites
1. Install dependencies:
```bash
npm install
```

2. Set up environment variables:
```bash
# .env file
PRIVATE_KEY=your_private_key
RPC_URL=your_rpc_url
```

### Deploy Contract
```bash
# Compile contracts
npx hardhat compile

# Deploy to testnet
npx hardhat run scripts/deploy-lottery.ts --network <network>

# Deploy to mainnet
npx hardhat run scripts/deploy-lottery.ts --network mainnet
```

### Test Contract
```bash
# Run tests
npx hardhat run scripts/test-lottery.ts --network <network>
```

## 🌐 Network Configuration

### Supported Networks
- **Ethereum Mainnet**
- **Arbitrum One**
- **Optimism**
- **Polygon**
- **Base**

### Pyth Entropy Addresses
You need to update the entropy addresses in the deployment script:

```typescript
// Example for Arbitrum
const entropyAddress = "0x0000000000000000000000000000000000000000";
const entropyProvider = "0x0000000000000000000000000000000000000000";
```

## 📊 Frontend Integration

### Contract ABI
After deployment, you'll get the contract ABI. Use it in your frontend:

```typescript
// Example usage in React
import { useContract, useContractRead, useContractWrite } from 'wagmi';

const lotteryContract = {
  address: '0x...',
  abi: COPYCATLotteryABI,
};

// Read lottery info
const { data: lotteryInfo } = useContractRead({
  ...lotteryContract,
  functionName: 'getLottery',
  args: [lotteryId],
});

// Join lottery
const { write: joinLottery } = useContractWrite({
  ...lotteryContract,
  functionName: 'joinLottery',
  args: [lotteryId],
  value: entryFee,
});
```

### Event Listening
```typescript
// Listen for lottery events
useEffect(() => {
  const contract = new ethers.Contract(contractAddress, abi, provider);
  
  contract.on('LotteryCreated', (lotteryId, entryFee, maxParticipants, duration) => {
    console.log('New lottery created:', { lotteryId, entryFee, maxParticipants, duration });
  });
  
  contract.on('LotteryJoined', (lotteryId, participant, participantCount) => {
    console.log('User joined lottery:', { lotteryId, participant, participantCount });
  });
  
  contract.on('LotteryEnded', (lotteryId, winner, prizeAmount, sequenceNumber) => {
    console.log('Lottery ended:', { lotteryId, winner, prizeAmount, sequenceNumber });
  });
}, []);
```

## 🎲 How It Works

### 1. Lottery Creation
- Owner creates a lottery with specific parameters
- Lottery becomes active and accepts participants

### 2. Participation
- Users pay entry fee to join lottery
- Each user can only participate once per lottery
- Prize pool increases with each participant

### 3. Lottery Ending
- Lottery ends when:
  - Maximum participants reached, OR
  - Time limit expired, OR
  - Manually ended by owner

### 4. Winner Selection
- If only 1 participant: they win automatically
- If multiple participants: Pyth Entropy generates random number
- Winner selected based on random number modulo participant count

### 5. Prize Claiming
- Winner can claim their prize anytime after lottery ends
- Prize is transferred directly to winner's address

## 🔒 Security Considerations

### Randomness
- Uses Pyth Entropy for provably fair randomness
- Random numbers are generated off-chain and verified on-chain
- No way to manipulate or predict outcomes

### Access Control
- Only owner can create lotteries
- Users can only join once per lottery
- Proper fee validation prevents underpayment

### Emergency Functions
- Owner can withdraw funds in emergencies
- Owner can update entropy provider if needed

## 📈 Analytics

### Contract Statistics
- Total lotteries created
- Total prizes distributed
- Current lottery ID

### User Statistics
- Total winnings per user
- Total participations per user

### Lottery Statistics
- Entry fees collected
- Participant counts
- Prize distributions

## 🚀 Future Enhancements

### Planned Features
- **Multiple Prize Tiers**: 1st, 2nd, 3rd place winners
- **NFT Rewards**: Special NFTs for winners
- **Governance**: Community voting on lottery parameters
- **Staking**: Stake tokens for lottery participation
- **Referral System**: Earn rewards for referring participants

### Integration Ideas
- **COPYCAT Strategies**: Use lottery winnings for trading strategies
- **Group Lotteries**: Lottery pools for trading groups
- **Tournament Mode**: Multi-round elimination tournaments

## 📞 Support

For questions or issues:
- Check the contract code and comments
- Review the test scripts for usage examples
- Test on testnets before mainnet deployment

## 📄 License

Apache 2.0 License - See LICENSE file for details.

---

**🎰 Ready to deploy your fair and secure lottery system!**
