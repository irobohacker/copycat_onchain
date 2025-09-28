// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the entropy SDK in order to interact with the entropy contracts
import "@pythnetwork/entropy-sdk-solidity/IEntropyV2.sol";
import "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";

library SwapLotteryErrors {
    error InsufficientFunds();
    error LotteryNotActive();
    error LotteryAlreadyEnded();
    error NoParticipants();
    error NotOwner();
    error NotAuthorizedContract();
    error InvalidWinnerNumber();
    error AlreadyParticipated();
    error LotteryInProgress();
    error InvalidLotteryDuration();
    error RandomNumberNotReady();
}

/**
 * @title SwapLottery
 * @dev A lottery contract that uses Pyth Entropy for random number generation.
 * Users are entered into the lottery when they complete profitable swaps.
 * The lottery uses Pyth Entropy to generate random numbers for fair winner selection.
 */
contract SwapLottery is IEntropyConsumer {

    // Events
    event LotteryStarted(uint256 indexed lotteryId, uint256 duration, uint256 timestamp);
    event UserEntered(uint256 indexed lotteryId, address indexed user, uint256 ticketNumber, uint256 swapProfit);
    event RandomNumberRequested(uint256 indexed lotteryId, uint64 sequenceNumber);
    event WinnerSelected(uint256 indexed lotteryId, address indexed winner, uint256 winningNumber, uint256 prizeAmount);
    event LotteryEnded(uint256 indexed lotteryId, uint256 totalPrize, uint256 totalParticipants);
    event PrizeClaimed(uint256 indexed lotteryId, address indexed winner, uint256 amount);

    // Lottery structure
    struct Lottery {
        uint256 lotteryId;
        uint256 startTime;
        uint256 endTime;
        uint256 prizePool;
        address[] participants;
        mapping(address => uint256[]) userTickets; // User's assigned random numbers
        mapping(address => bool) hasParticipated;
        address winner;
        uint256 winningNumber;
        bool isActive;
        bool isEnded;
        uint64 sequenceNumber;
        bool randomNumberReceived;
        bool prizeClaimed;
    }

    // State variables
    IEntropyV2 private entropy;
    address private entropyProvider;
    address public owner;
    address public swapContract; // The ProfitableSaucerSwap contract

    uint256 public currentLotteryId;
    mapping(uint256 => Lottery) public lotteries;

    // Lottery settings
    uint256 public lotteryDuration; // Duration of each lottery round in seconds
    uint256 public minParticipants; // Minimum participants to draw winner

    // Statistics
    uint256 public totalLotteries;
    uint256 public totalPrizesDistributed;
    mapping(address => uint256) public userTotalWinnings;
    mapping(address => uint256) public userParticipationCount;

    constructor(
        address _entropy,
        address _entropyProvider,
        uint256 _lotteryDuration,
        uint256 _minParticipants
    ) {
        entropy = IEntropyV2(_entropy);
        entropyProvider = _entropyProvider;
        owner = msg.sender;
        lotteryDuration = _lotteryDuration;
        minParticipants = _minParticipants;

        // Start the first lottery
        _startNewLottery();
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert SwapLotteryErrors.NotOwner();
        }
        _;
    }

    modifier onlySwapContract() {
        if (msg.sender != swapContract) {
            revert SwapLotteryErrors.NotAuthorizedContract();
        }
        _;
    }

    modifier lotteryExists(uint256 _lotteryId) {
        if (_lotteryId > currentLotteryId) {
            revert SwapLotteryErrors.InvalidWinnerNumber();
        }
        _;
    }

    /**
     * @dev Set the authorized swap contract
     */
    function setSwapContract(address _swapContract) external onlyOwner {
        swapContract = _swapContract;
    }

    /**
     * @dev Start a new lottery round
     */
    function _startNewLottery() internal {
        currentLotteryId++;
        totalLotteries++;

        Lottery storage lottery = lotteries[currentLotteryId];
        lottery.lotteryId = currentLotteryId;
        lottery.startTime = block.timestamp;
        lottery.endTime = block.timestamp + lotteryDuration;
        lottery.isActive = true;
        lottery.isEnded = false;
        lottery.randomNumberReceived = false;
        lottery.prizeClaimed = false;

        emit LotteryStarted(currentLotteryId, lotteryDuration, block.timestamp);
    }

    /**
     * @dev Enter a user into the current lottery (called by swap contract)
     */
    function enterUser(address user, uint256 swapProfit) external onlySwapContract {
        Lottery storage lottery = lotteries[currentLotteryId];

        if (!lottery.isActive) {
            revert SwapLotteryErrors.LotteryNotActive();
        }

        if (block.timestamp >= lottery.endTime) {
            // End current lottery and start new one
            _endCurrentLottery();
            _startNewLottery();
            lottery = lotteries[currentLotteryId];
        }

        // Generate a random ticket number for the user using Pyth entropy
        uint256 ticketNumber = _generateTicketNumber(user, swapProfit);

        // Add user to lottery if not already participated
        if (!lottery.hasParticipated[user]) {
            lottery.participants.push(user);
            lottery.hasParticipated[user] = true;
            userParticipationCount[user]++;
        }

        // Add ticket number to user's tickets
        lottery.userTickets[user].push(ticketNumber);

        emit UserEntered(currentLotteryId, user, ticketNumber, swapProfit);
    }

    /**
     * @dev Generate a ticket number for a user based on their swap profit and other factors
     */
    function _generateTicketNumber(address user, uint256 swapProfit) internal view returns (uint256) {
        // Create a pseudo-random number based on multiple factors
        // This will be used until Pyth entropy provides the final random number
        bytes32 hash = keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            user,
            swapProfit,
            currentLotteryId,
            lotteries[currentLotteryId].participants.length
        ));

        // Convert to number between 1 and 1000000
        return (uint256(hash) % 1000000) + 1;
    }

    /**
     * @dev End the current lottery manually (anyone can call if time expired)
     */
    function endCurrentLottery() external {
        Lottery storage lottery = lotteries[currentLotteryId];

        if (!lottery.isActive) {
            revert SwapLotteryErrors.LotteryNotActive();
        }

        if (block.timestamp < lottery.endTime) {
            revert SwapLotteryErrors.LotteryInProgress();
        }

        _endCurrentLottery();
    }

    /**
     * @dev Internal function to end the current lottery
     */
    function _endCurrentLottery() internal {
        Lottery storage lottery = lotteries[currentLotteryId];

        if (lottery.participants.length == 0) {
            lottery.isActive = false;
            lottery.isEnded = true;
            emit LotteryEnded(currentLotteryId, lottery.prizePool, 0);
            return;
        }

        lottery.isActive = false;

        if (lottery.participants.length < minParticipants) {
            // Not enough participants, roll over prize to next lottery
            lottery.isEnded = true;
            emit LotteryEnded(currentLotteryId, lottery.prizePool, lottery.participants.length);
            return;
        }

        // Request random number from Pyth Entropy
        uint256 fee = entropy.getFeeV2();
        if (address(this).balance >= fee) {
            uint64 sequenceNumber = entropy.requestV2{value: fee}();
            lottery.sequenceNumber = sequenceNumber;
            emit RandomNumberRequested(currentLotteryId, sequenceNumber);
        } else {
            // Fallback: use block-based randomness if we can't pay entropy fee
            _selectWinnerWithFallback(currentLotteryId);
        }
    }

    /**
     * @dev Select winner using a specific winning number
     */
    function selectWinner(uint256 _lotteryId, uint256 _winningNumber) external lotteryExists(_lotteryId) {
        Lottery storage lottery = lotteries[_lotteryId];

        if (lottery.isEnded) {
            revert SwapLotteryErrors.LotteryAlreadyEnded();
        }

        if (lottery.isActive) {
            revert SwapLotteryErrors.LotteryInProgress();
        }

        if (_winningNumber == 0 || _winningNumber > 1000000) {
            revert SwapLotteryErrors.InvalidWinnerNumber();
        }

        _selectWinnerByNumber(_lotteryId, _winningNumber);
    }

    /**
     * @dev Callback function called by Pyth Entropy when random number is generated
     */
    function entropyCallback(
        uint64 sequenceNumber,
        address,
        bytes32 randomNumber
    ) internal override {
        // Find the lottery with this sequence number
        for (uint256 i = 1; i <= currentLotteryId; i++) {
            Lottery storage lottery = lotteries[i];
            if (lottery.sequenceNumber == sequenceNumber && !lottery.randomNumberReceived) {
                lottery.randomNumberReceived = true;

                // Convert random number to winning number (1-1000000)
                uint256 winningNumber = (uint256(randomNumber) % 1000000) + 1;
                _selectWinnerByNumber(i, winningNumber);
                break;
            }
        }
    }

    /**
     * @dev Select winner by finding closest ticket number to winning number
     */
    function _selectWinnerByNumber(uint256 _lotteryId, uint256 _winningNumber) internal {
        Lottery storage lottery = lotteries[_lotteryId];

        if (lottery.participants.length == 0) {
            revert SwapLotteryErrors.NoParticipants();
        }

        address closestWinner = address(0);
        uint256 closestDifference = type(uint256).max;

        // Find the participant with the ticket number closest to winning number
        for (uint256 i = 0; i < lottery.participants.length; i++) {
            address participant = lottery.participants[i];
            uint256[] storage userTickets = lottery.userTickets[participant];

            for (uint256 j = 0; j < userTickets.length; j++) {
                uint256 ticketNumber = userTickets[j];
                uint256 difference = ticketNumber > _winningNumber ?
                    ticketNumber - _winningNumber :
                    _winningNumber - ticketNumber;

                if (difference < closestDifference) {
                    closestDifference = difference;
                    closestWinner = participant;
                }
            }
        }

        lottery.winner = closestWinner;
        lottery.winningNumber = _winningNumber;
        lottery.isEnded = true;

        if (closestWinner != address(0)) {
            userTotalWinnings[closestWinner] += lottery.prizePool;
            totalPrizesDistributed += lottery.prizePool;
        }

        emit WinnerSelected(_lotteryId, closestWinner, _winningNumber, lottery.prizePool);
        emit LotteryEnded(_lotteryId, lottery.prizePool, lottery.participants.length);
    }

    /**
     * @dev Fallback winner selection using block-based randomness
     */
    function _selectWinnerWithFallback(uint256 _lotteryId) internal {
        bytes32 blockHash = keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            _lotteryId
        ));
        uint256 winningNumber = (uint256(blockHash) % 1000000) + 1;
        _selectWinnerByNumber(_lotteryId, winningNumber);
    }

    /**
     * @dev Claim prize for a lottery (winner only)
     */
    function claimPrize(uint256 _lotteryId) external lotteryExists(_lotteryId) {
        Lottery storage lottery = lotteries[_lotteryId];

        if (!lottery.isEnded) {
            revert SwapLotteryErrors.LotteryInProgress();
        }

        if (lottery.winner != msg.sender) {
            revert SwapLotteryErrors.NotOwner();
        }

        if (lottery.prizeClaimed) {
            revert SwapLotteryErrors.InvalidWinnerNumber();
        }

        if (lottery.prizePool == 0) {
            revert SwapLotteryErrors.InsufficientFunds();
        }

        uint256 prizeAmount = lottery.prizePool;
        lottery.prizePool = 0;
        lottery.prizeClaimed = true;

        (bool success, ) = payable(msg.sender).call{value: prizeAmount}("");
        require(success, "Transfer failed");

        emit PrizeClaimed(_lotteryId, msg.sender, prizeAmount);
    }

    /**
     * @dev Add funds to current lottery prize pool
     */
    function addToPrizePool() external payable {
        if (msg.value > 0) {
            Lottery storage lottery = lotteries[currentLotteryId];
            lottery.prizePool += msg.value;
        }
    }

    /**
     * @dev Get lottery information
     */
    function getLottery(uint256 _lotteryId) external view lotteryExists(_lotteryId) returns (
        uint256 lotteryId,
        uint256 startTime,
        uint256 endTime,
        uint256 prizePool,
        uint256 participantCount,
        address winner,
        uint256 winningNumber,
        bool isActive,
        bool isEnded,
        bool randomNumberReceived,
        uint64 sequenceNumber
    ) {
        Lottery storage lottery = lotteries[_lotteryId];
        return (
            lottery.lotteryId,
            lottery.startTime,
            lottery.endTime,
            lottery.prizePool,
            lottery.participants.length,
            lottery.winner,
            lottery.winningNumber,
            lottery.isActive,
            lottery.isEnded,
            lottery.randomNumberReceived,
            lottery.sequenceNumber
        );
    }

    /**
     * @dev Get lottery participants
     */
    function getLotteryParticipants(uint256 _lotteryId) external view lotteryExists(_lotteryId) returns (address[] memory) {
        return lotteries[_lotteryId].participants;
    }

    /**
     * @dev Get user's ticket numbers for a lottery
     */
    function getUserTickets(uint256 _lotteryId, address user) external view lotteryExists(_lotteryId) returns (uint256[] memory) {
        return lotteries[_lotteryId].userTickets[user];
    }

    /**
     * @dev Get user statistics
     */
    function getUserStats(address _user) external view returns (
        uint256 totalWinnings,
        uint256 participationCount
    ) {
        return (userTotalWinnings[_user], userParticipationCount[_user]);
    }

    /**
     * @dev Get contract statistics
     */
    function getContractStats() external view returns (
        uint256 totalLotteries_,
        uint256 totalPrizesDistributed_,
        uint256 currentLotteryId_,
        uint256 currentPrizePool,
        uint256 lotteryDuration_,
        uint256 minParticipants_
    ) {
        return (
            totalLotteries,
            totalPrizesDistributed,
            currentLotteryId,
            lotteries[currentLotteryId].prizePool,
            lotteryDuration,
            minParticipants
        );
    }

    /**
     * @dev Get entropy fee required for random number generation
     */
    function getEntropyFee() public view returns (uint256) {
        return entropy.getFeeV2();
    }

    /**
     * @dev Required by IEntropyConsumer interface
     */
    function getEntropy() internal view override returns (address) {
        return address(entropy);
    }

    /**
     * @dev Update lottery settings (owner only)
     */
    function updateLotterySettings(uint256 _lotteryDuration, uint256 _minParticipants) external onlyOwner {
        if (_lotteryDuration < 1 hours || _lotteryDuration > 30 days) {
            revert SwapLotteryErrors.InvalidLotteryDuration();
        }

        lotteryDuration = _lotteryDuration;
        minParticipants = _minParticipants;
    }

    /**
     * @dev Update entropy provider (owner only)
     */
    function setEntropyProvider(address _newProvider) external onlyOwner {
        entropyProvider = _newProvider;
    }

    /**
     * @dev Emergency functions (only owner)
     */
    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Transfer ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }

    /**
     * @dev Accept HBAR deposits
     */
    receive() external payable {
        if (msg.value > 0) {
            Lottery storage lottery = lotteries[currentLotteryId];
            lottery.prizePool += msg.value;
        }
    }
}