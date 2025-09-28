// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Minimal IERC20 interface
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

// SaucerSwap V2 Router interface
interface ISwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
    function refundETH() external payable;
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;
}

// QuoterV2 interface for getting quotes
interface IQuoterV2 {
    function quoteExactInput(bytes memory path, uint256 amountIn)
        external
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    function quoteExactOutput(bytes memory path, uint256 amountOut)
        external
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );
}

// Interface for the lottery contract
interface ISwapLottery {
    function enterUser(address user, uint256 swapProfit) external;
}

/**
 * @title ProfitableSaucerSwap
 * @dev A contract to handle SaucerSwap trading with profit tracking and lottery integration
 */
contract ProfitableSaucerSwap {
    ISwapRouter public immutable swapRouter;
    IQuoterV2 public immutable quoter;
    ISwapLottery public lotteryContract;

    // WHBAR address (Wrapped HBAR)
    address public immutable WHBAR;

    // Owner address
    address public owner;

    // Lottery pool address
    address public lotteryPool;

    // Reentrancy guard
    bool private locked;

    // User swap history for profit calculation
    struct SwapRecord {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        uint256 timestamp;
        bool isRoundTripStart; // true if this is the first swap in a potential round trip
    }

    mapping(address => SwapRecord[]) public userSwapHistory;
    mapping(address => uint256) public userTotalProfits;
    mapping(address => uint256) public userLotteryContributions;

    // Events
    event SwapExecuted(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 profit,
        uint256 lotteryContribution
    );

    event RoundTripCompleted(
        address indexed user,
        uint256 profit,
        uint256 lotteryContribution
    );

    event LotteryContractUpdated(address indexed newLotteryContract);
    event LotteryPoolUpdated(address indexed newLotteryPool);

    event EmergencyWithdraw(
        address indexed token,
        uint256 amount,
        address indexed to
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    constructor(
        address _swapRouter,
        address _quoter,
        address _whbar,
        address _lotteryPool
    ) {
        swapRouter = ISwapRouter(_swapRouter);
        quoter = IQuoterV2(_quoter);
        WHBAR = _whbar;
        lotteryPool = _lotteryPool;
        owner = msg.sender;
    }

    /**
     * @dev Set the lottery contract address
     */
    function setLotteryContract(address _lotteryContract) external onlyOwner {
        lotteryContract = ISwapLottery(_lotteryContract);
        emit LotteryContractUpdated(_lotteryContract);
    }

    /**
     * @dev Set the lottery pool address
     */
    function setLotteryPool(address _lotteryPool) external onlyOwner {
        lotteryPool = _lotteryPool;
        emit LotteryPoolUpdated(_lotteryPool);
    }

    /**
     * @dev Internal function to calculate profit and handle lottery contributions
     */
    function _handleProfitAndLottery(
        address user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) internal returns (uint256 profit, uint256 lotteryContribution) {
        SwapRecord[] storage history = userSwapHistory[user];

        // Check for round-trip completion
        bool isRoundTripComplete = false;
        uint256 originalAmount = 0;

        if (history.length > 0) {
            SwapRecord storage lastSwap = history[history.length - 1];

            // Check if this completes a round trip (swap back to original token)
            if (lastSwap.isRoundTripStart &&
                lastSwap.tokenOut == tokenIn &&
                lastSwap.tokenIn == tokenOut) {

                isRoundTripComplete = true;
                originalAmount = lastSwap.amountIn;

                // Calculate profit (if we got more than we started with)
                if (amountOut > originalAmount) {
                    profit = amountOut - originalAmount;

                    // Calculate 10% charge on profit
                    uint256 totalCharge = (profit * 1000) / 10000; // 10%

                    // 8% goes to lottery pool
                    lotteryContribution = (profit * 800) / 10000; // 8%

                    // Transfer lottery contribution to lottery pool
                    if (lotteryContribution > 0) {
                        if (tokenOut == WHBAR) {
                            // If profit is in HBAR, transfer directly
                            payable(lotteryPool).transfer(lotteryContribution);
                        } else {
                            // If profit is in tokens, transfer tokens
                            IERC20(tokenOut).transfer(lotteryPool, lotteryContribution);
                        }

                        userLotteryContributions[user] += lotteryContribution;

                        // Enter user in lottery if lottery contract is set
                        if (address(lotteryContract) != address(0)) {
                            lotteryContract.enterUser(user, profit);
                        }
                    }

                    userTotalProfits[user] += profit;

                    emit RoundTripCompleted(user, profit, lotteryContribution);
                }

                // Mark last swap as no longer round trip start
                lastSwap.isRoundTripStart = false;
            }
        }

        // Record current swap
        SwapRecord memory newRecord = SwapRecord({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            amountOut: amountOut,
            timestamp: block.timestamp,
            isRoundTripStart: !isRoundTripComplete // This could be start of new round trip
        });

        history.push(newRecord);
    }

    /**
     * @dev Swap exact HBAR for tokens
     */
    function swapExactHBARForTokens(
        address tokenOut,
        uint24 fee,
        uint256 amountOutMinimum,
        uint256 deadline
    ) external payable nonReentrant returns (uint256 amountOut) {
        require(msg.value > 0, "Must send HBAR");
        require(tokenOut != address(0), "Invalid token address");
        require(deadline >= block.timestamp, "Deadline expired");

        // Create the swap path: WHBAR -> tokenOut
        bytes memory path = abi.encodePacked(WHBAR, fee, tokenOut);

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(this), // Receive tokens to this contract for profit calculation
            deadline: deadline,
            amountIn: msg.value,
            amountOutMinimum: amountOutMinimum
        });

        // Execute the swap with HBAR value
        amountOut = swapRouter.exactInput{value: msg.value}(params);

        // Handle profit calculation and lottery
        (uint256 profit, uint256 lotteryContribution) = _handleProfitAndLottery(
            msg.sender,
            WHBAR,
            tokenOut,
            msg.value,
            amountOut
        );

        // Transfer tokens to user (minus any lottery contribution)
        uint256 userAmount = amountOut - lotteryContribution;
        if (userAmount > 0) {
            IERC20(tokenOut).transfer(msg.sender, userAmount);
        }

        emit SwapExecuted(msg.sender, WHBAR, tokenOut, msg.value, amountOut, profit, lotteryContribution);
        return amountOut;
    }

    /**
     * @dev Swap exact tokens for HBAR
     */
    function swapExactTokensForHBAR(
        address tokenIn,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountOut) {
        require(tokenIn != address(0), "Invalid token address");
        require(amountIn > 0, "Amount in must be > 0");
        require(deadline >= block.timestamp, "Deadline expired");

        // Transfer tokens from sender to this contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Approve the router to spend the tokens
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        // Create the swap path: tokenIn -> WHBAR
        bytes memory path = abi.encodePacked(tokenIn, fee, WHBAR);

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(this), // Receive WHBAR to this contract first
            deadline: deadline,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum
        });

        // Execute the swap to get WHBAR
        amountOut = swapRouter.exactInput(params);

        // Unwrap WHBAR to HBAR
        bytes[] memory multicallData = new bytes[](2);
        multicallData[0] = abi.encodeWithSelector(
            ISwapRouter.unwrapWETH9.selector,
            amountOut,
            address(this)
        );
        multicallData[1] = abi.encodeWithSelector(ISwapRouter.refundETH.selector);

        swapRouter.multicall(multicallData);

        // Handle profit calculation and lottery
        (uint256 profit, uint256 lotteryContribution) = _handleProfitAndLottery(
            msg.sender,
            tokenIn,
            WHBAR,
            amountIn,
            amountOut
        );

        // Send HBAR to user (minus any lottery contribution)
        uint256 userAmount = amountOut - lotteryContribution;
        if (userAmount > 0) {
            payable(msg.sender).transfer(userAmount);
        }

        emit SwapExecuted(msg.sender, tokenIn, WHBAR, amountIn, amountOut, profit, lotteryContribution);
        return amountOut;
    }

    /**
     * @dev Swap exact input tokens for output tokens
     */
    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountOut) {
        require(tokenIn != address(0) && tokenOut != address(0), "Invalid token address");
        require(tokenIn != tokenOut, "Cannot swap same token");
        require(amountIn > 0, "Amount in must be > 0");
        require(deadline >= block.timestamp, "Deadline expired");

        // Transfer tokens from sender to this contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Approve the router to spend the tokens
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        // Create the swap path: tokenIn -> tokenOut
        bytes memory path = abi.encodePacked(tokenIn, fee, tokenOut);

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(this), // Receive tokens to this contract for profit calculation
            deadline: deadline,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum
        });

        // Execute the swap
        amountOut = swapRouter.exactInput(params);

        // Handle profit calculation and lottery
        (uint256 profit, uint256 lotteryContribution) = _handleProfitAndLottery(
            msg.sender,
            tokenIn,
            tokenOut,
            amountIn,
            amountOut
        );

        // Transfer tokens to user (minus any lottery contribution)
        uint256 userAmount = amountOut - lotteryContribution;
        if (userAmount > 0) {
            IERC20(tokenOut).transfer(msg.sender, userAmount);
        }

        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut, profit, lotteryContribution);
        return amountOut;
    }

    /**
     * @dev Get a quote for exact input swap
     */
    function getQuoteExactInput(bytes memory path, uint256 amountIn)
        external
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        )
    {
        return quoter.quoteExactInput(path, amountIn);
    }

    /**
     * @dev Get user's swap history length
     */
    function getUserSwapHistoryLength(address user) external view returns (uint256) {
        return userSwapHistory[user].length;
    }

    /**
     * @dev Get user's swap record at index
     */
    function getUserSwapRecord(address user, uint256 index) external view returns (
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 timestamp,
        bool isRoundTripStart
    ) {
        require(index < userSwapHistory[user].length, "Index out of bounds");
        SwapRecord memory record = userSwapHistory[user][index];
        return (
            record.tokenIn,
            record.tokenOut,
            record.amountIn,
            record.amountOut,
            record.timestamp,
            record.isRoundTripStart
        );
    }

    /**
     * @dev Get user statistics
     */
    function getUserStats(address user) external view returns (
        uint256 totalProfits,
        uint256 lotteryContributions,
        uint256 totalSwaps
    ) {
        return (
            userTotalProfits[user],
            userLotteryContributions[user],
            userSwapHistory[user].length
        );
    }

    /**
     * @dev Emergency function to withdraw tokens
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be > 0");

        if (token == address(0)) {
            require(address(this).balance >= amount, "Insufficient HBAR balance");
            payable(owner).transfer(amount);
        } else {
            require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient token balance");
            bool success = IERC20(token).transfer(owner, amount);
            require(success, "Token transfer failed");
        }

        emit EmergencyWithdraw(token, amount, owner);
    }

    /**
     * @dev Transfer ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        require(newOwner != owner, "New owner must be different");

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /**
     * @dev Get contract's balance of a specific token
     */
    function getTokenBalance(address token) external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        }
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev Get current contract configuration
     */
    function getContractInfo() external view returns (
        address _swapRouter,
        address _quoter,
        address _whbar,
        address _owner,
        address _lotteryPool,
        address _lotteryContract
    ) {
        return (
            address(swapRouter),
            address(quoter),
            WHBAR,
            owner,
            lotteryPool,
            address(lotteryContract)
        );
    }

    /**
     * @dev Allow the contract to receive HBAR
     */
    receive() external payable {}
}