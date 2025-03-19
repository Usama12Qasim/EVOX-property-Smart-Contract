// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title TokenPresale Contract
/// @notice Handles the presale of tokens across multiple rounds with different configurations.
/// @dev Utilizes SafeERC20 for token operations and Chainlink for price feeds.
contract IGOPresale is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    /// @notice The ERC20 token being sold in the presale.
    IERC20 public token;

    /// @notice Struct representing a presale round.
    /// @param minBuyAmount Minimum amount of tokens that can be purchased in the round.
    /// @param maxBuyAmount Maximum amount of tokens that can be purchased in the round.
    /// @param tokenPrice Price of one token in the round.
    /// @param active Indicates if the round is currently active.
    /// @param totalTokens Total tokens allocated for the round.
    /// @param initialUnlock Percentage of tokens unlocked at the Token Generation Event (TGE).
    /// @param cliffDuration Duration of the cliff period in seconds.
    /// @param vestingDuration Duration of the vesting period in seconds.
    /// @param tokensSold Total number of tokens sold in this round.
    struct Round {
        uint256 minBuyAmount;
        uint256 maxBuyAmount;
        uint256 tokenPrice;
        bool active;
        uint256 totalTokens;
        uint256 initialUnlock;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 tokensSold;
    }

    struct UserData {
        address user;
        uint256 rounds;
        uint256 purchaseOn;
        uint256 purchasedTokens;
        uint256 buyWithBNB;
        uint256 buyWithTokens;
        uint256 tokenPrice;
        uint256 claimAmount;
        bool status;
    }

    /// @notice Struct representing a user's purchase details.
    /// @param amount Total amount of tokens purchased.
    /// @param claimAmount Total claimable tokens.
    /// @param initialClaim Indicates if the initial claim has been made.
    /// @param totalClaimed Total amount of tokens claimed by the user.
    /// @param nextClaimDate Date of the next claim.
    struct Purchase {
        uint256 amount;
        uint256 claimAmount;
        bool initialClaim;
        uint256 totalClaimed;
        uint256 nextClaimDate;
        uint256 lastClaimTime; // Track the last time the user claimed tokens
        bool isClaimed;
    }

    /// @notice Mapping of user purchases by address and round index.
    mapping(address => mapping(uint256 => Purchase)) public userPurchases;
    mapping(address => UserData[]) public userData;

    /// @notice Array to store all presale rounds.
    Round[] public rounds;

    /// @notice Indicates if token claiming is open.
    bool public claimOpen;

    /// @notice Total number of claim periods for token distribution.
    uint256 public totalClaimPeriods;

    /// @notice BNB token address for internal usage.
    address private BnbAddress;

    /// @notice Maximum cap for the total number of tokens sold in the presale.
    uint256 public maxCap;

    /// @notice Total tokens sold during the entire presale.
    uint256 public totalTokensSold;

    /// @notice Wallet address where funds from token sales will be transferred.
    address public fundsWallet;

    uint256 public TokenGenerationEvent;

    /// @notice Mapping of token addresses to their respective Chainlink price feeds.
    mapping(address => AggregatorV3Interface) public priceFeeds;

    /// @notice Mapping of claimed amounts by user and round index.
    mapping(address => mapping(uint256 => uint256)) public userClaimedAmounts;

    /// @notice Emitted when tokens are purchased.
    /// @param buyer The address of the buyer.
    /// @param amount The amount of tokens purchased.
    /// @param cost The cost of the tokens in the payment currency.
    event TokenPurchased(
        uint256 PurchasedOn,
        uint256 Round,
        address indexed buyer,
        uint256 amount,
        uint256 cost
    );

    /// @notice Emitted when a new round starts.
    /// @param roundIndex The index of the new round.
    /// @param startTimestamp The start timestamp of the round.
    /// @param endTimestamp The end timestamp of the round.
    event RoundStarted(
        uint256 roundIndex,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    /// @notice Emitted when a round ends.
    /// @param roundIndex The index of the ended round.
    event RoundEnded(uint256 roundIndex);

    /// @notice Emitted when a user tries to claim before the cliff period ends.
    /// @param user The address of the user.
    /// @param roundIndex The index of the round.
    event CliffNotReached(address user, uint256 roundIndex);

    /// @notice Emitted when a user's vesting period is completed.
    /// @param user The address of the user.
    /// @param roundIndex The index of the round.
    event VestingCompleted(address user, uint256 roundIndex);

    /// @notice Emitted when token claiming is opened.
    event ClaimOpened();

    /// @notice Emitted when tokens are claimed by a user.
    /// @param claimant The address of the user.
    /// @param amount The amount of tokens claimed.
    event TokensClaimed(address indexed claimant, uint256 amount);

    /// @notice Error for an invalid round index.
    error InvalidRoundIndex();

    /// @notice Error for an invalid end time.
    error InvalidEndTime();

    /// @notice Error for an unsupported token address.
    error UnsupportedTokenAddress();

    /// @notice Error for invalid price data from Chainlink.
    error InvalidPriceData();

    /// @notice Error for when the previous round hasn't ended yet.
    error PreviousRoundNotEnded();

    /// @notice Error for reaching the maximum cap of token sales.
    error MaxCapReached();

    /// @notice Initializes the presale contract.
    /// @param _bnbAddress The BNB token address.
    /// @param _usdtAddress The USDT token address.
    /// @param _priceFeedBNB The BNB Chainlink price feed address.
    /// @param _priceFeedUSDT The USDT Chainlink price feed address.
    /// @param _fundsWallet The wallet where funds will be collected.
    /// @param _maxCap The maximum cap for the total tokens sold.
    /// @param _token The token being sold.

    function initialize(
        address _bnbAddress,
        address _usdtAddress,
        address _priceFeedBNB,
        address _priceFeedUSDT,
        address _fundsWallet,
        uint256 _maxCap,
        IERC20 _token
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        priceFeeds[_bnbAddress] = AggregatorV3Interface(_priceFeedBNB);
        priceFeeds[_usdtAddress] = AggregatorV3Interface(_priceFeedUSDT);
        fundsWallet = _fundsWallet;
        BnbAddress = _bnbAddress;
        maxCap = _maxCap;
        token = _token;
        claimOpen = false;
        totalClaimPeriods = 12;
    }

    /// @notice Updates the token address for the presale.
    /// @param _tokenAddress The new token address.
    function setTokenAddress(IERC20 _tokenAddress) external onlyOwner {
        token = _tokenAddress;
    }

    /// @notice Starts a new presale round with the specified parameters.
    /// @param _minBuyAmount Minimum purchase amount for the round.
    /// @param _tokenPrice Token price for the round.
    /// @param _initialUnlock Percentage of tokens unlocked at TGE.
    /// @param _cliffDuration Duration of the cliff period.
    /// @param _vestingDuration Duration of the vesting period.
    /// @param _active Whether the round is active immediately.
    function startRound(
        uint256 _minBuyAmount,
        uint256 _allocationPercentage,
        uint256 _tokenPrice,
        uint256 _initialUnlock,
        uint256 _cliffDuration,
        uint256 _vestingDuration,
        bool _active
    ) external onlyOwner {
        uint256 remainingTokens = 0;
        if (rounds.length > 0) {
            Round storage lastRound = rounds[rounds.length - 1];
            lastRound.active = false;
            remainingTokens = lastRound.maxBuyAmount - lastRound.tokensSold;
        }

        uint256 totalTokens = (_allocationPercentage * maxCap) / 100;

        rounds.push(
            Round({
                minBuyAmount: _minBuyAmount,
                maxBuyAmount: totalTokens + remainingTokens,
                tokenPrice: _tokenPrice,
                active: _active,
                totalTokens: totalTokens,
                initialUnlock: _initialUnlock,
                cliffDuration: _cliffDuration,
                vestingDuration: _vestingDuration,
                tokensSold: 0
            })
        );
    }

    /// @notice Fetches the latest price for a given token from Chainlink.
    /// @param tokenAddress The address of the token.
    /// @return The latest price for the token.
    function getLatestPrice(
        address tokenAddress
    ) public view returns (uint256) {
        AggregatorV3Interface priceFeed = priceFeeds[tokenAddress];
        if (address(priceFeed) == address(0)) {
            revert UnsupportedTokenAddress();
        }

        (, int256 price, , , ) = priceFeed.latestRoundData();
        if (price <= 0) {
            revert InvalidPriceData();
        }
        return uint256(price) * 1e10; // Convert 8 decimal places to 18
    }

    /// @notice Allows users to buy tokens using another token (like USDT).
    /// @param _tokenAddress The address of the token being used for payment.
    /// @param _amount The amount of tokens to buy.
    function buyWithToken(
        address _tokenAddress,
        uint256 _amount
    ) external nonReentrant {
        Round storage currentRound = rounds[rounds.length - 1];
        UserData[] storage user = userData[msg.sender];
        require(currentRound.active, "No active round");

        uint256 tokenCost = (_amount * currentRound.tokenPrice) / 1e18;

        //require(_amount >= currentRound.minBuyAmount, "Amount too low");
        require(
            currentRound.tokensSold + _amount <= currentRound.maxBuyAmount,
            "Exceeds max cap for this round"
        );
        require(totalTokensSold + _amount <= maxCap, "Max cap reached");

        uint256 allowance = IERC20(_tokenAddress).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= tokenCost, "Token allowance too low");
        IERC20(_tokenAddress).transferFrom(
            msg.sender,
            fundsWallet,
            tokenCost
        );

        currentRound.tokensSold += _amount;
        totalTokensSold += _amount;

        Purchase storage purchase = userPurchases[msg.sender][
            rounds.length - 1
        ];
        purchase.amount += _amount;

        user.push(
            UserData(
                msg.sender,
                rounds.length - 1,
                block.timestamp,
                _amount,
                0,
                tokenCost,
                currentRound.tokenPrice,
                0,
                false
            )
        );

        emit TokenPurchased(
            block.timestamp,
            rounds.length - 1,
            msg.sender,
            _amount,
            tokenCost
        );
    }

    /// @notice Allows users to buy tokens using BNB.

    function buyWithBNB() external payable nonReentrant {
        require(msg.value > 0, "No BNB sent");

        Round storage currentRound = rounds[rounds.length - 1];
        UserData[] storage user = userData[msg.sender];

        require(currentRound.active, "No active round");

        uint256 bnbPrice = getLatestPrice(
            address(priceFeeds[address(BnbAddress)])
        );

        uint256 tokenAmount = (msg.value * bnbPrice) / currentRound.tokenPrice;
        // uint256 tokenCost = (_amount * currentRound.tokenPrice) / 1e18;
        // uint256 bnbRequired = (tokenCost * 1e18) / bnbPrice;

        // require(msg.value >= bnbRequired, "Insufficient BNB sent");
        // if (msg.value > bnbRequired) {
        //     payable(msg.sender).transfer(msg.value - bnbRequired);
        // }

        require(
            currentRound.tokensSold + tokenAmount <= currentRound.maxBuyAmount,
            "Exceeds max cap for this round"
        );
        require(totalTokensSold + tokenAmount <= maxCap, "Max cap reached");

        currentRound.tokensSold += tokenAmount;
        totalTokensSold += tokenAmount;

        Purchase storage purchase = userPurchases[msg.sender][
            rounds.length - 1
        ];
        purchase.amount += tokenAmount;

        user.push(
            UserData(
                msg.sender,
                rounds.length - 1,
                block.timestamp,
                tokenAmount,
                msg.value,
                0,
                currentRound.tokenPrice,
                0,
                false
            )
        );

        payable(fundsWallet).transfer(msg.value);

        emit TokenPurchased(
            block.timestamp,
            rounds.length - 1,
            msg.sender,
            tokenAmount,
            msg.value
        );
    }

    function getUserData(
        address user
    ) external view returns (UserData[] memory) {
        return userData[user];
    }

    /// @notice Retrieves the current round's details.
    /// @return minBuyAmount The minimum amount of tokens that can be purchased in the round.
    /// @return maxBuyAmount The maximum amount of tokens that can be purchased in the round.
    /// @return tokenPrice The price of each token in the round.
    /// @return active Whether the round is currently active.
    function currentRoundOfPurchase()
        external
        view
        returns (
            uint256 minBuyAmount,
            uint256 maxBuyAmount,
            uint256 tokenPrice,
            bool active
        )
    {
        Round storage currentRound = rounds[rounds.length - 1];
        return (
            currentRound.minBuyAmount,
            currentRound.maxBuyAmount,
            currentRound.tokenPrice,
            currentRound.active
        );
    }

    /// @notice Opens the claiming process for users to start claiming their purchased tokens.
    function openClaiming() external onlyOwner {
        claimOpen = true;
        emit ClaimOpened();
    }

    /// @notice Allows users to claim their tokens based on the vesting schedule.

    function claimAll() external nonReentrant {
        require(claimOpen, "Claiming is not open");
        require(
            block.timestamp > TokenGenerationEvent,
            "Token Generation Event Time has not started yet"
        );

        uint256 totalClaimable = 0;

        for (uint256 i = 0; i < rounds.length; i++) {
            Purchase storage purchase = userPurchases[msg.sender][i];
            uint256 CliffEndTime = TokenGenerationEvent +
                rounds[i].cliffDuration *
                (30 * 24 * 60 * 60);
            uint256 VestingStartTime = CliffEndTime; // Vesting starts after the cliff
            
            if (purchase.amount > 0) {
                // 1️⃣ **Handle Initial Claim First**
                if (!purchase.initialClaim) {
                    uint256 initialClaimAmount = (purchase.amount *
                        rounds[i].initialUnlock) / 100;

                    // Ensure it does not exceed purchase.amount
                    if (initialClaimAmount > purchase.amount) {
                        initialClaimAmount = purchase.amount;
                    }

                    purchase.claimAmount += initialClaimAmount;
                    purchase.initialClaim = true;
                    purchase.lastClaimTime = block.timestamp;
                    purchase.nextClaimDate = VestingStartTime;
                    totalClaimable += initialClaimAmount;
                    purchase.isClaimed = true;
                    updateUserStatus(msg.sender);

                    // After the first claim, exit to prevent cliff check
                    continue;
                }

                // 2️⃣ **Cliff Duration Check (ONLY after Initial Claim)**
                require(
                    block.timestamp >= VestingStartTime,
                    "Cliff Duration not finished yet"
                );

                // 3️⃣ **Vesting: Only Allow Claims Every Month**
                require(
                        block.timestamp >= purchase.lastClaimTime + 30 days,
                    "You can only claim once per month"
                );

                // 4️⃣ **Calculate Monthly Vesting**
                // uint256 monthsSinceCliff = (block.timestamp -
                //     VestingStartTime) / (30 * 24 * 60 * 60);
                uint256 VestingPercentage = 100 - rounds[i].initialUnlock;
                uint256 vestedAmount = (purchase.amount * VestingPercentage) /
                    100;
                // uint256 totalVestedTillNow = (vestedAmount * monthsSinceCliff) /
                //     rounds[i].vestingDuration;
                uint256 newClaimable = vestedAmount / rounds[i].vestingDuration;

                // **✅ Fix: Ensure total claim never exceeds purchase.amount**
                uint256 remainingTokens = purchase.amount -
                    purchase.claimAmount;
                if (newClaimable > remainingTokens) {
                    newClaimable = remainingTokens; // Cap the claim amount
                }

                require(newClaimable > 0, "You already claim your tokens");

                // 5️⃣ **Update User Claim Data**
                purchase.claimAmount += newClaimable;
                purchase.totalClaimed += newClaimable;
                purchase.lastClaimTime = block.timestamp;
                purchase.nextClaimDate = purchase.lastClaimTime + 30 days;
                purchase.isClaimed = true;
                totalClaimable += newClaimable;
                updateUserStatus(msg.sender);
            }
        }
        require(totalClaimable > 0, "No tokens available for claim");
        // Transfer tokens after all state changes
        require(
            token.transferFrom(fundsWallet, msg.sender, totalClaimable),
            "Token transfer failed"
        );
        emit TokensClaimed(msg.sender, totalClaimable);
    }

    function claim(uint256 index) external nonReentrant {
        require(claimOpen, "Claiming is not open");
        require(
            block.timestamp > TokenGenerationEvent,
            "Token Generation Event Time has not started yet"
        );

        require(index < userData[msg.sender].length, "Invalid index");

        UserData storage user = userData[msg.sender][index];

        uint256 totalClaimable = 0;

        for (uint256 i = 0; i < rounds.length; i++) {
            Purchase storage purchase = userPurchases[msg.sender][i];
            uint256 CliffEndTime = TokenGenerationEvent +
                rounds[i].cliffDuration *
                (30 * 24 * 60 * 60);
            uint256 VestingStartTime = CliffEndTime; // Vesting starts after the cliff

            if (purchase.amount > 0) {
                // 1️⃣ **Handle Initial Claim First**
                if (!purchase.initialClaim) {
                    uint256 initialClaimAmount = (user.purchasedTokens *
                        rounds[i].initialUnlock) / 100;

                    // Ensure it does not exceed purchase.amount
                    if (initialClaimAmount > user.purchasedTokens) {
                        initialClaimAmount = user.purchasedTokens;
                    }

                    purchase.claimAmount += initialClaimAmount;
                    purchase.initialClaim = true;
                    purchase.lastClaimTime = block.timestamp;
                    purchase.nextClaimDate = VestingStartTime;
                    totalClaimable += initialClaimAmount;
                    purchase.isClaimed = true;
                    user.claimAmount += initialClaimAmount;
                    user.status = true;

                    // After the first claim, exit to prevent cliff check
                    continue;
                }

                // 2️⃣ **Cliff Duration Check (ONLY after Initial Claim)**
                require(
                    block.timestamp >= VestingStartTime,
                    "Cliff Duration not finished yet"
                );

                // 3️⃣ **Vesting: Only Allow Claims Every Month**
                require(
                    purchase.lastClaimTime == 0 ||
                        block.timestamp >= purchase.lastClaimTime + 30 days,
                    "You can only claim once per month"
                );

                // 4️⃣ **Calculate Monthly Vesting**
                // uint256 monthsSinceCliff = (block.timestamp -
                //     VestingStartTime) / (30 * 24 * 60 * 60);
                uint256 VestingPercentage = 100 - rounds[i].initialUnlock;
                uint256 vestedAmount = (user.purchasedTokens * VestingPercentage) /
                    100;
                // uint256 totalVestedTillNow = (vestedAmount * monthsSinceCliff) /
                //     rounds[i].vestingDuration;
                uint256 newClaimable = vestedAmount / rounds[i].vestingDuration;

                // **✅ Fix: Ensure total claim never exceeds purchase.amount**
                uint256 remainingTokens = user.purchasedTokens -
                    purchase.claimAmount;
                if (newClaimable > remainingTokens) {
                    newClaimable = remainingTokens; // Cap the claim amount
                }

                require(newClaimable > 0, "You already claim your tokens");

                // 5️⃣ **Update User Claim Data**
                purchase.claimAmount += newClaimable;
                purchase.totalClaimed += newClaimable;
                purchase.lastClaimTime = block.timestamp;
                purchase.nextClaimDate = purchase.lastClaimTime + 30 days;
                purchase.isClaimed = true;
                totalClaimable += newClaimable;
                user.claimAmount += newClaimable;
                user.status = true;
            }
        }
        require(totalClaimable > 0, "No tokens available for claim");
        // Transfer tokens after all state changes
        require(
            token.transferFrom(fundsWallet, msg.sender, totalClaimable),
            "Token transfer failed"
        );
        emit TokensClaimed(msg.sender, totalClaimable);
    }

    function updateUserStatus(address _user) internal {
    for (uint256 i = 0; i < userData[_user].length; i++) {
        if (!userData[_user][i].status) {
            userData[_user][i].status = true;
        }
    }
    }

    function tgeTime(uint256 _tgeTime) external onlyOwner {
        require(
            _tgeTime > block.timestamp,
            "Please Correct Token Generation Event Time"
        );
        TokenGenerationEvent = _tgeTime;
    }
}
