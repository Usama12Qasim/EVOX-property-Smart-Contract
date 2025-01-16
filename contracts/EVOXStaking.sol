//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./EVOXProperty.sol";
import "./EVOXMarketplace.sol";

contract EVOXStaking is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PropertyCreation
{
    using SafeERC20 for IERC20;

    event Stake(
        address Staker,
        uint256 PropertyID,
        uint256 NftFractions,
        uint256 startTime,
        uint256 endTime,
        bool isStaked
    );

    struct StakeInfo {
        address Staker;
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
    uint256 private APY;

    function initialize(IERC20 _EvoxToken, uint256 _APY) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        RewardToken = _EvoxToken;
        APY = _APY;
    }

    function stakeNft(
        uint256 propertyID,
        uint256 _propertyFraction,
        uint256 _endTime
    ) external nonReentrant {
        StakeInfo storage info = UserInfo[msg.sender];

        require(exists(propertyID), "Property ID: Not Existed");
        require(
            balanceOf(msg.sender, propertyID) >= _propertyFraction &&
                _propertyFraction > 0,
            "No Fraction Availabe"
        );

        require(!info.isStake, "Already Staked");
        require(
            info.startTime != _endTime &&
                block.timestamp < _endTime &&
                info.startTime < _endTime,
            "Time Error"
        );

        info.Staker = msg.sender;
        info.PropertyID = propertyID;
        info.NftFractions = _propertyFraction;
        info.startTime = block.timestamp;
        info.endTime = _endTime;
        info.isStake = true;

        safeTransferFrom(
            msg.sender,
            address(this),
            propertyID,
            _propertyFraction,
            ""
        );
    }

    function unStakeNft(uint256 propertyID) external nonReentrant {
        StakeInfo memory info = UserInfo[msg.sender];
        require(
            info.Staker == msg.sender,
            "You are not Property Fraction Owner"
        );
        require(info.isStake, "Property Fraction is not Staked");

        _claimReward(msg.sender);

        safeTransferFrom(
            address(this),
            msg.sender,
            propertyID,
            info.NftFractions,
            ""
        );

        delete UserInfo[msg.sender];
    }

    function claimReward() external nonReentrant {
        StakeInfo memory info = UserInfo[msg.sender];
        require(info.isStake, "Property Fractions is not Staked");
        require(
            block.timestamp >= lastClaimRewardTime[msg.sender] + 30 days,
            "Reward claimed Only Once In a Month"
        );

        require(block.timestamp <= info.endTime, "Staking Period is over");
        _claimReward(msg.sender);
    }

    function _claimReward(address _user) internal {
        uint256 Reward = _calculateReward(_user);
        RewardAmount[_user] += Reward;

        require(
            RewardToken.balanceOf(address(this)) >= Reward,
            "InSufficient Reward Amount"
        );

        lastClaimRewardTime[_user] = block.timestamp;

        RewardAmount[_user] = 0;

        RewardToken.transfer(_user, Reward);
    }

    function _calculateReward(address _user) internal view returns (uint256) {
        StakeInfo memory info = UserInfo[_user];
        require(info.Staker == _user, "You are not Staker");
        require(info.NftFractions > 0, "No Staked Fractions Available");
        uint256 timeElapsed = block.timestamp - info.startTime;
        uint256 monthlyRate = APY / 12;
        uint256 calculateReward = (info.NftFractions *
            monthlyRate *
            timeElapsed) / (30 days * 10000);

        return calculateReward;
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
}
