//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./EVOXProperty.sol";

contract EVOXPropertyMarketplace is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PropertyCreation
{
    using SafeERC20 for IERC20;

    event PropertyApproved(uint256 PropertyID, bool approved, string);
    event BuyPropertyFractions(
        uint256 PropertyID,
        uint256 PropertyFractions,
        uint256 purchasePrice
    );
    event ROIDeposit(
        address PropertyOwner,
        uint256 PropertyID,
        uint256 ROIAmount,
        uint256 DepositTime
    );
    event ClaimROIAmount(
        address FractionOwner,
        uint256 RoiAmount,
        uint256 ClaimTime
    );
    struct PropertyInfo {
        address Seller;
        uint256 propertyID;
        uint256 totalFractions;
        uint256 availableFractions;
        address[] propertyFractionsOwner;
        uint256 PropertyPrice;
        uint256 perFractionPropertyPrice;
        uint256 totalROI;
        uint256 ROIPercentage;
        uint256 depositROITime;
        bool isApproved;
    }

    mapping(uint256 => PropertyInfo) property;
    mapping(address => mapping(uint256 => uint256)) public TrackFractions;
    mapping(address => mapping(uint256 => uint256)) public lastClaimROITime;
    mapping(uint256 => uint256) public TrackROIAmount;

    IERC20 public EvoxToken;

    modifier onlyApprovedProperty(uint256 propertyID) {
        require(
            property[propertyID].isApproved,
            "Property not Approved by admin"
        );
        _;
    }

    modifier onlyDeveloper(uint256 propertyID) {
        require(
            property[propertyID].Seller == msg.sender,
            "Not the Property Developer"
        );
        _;
    }

    function initialize(IERC20 _EVOXToken) public initializer {
        EvoxToken = _EVOXToken;
    }

    function approveProperty(
        uint256 propertyID
    ) external onlyOwner nonReentrant {
        PropertyInfo storage Property = property[propertyID];

        require(exists(propertyID), "Property ID: Doesn't Exist");
        Property.isApproved = true;

        _update(propertyID);

        emit PropertyApproved(
            propertyID,
            true,
            "Property is now Approved by Admin"
        );
    }

    function buyPropertyFractions(
        uint256 propertyID,
        uint256 propertyFractions
    ) external payable onlyApprovedProperty(propertyID) nonReentrant {
        PropertyInfo storage Property = property[propertyID];

        require(exists(propertyID), "Property ID: Doesn't Exist");
        require(
            propertyFractions <= Property.availableFractions,
            "Property: Out Of Stock"
        );
        uint256 perFractionPrice = Property.perFractionPropertyPrice;
        uint256 RequiredAmount = propertyFractions * perFractionPrice;
        require(
            msg.value == RequiredAmount && msg.value > 0,
            "Incorrect payment amount"
        );

        Property.availableFractions -= propertyFractions;
        TrackFractions[msg.sender][propertyID] += propertyFractions;
        Property.propertyFractionsOwner.push(msg.sender);

        payable(Property.Seller).transfer(RequiredAmount);

        emit BuyPropertyFractions(
            propertyID,
            propertyFractions,
            RequiredAmount
        );
    }

    function buyFractionByEVOXTokens(
        uint256 propertyID,
        uint256 propertyFractions
    ) external onlyApprovedProperty(propertyID) nonReentrant {
        PropertyInfo storage Property = property[propertyID];

        require(exists(propertyID), "Property ID: Doesn't Exist");
        require(
            propertyFractions <= Property.availableFractions,
            "Property: Out Of Stock"
        );
        uint256 perFractionPrice = Property.perFractionPropertyPrice;
        uint256 RequiredAmount = propertyFractions * perFractionPrice;

        require(
            RequiredAmount == EvoxToken.allowance(msg.sender, Property.Seller),
            "Insufficient Allowance"
        );

        Property.availableFractions -= propertyFractions;
        TrackFractions[msg.sender][propertyID] += propertyFractions;
        Property.propertyFractionsOwner.push(msg.sender);

        EvoxToken.transferFrom(msg.sender, Property.Seller, RequiredAmount);
    }

    function depositROI(
        uint256 propertyID,
        uint256 _ROIAmount
    )
        external
        payable
        onlyApprovedProperty(propertyID)
        onlyDeveloper(propertyID)
        nonReentrant
    {
        PropertyInfo storage Property = property[propertyID];

        require(msg.value == _ROIAmount, "Invalid ROI Amount");
        require(
            block.timestamp >= Property.depositROITime + 30 days,
            "ROI can only be deposited once per month"
        );

        Property.depositROITime = block.timestamp;
        TrackROIAmount[propertyID] += msg.value;
        Property.totalROI += msg.value;

        emit ROIDeposit(msg.sender, propertyID, _ROIAmount, block.timestamp);
    }

    function claimROI(uint256 propertyID) external nonReentrant {
        uint256 userShares = TrackFractions[msg.sender][propertyID];
        require(userShares > 0, "No Property Fractions Owned");

        _claimROI(propertyID);
    }

    function _claimROI(uint256 propertyID) internal {
        require(
            block.timestamp >=
                lastClaimROITime[msg.sender][propertyID] + 30 days,
            "ROI can only be claimed once per month"
        );

        uint256 totalROIForProperty = TrackROIAmount[propertyID];
        require(totalROIForProperty > 0, "No ROI available for claim");

        uint256 userShare = calculateUserROI(msg.sender, propertyID);
        TrackROIAmount[propertyID] -= userShare;

        lastClaimROITime[msg.sender][propertyID] = block.timestamp;

        payable(msg.sender).transfer(userShare);

        emit ClaimROIAmount(msg.sender, userShare, block.timestamp);
    }

    function calculateUserROI(
        address shareHolder,
        uint256 propertyID
    ) internal view returns (uint256) {
        PropertyInfo memory Property = property[propertyID];
        uint256 userShares = TrackFractions[shareHolder][propertyID];

        uint256 totalROI = TrackROIAmount[propertyID];
        uint256 totalFractions = Property.totalFractions;
        uint256 ROIPercentage = Property.ROIPercentage;

        require(totalFractions > 0, "No Fractions Available");
        uint256 CalculateROIAmount = (totalROI * ROIPercentage) / 100;
        uint256 ROIAmount = CalculateROIAmount / totalFractions;

        uint256 UserShare = userShares * ROIAmount;

        return UserShare;
    }

    function _update(uint256 propertyID) internal nonReentrant {
        PropertyInfo storage Property = property[propertyID];
        Property.propertyID = PropertyCreation.propertyDetails.PropertyID;
        Property.totalFractions = PropertyCreation
            .propertyDetails
            .totalFractions;
        Property.PropertyPrice = PropertyCreation.propertyDetails.PropertyPrice;
        Property.perFractionPropertyPrice = PropertyCreation
            .propertyDetails
            .perFractionprice;
        Property.Seller = PropertyCreation.propertyDetails.PropertyOwner;
        Property.availableFractions = PropertyCreation
            .propertyDetails
            .totalFractions;
        Property.ROIPercentage = PropertyCreation.propertyDetails.ROIPercentage;
    }
}
