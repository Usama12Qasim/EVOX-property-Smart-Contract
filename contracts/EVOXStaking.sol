//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./EVOXProperty.sol";

contract EVOXStaking is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PropertyCreation
{
    using SafeERC20 for IERC20;

    event StakeNft(
        address Staker,
        uint256 PropertyID,
        uint256 NftFractions,
        uint256 startTime,
        uint256 endTime,
        bool isStaked
    );

    event ClaimReward(address Claimer, uint256 RewardAmount, uint256 ClaimTime);

    struct StakeInfo {
        address Staker;
        address PropertyAddress;
        uint256 PropertyID;
        uint256 NftFractions;
        bool isStake;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(address => StakeInfo) public UserInfo;
    mapping(address => uint256) public lastClaimRewardTime;
    mapping(address => uint256) public RewardAmount;
    IERC20 public RewardToken;
    uint256 public totalStaked;
    uint256 private APY;

    function initialize(IERC20 _EvoxToken, uint256 _APY) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        RewardToken = _EvoxToken;
        APY = _APY;
    }

    function updateAPY(uint256 _APY) external onlyOwner nonReentrant {
        require(_APY != 0, "Invalid Amount");
        APY = _APY;
    }

    function stakeNft(
        address _propertyAddress,
        uint256 propertyID,
        uint256 _propertyFraction,
        uint256 _endTime
    ) external nonReentrant {
        StakeInfo storage info = UserInfo[msg.sender];
        PropertyCreation property = PropertyCreation(_propertyAddress);

        require(property.exists(propertyID), "Property ID: Not Existed");
        require(
            property.balanceOf(msg.sender, propertyID) >= _propertyFraction &&
                _propertyFraction > 0,
            "No Fraction Availabe"
        );

        require(!info.isStake, "Already Staked");
        require(
            block.timestamp < _endTime && info.startTime < _endTime,
            "Time Error"
        );

        info.Staker = msg.sender;
        info.PropertyAddress = _propertyAddress;
        info.PropertyID = propertyID;
        info.NftFractions = _propertyFraction;
        info.startTime = block.timestamp;
        info.endTime = _endTime;
        info.isStake = true;
        totalStaked += _propertyFraction;

        property.safeTransferFrom(
            msg.sender,
            address(this),
            propertyID,
            _propertyFraction,
            ""
        );

        emit StakeNft(
            msg.sender,
            propertyID,
            _propertyFraction,
            block.timestamp,
            _endTime,
            true
        );
    }

    function unStakeNft(uint256 propertyID) external nonReentrant {
        StakeInfo memory info = UserInfo[msg.sender];
        require(
            info.Staker == msg.sender && msg.sender != address(0),
            "You are not Property Fraction Owner"
        );
        require(info.isStake, "Property Fraction is not Staked");

        safeTransferFrom(
            address(this),
            msg.sender,
            propertyID,
            info.NftFractions,
            ""
        );

        totalStaked -= info.NftFractions;

        delete UserInfo[msg.sender];
    }

    function withDraw() external nonReentrant {
        StakeInfo memory info = UserInfo[msg.sender];
        require(RewardAmount[msg.sender] > 0, "Rewards already WithDraw");
        require(info.Staker == msg.sender, "Only Staker withDraw Reward");
        require(
            RewardToken.balanceOf(address(this)) > RewardAmount[msg.sender],
            "Insufficient rewards in pool"
        );

        uint256 Reward = RewardAmount[msg.sender];
        RewardAmount[msg.sender] = 0;

        RewardToken.safeTransfer(msg.sender, Reward);
    }

    function claimReward() external nonReentrant {
        StakeInfo memory info = UserInfo[msg.sender];
        require(info.isStake, "Property Fractions is not Staked");

        require(block.timestamp <= info.endTime, "Staking Period is over");
        require(
            block.timestamp >= lastClaimRewardTime[msg.sender] + 30 days,
            "Reward claimed Only Once In a Month"
        );

        uint256 Reward = _calculateReward(msg.sender);
        RewardAmount[msg.sender] += Reward;

        lastClaimRewardTime[msg.sender] = block.timestamp;

        emit ClaimReward(msg.sender, Reward, block.timestamp);
    }

    function _calculateReward(address _user) public view returns (uint256) {
        StakeInfo memory info = UserInfo[_user];
        require(info.Staker == _user, "You are not Staker");
        require(info.NftFractions > 0, "No Staked Fractions Available");

        uint256 timeElapsed = block.timestamp - info.startTime;
        uint256 monthlyRate = APY / 12;
        uint256 calculateReward = (info.NftFractions *
            monthlyRate *
            timeElapsed) / 10000 ;

        return calculateReward;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
