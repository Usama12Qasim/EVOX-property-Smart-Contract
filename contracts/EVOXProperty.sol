// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {EVOXFactory} from "./EVOXFactoryContract.sol";
import {EVOXSubgraph} from "./EVOXSubgraphData.sol";
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {ERC1155SupplyUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract PropertyCreation is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    ERC1155SupplyUpgradeable,
    ReentrancyGuardUpgradeable,
    EVOXSubgraph
{
    using SafeERC20 for IERC20;

    enum ROIPeriod {
        Monthly,
        Yearly
    }

    enum TransactionStatus {
        Pending,
        Completed,
        Failed
    }

    ROIPeriod public roiPeriod;

    event BuyPropertyFractions(
        uint256 PropertyID,
        uint256 PropertyFractions,
        uint256 purchasePrice
    );

    event ROIDeposit(
        address PropertyOwner,
        uint256 PropertyID,
        uint256 ROIAmount,
        uint256 DepositTime,
        uint256 DueAmount
    );

    event ClaimROIAmount(
        address FractionOwner,
        uint256 RoiAmount,
        uint256 ClaimTime
    );

    error UnsupportedTokenAddress();
    error InvalidPriceData();

    struct PropertyDetail {
        address PropertyOwner;
        uint256 perFractionPriceInNative;
        uint256 perFractionPriceInEVOX;
        string PropertyUri;
        uint256 totalFractions;
        uint256 PropertyID;
        uint256 availableFractions;
        uint256 ROIPercentage;
        uint256 ROIDepositTime;
        uint256 ROIDepositAmount;
        uint256 totalROIDepositAmount;
        bool isPropertyCreated;
    }

    struct UserDetail {
        address User;
        string PropertyUri;
        uint256 PurchasingTime;
        uint256 InvestmentAmountInNativeInEVOXToken;
        uint256 InvestmentAmountInNativeInNativeCurrency;
        uint256 PurchaseFractions;
        uint256 AvailableFractions;
        uint256 totalFractions;
        uint256 ClaimAmount;
        address Claimer;
        uint256 ClaimTime;
    }

    PropertyDetail public propertyDetails;
    mapping(address => mapping(uint256 => UserDetail)) User;
    mapping(address => mapping(uint256 => uint256)) TrackFractions;
    mapping(address => uint256) InvestmentAmountInNative;
    mapping(address => uint256) InvestmentAmountInEVOXToken;
    mapping(address => mapping(uint256 => uint256)) lastClaimROITime;
    mapping(address => mapping(uint256 => uint256)) lastROIDepositTime;
    mapping(address => bool) isPropertyCreated;
    mapping(address => AggregatorV3Interface) public priceFeeds;
    address public FactoryAddress;
    IERC20 public EvoxToken;
    IERC20 public USDTAddress;
    address public priceFeedBNB = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
    address public priceFeedEVOX = 0xE4eE17114774713d2De0eC0f035d4F7665fc025D;

    mapping(uint256 => string) private _tokenURIs;

    modifier onlyPropertyDeveloper() {
        require(
            msg.sender == propertyDetails.PropertyOwner,
            "Access Denied: You are not the Property Owner"
        );
        _;
    }

    modifier isEligibleToClaimROI() {
        if (roiPeriod == ROIPeriod.Monthly) {
            require(
                block.timestamp >=
                    lastClaimROITime[msg.sender][propertyDetails.PropertyID] +
                        30 days,
                "ROI can only be claimed once per month"
            );
        } else if (roiPeriod == ROIPeriod.Yearly) {
            require(
                block.timestamp >=
                    lastClaimROITime[msg.sender][propertyDetails.PropertyID] +
                        365 days,
                "ROI can only be claimed once per yearly"
            );
        }
        _;
    }

    function initialize(
        uint256 _perFractionPriceInNative,
        uint256 _perFractionPriceInEVOX,
        string memory _propertyUri,
        uint256 fractions,
        address owner,
        address _factoryAddress,
        address _EVOXToken,
        address _usdtTokenAddress,
        uint256 _propertyID,
        uint256 _ROIPercentage,
        uint8 _roiPeriod
    ) public initializer {
        __ERC1155_init(_propertyUri);
        __Ownable_init(owner);
        __ERC1155Supply_init();
        __ReentrancyGuard_init();

        propertyDetails.PropertyOwner = owner;
        propertyDetails.PropertyUri = _propertyUri;
        propertyDetails.perFractionPriceInNative = _perFractionPriceInNative;
        propertyDetails.perFractionPriceInEVOX = _perFractionPriceInEVOX;
        propertyDetails.ROIPercentage = _ROIPercentage;
        propertyDetails.PropertyID = _propertyID;
        propertyDetails.totalFractions = fractions;
        propertyDetails.availableFractions = fractions;
        propertyDetails.isPropertyCreated = true;
        isPropertyCreated[address(this)] = true;
        FactoryAddress = _factoryAddress;
        EvoxToken = IERC20(_EVOXToken);
        USDTAddress = IERC20(_usdtTokenAddress);

        priceFeeds[priceFeedBNB] = AggregatorV3Interface(priceFeedBNB);
        priceFeeds[priceFeedEVOX] = AggregatorV3Interface(priceFeedEVOX);

        if (_roiPeriod == 0) {
            roiPeriod = ROIPeriod.Monthly;
        } else {
            roiPeriod = ROIPeriod.Yearly;
        }

        _setTokenURI(_propertyID, _propertyUri);
    }

    function getUserDetail(
        address user
    )
        external
        view
        returns (
            address Buyer,
            uint256 InvestmentInEVOX,
            uint256 InvestmentInNative,
            string memory PropertyURI,
            uint256 PurchaseFractions,
            uint256 PurchaseTime
        )
    {
        UserDetail storage userDetails = User[user][propertyDetails.PropertyID];
        return (
            Buyer = userDetails.User,
            InvestmentInEVOX = userDetails.InvestmentAmountInNativeInEVOXToken,
            InvestmentInNative = userDetails
                .InvestmentAmountInNativeInNativeCurrency,
            PropertyURI = userDetails.PropertyUri,
            PurchaseFractions = userDetails.PurchaseFractions,
            PurchaseTime = userDetails.PurchasingTime
        );
    }

    function buyPropertyFractions(
        uint256 propertyFractions
    ) external payable nonReentrant {
        UserDetail storage users = User[msg.sender][propertyDetails.PropertyID];
        uint256 amountRequire = propertyFractions *
            propertyDetails.perFractionPriceInNative;
        require(
            msg.value >= amountRequire,
            "InSufficient Amount to purchase Property Fractions"
        );
        require(propertyDetails.isPropertyCreated, "Property: Not Existed");
        require(
            propertyFractions > 0 &&
                propertyFractions <= propertyDetails.availableFractions,
            "Property: Out Of Stock"
        );

        propertyDetails.availableFractions -= propertyFractions;
        TrackFractions[msg.sender][
            propertyDetails.PropertyID
        ] += propertyFractions;

        InvestmentAmountInNative[msg.sender] += amountRequire;

        users.User = msg.sender;
        users.PropertyUri = propertyDetails.PropertyUri;
        users.InvestmentAmountInNativeInNativeCurrency += amountRequire;
        users.AvailableFractions = propertyDetails.availableFractions;
        users.totalFractions = propertyDetails.totalFractions;
        users.PurchaseFractions += propertyFractions;
        users.PurchasingTime = block.timestamp;

        payable(propertyDetails.PropertyOwner).transfer(amountRequire);

        _mint(msg.sender, propertyDetails.PropertyID, propertyFractions, "");

        updateUserPortfolio(
            msg.sender,
            address(this),
            propertyDetails.PropertyID,
            propertyDetails.PropertyUri,
            block.timestamp,
            users.InvestmentAmountInNativeInEVOXToken,
            users.InvestmentAmountInNativeInNativeCurrency,
            users.PurchaseFractions,
            propertyDetails.availableFractions,
            propertyDetails.totalFractions
        );
        getBuyFractionsInfo(
            msg.sender,
            propertyDetails.PropertyID,
            propertyFractions,
            amountRequire,
            block.timestamp
        );

        emit BuyPropertyFractions(
            propertyDetails.PropertyID,
            propertyFractions,
            amountRequire
        );
    }

    function trackInvestmentAmountInNative() public view returns (uint256) {
        return InvestmentAmountInNative[msg.sender];
    }

    function buyFractionByEVOXTokens(
        uint256 propertyFractions
    ) external nonReentrant {
        UserDetail storage users = User[msg.sender][propertyDetails.PropertyID];
        require(propertyDetails.isPropertyCreated, "Property: Not Existed");
        require(
            propertyFractions > 0 &&
                propertyFractions <= propertyDetails.availableFractions,
            "Property: Out Of Stock"
        );

        uint256 requireAmount = propertyFractions *
            propertyDetails.perFractionPriceInEVOX;

        require(
            EvoxToken.balanceOf(msg.sender) >= requireAmount,
            "Insufficient EVOX Token to purchase Property"
        );

        propertyDetails.availableFractions -= propertyFractions;
        TrackFractions[msg.sender][
            propertyDetails.PropertyID
        ] += propertyFractions;

        InvestmentAmountInEVOXToken[msg.sender] += requireAmount;

        users.User = msg.sender;
        users.PropertyUri = propertyDetails.PropertyUri;
        users.AvailableFractions = propertyDetails.availableFractions;
        users.totalFractions = propertyDetails.totalFractions;
        users.InvestmentAmountInNativeInEVOXToken += requireAmount;
        users.PurchaseFractions += propertyFractions;
        users.PurchasingTime = block.timestamp;

        EvoxToken.transferFrom(
            msg.sender,
            propertyDetails.PropertyOwner,
            requireAmount
        );

        _mint(msg.sender, propertyDetails.PropertyID, propertyFractions, "");

        updateUserPortfolio(
            msg.sender,
            address(this),
            propertyDetails.PropertyID,
            propertyDetails.PropertyUri,
            block.timestamp,
            users.InvestmentAmountInNativeInEVOXToken,
            users.InvestmentAmountInNativeInNativeCurrency,
            users.PurchaseFractions,
            propertyDetails.availableFractions,
            propertyDetails.totalFractions
        );

        getBuyFractionsInfo(
            msg.sender,
            propertyDetails.PropertyID,
            propertyFractions,
            requireAmount,
            block.timestamp
        );

        emit BuyPropertyFractions(
            propertyDetails.PropertyID,
            propertyFractions,
            requireAmount
        );
    }

    function getOwnedPropertyShares(
        address user,
        uint256 propertyID
    ) public view returns (uint256 OwnFractions) {
        return OwnFractions = TrackFractions[user][propertyID];
    }

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

    function depositROI()
        external
        onlyPropertyDeveloper
        isEligibleToClaimROI
        nonReentrant
    {
        (uint256 _roiAmount, uint256 dueAmount )= calculateDepositROIAmount();
        require(
            USDTAddress.balanceOf(msg.sender) >= _roiAmount,
            "InSufficient Balance"
        );
        require(
            USDTAddress.allowance(msg.sender, address(this)) >= _roiAmount,
            "Insufficient Allowance"
        );

        bool success = USDTAddress.transferFrom(
            msg.sender,
            address(this),
            _roiAmount
        );

        propertyDetails.ROIDepositAmount = _roiAmount;
        propertyDetails.totalROIDepositAmount += _roiAmount;
        propertyDetails.ROIDepositTime = block.timestamp;
        lastROIDepositTime[msg.sender][propertyDetails.PropertyID] = block
            .timestamp;

        if (success) {
            depositHistroy(
                address(this),
                propertyDetails.PropertyID,
                _roiAmount,
                block.timestamp,
                uint8(TransactionStatus.Completed)
            );
        } else {
            depositHistroy(
                address(this),
                propertyDetails.PropertyID,
                _roiAmount,
                block.timestamp,
                uint8(TransactionStatus.Failed)
            );
        }

        depositData(
            address(this),
            propertyDetails.PropertyID,
            _roiAmount,
            propertyDetails.totalROIDepositAmount,
            dueAmount
        );

        emit ROIDeposit(
            msg.sender,
            propertyDetails.PropertyID,
            _roiAmount,
            dueAmount,
            block.timestamp
        );
    }

    function claimROI() external isEligibleToClaimROI nonReentrant {
        UserDetail storage users = User[msg.sender][propertyDetails.PropertyID];
        require(msg.sender != address(0), "Invalid Address");

        require(
            balanceOf(msg.sender, propertyDetails.PropertyID) > 0,
            "No Property Fractions Owned"
        );

        require(
            USDTAddress.balanceOf(address(this)) > 0,
            "InSufficient USDT in pool"
        );

        uint256 amount = _calculateUserROI(msg.sender);

        lastClaimROITime[msg.sender][propertyDetails.PropertyID] = block
            .timestamp;

        users.Claimer = msg.sender;
        users.ClaimAmount = amount;
        users.ClaimTime = block.timestamp;
        require(
            USDTAddress.transfer(msg.sender, amount),
            "ROI transfer failed"
        );

        getClaimROIHistroy(
            users.Claimer,
            propertyDetails.PropertyID,
            users.ClaimAmount,
            users.ClaimTime
        );

        emit ClaimROIAmount(msg.sender, amount, users.ClaimTime);
    }

    function PropertyCreated(address hostContract) public view returns (bool) {
        return isPropertyCreated[hostContract];
    }

    function _calculateUserROI(address _user) internal view returns (uint256) {
        uint256 ROIPercentage = propertyDetails.ROIPercentage;
        uint256 InvestmentInNative = InvestmentAmountInNative[_user];
        uint256 InvestmentInEVOX = InvestmentAmountInEVOXToken[_user];

        uint256 NativeROI = (InvestmentInNative * ROIPercentage) /
            (100 * 10 ** 18);
        uint256 EVOXROI = (InvestmentInEVOX * ROIPercentage) / (100 * 10 ** 18);

        uint256 amount = NativeROI + EVOXROI;

        return amount;
    }

    function calculateDepositROIAmount()
        public
        view
        returns (uint256, uint256)
    {
        uint256 soldFractions = propertyDetails.totalFractions -
            propertyDetails.availableFractions;
        uint256 ROIPercent = propertyDetails.ROIPercentage;
        uint256 PriceInNative = propertyDetails.perFractionPriceInNative;
        uint256 PriceInEVOX = propertyDetails.perFractionPriceInEVOX;
        uint256 getNativeUSDTAmount = getLatestPrice(priceFeedBNB);
        uint256 getEVOXUSDTAmount = getLatestPrice(priceFeedEVOX);

        uint256 DepositAmountInNative = (soldFractions *
            PriceInNative *
            ROIPercent) / (100 * 10 ** 18);
        uint256 depositAmountInEVOX = (soldFractions *
            PriceInEVOX *
            ROIPercent) / (100 * 10 ** 18);

        uint256 NativeAmount = (DepositAmountInNative * getNativeUSDTAmount) /
            1e18;
        uint256 EVOXAmount = (depositAmountInEVOX * getEVOXUSDTAmount) / 1e18;

        uint256 depositAmount = NativeAmount + EVOXAmount;

        uint256 totalDepositAmountInNative = (propertyDetails.totalFractions *
            PriceInNative *
            ROIPercent) / (100 * 10 ** 18);
        uint256 totaldepositAmountInEVOX = (propertyDetails.totalFractions *
            PriceInEVOX *
            ROIPercent) / (100 * 10 ** 18);

        uint256 nativeAmount = (totalDepositAmountInNative *
            getNativeUSDTAmount) / 1e18;
        uint256 evoxAmount = (totaldepositAmountInEVOX * getEVOXUSDTAmount) /
            1e18;
        uint256 totalAmount = nativeAmount + evoxAmount;
        uint256 dueAmount = totalAmount - propertyDetails.totalROIDepositAmount;

        return (depositAmount, dueAmount);
    }

    function _setTokenURI(
        uint256 _propertyID,
        string memory _propertyUri
    ) internal {
        require(msg.sender != address(0), "User not Existed");
        _tokenURIs[_propertyID] = _propertyUri;
    }

    function tokenUri(uint256 _propertyID) public view returns (string memory) {
        return _tokenURIs[_propertyID];
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._update(from, to, ids, values);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
