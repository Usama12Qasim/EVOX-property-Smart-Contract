//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./EVOXToken.sol";

contract EVOXStaking is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    event StakeToken(
        address Staker,
        uint256 StakeAmount,
        bool isStaked
    );

    event ClaimReward(address Claimer, uint256 RewardAmount, uint256 ClaimTime);
    event WithDrawReward(address User, uint256 RewardAmount);

    struct StakeInfo {
        address Staker;
        uint256 StakingAmount;
        bool isStake;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(address => StakeInfo) public UserInfo;
    mapping(address => uint256) public lastClaimRewardTime;
    mapping(address => uint256) public RewardAmount;
    IERC20 public EvoxToken;
    uint256 public totalStaked;
    uint256 private APY;

    function initialize(IERC20 _EvoxToken, uint256 _APY) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        EvoxToken = _EvoxToken;
        APY = _APY;
    }

    function updateAPY(uint256 _APY) external onlyOwner nonReentrant {
        require(_APY != 0, "Invalid Amount");
        APY = _APY;
    }

    function stakeToken(uint256 amount) external nonReentrant {
        StakeInfo storage info = UserInfo[msg.sender];
        require(EvoxToken.balanceOf(msg.sender) >= amount && amount > 0, "Insufficient balance");
        EvoxToken.transferFrom(msg.sender, address(this), amount);

        info.Staker = msg.sender;
        info.StakingAmount = amount;
        info.isStake = true;
        totalStaked += amount;

        emit StakeToken(msg.sender, amount, true);

    }

    // function unStakeNft(uint256 propertyID) external nonReentrant {
    //     StakeInfo memory info = UserInfo[msg.sender];
    //     require(
    //         info.Staker == msg.sender && msg.sender != address(0),
    //         "You are not Property Fraction Owner"
    //     );
    //     require(info.isStake, "Property Fraction is not Staked");




    //     delete UserInfo[msg.sender];
    // }

    // function withDraw() external nonReentrant {
    //     StakeInfo memory info = UserInfo[msg.sender];
    //     require(RewardAmount[msg.sender] > 0, "Rewards already WithDraw");
    //     require(info.Staker == msg.sender, "Only Staker withDraw Reward");
    //     require(
    //         EvoxToken.balanceOf(address(this)) > RewardAmount[msg.sender],
    //         "Insufficient rewards in pool"
    //     );

    //     uint256 Reward = RewardAmount[msg.sender];
    //     RewardAmount[msg.sender] = 0;

    //     EvoxToken.safeTransfer(msg.sender, Reward);

    //     emit WithDrawReward(msg.sender, Reward);
    // }

    // function claimReward() external nonReentrant {
    //     StakeInfo memory info = UserInfo[msg.sender];
    //     require(info.isStake, "Property Fractions is not Staked");

    //     require(block.timestamp <= info.endTime, "Staking Period is over");
    //     require(
    //         block.timestamp >= lastClaimRewardTime[msg.sender] + 30 days &&
    //             block.timestamp >= info.startTime + 30 days,
    //         "Reward claimed Only Once In a Month"
    //     );

    //     uint256 Reward = _calculateReward(msg.sender);
    //     RewardAmount[msg.sender] += Reward;

    //     lastClaimRewardTime[msg.sender] = block.timestamp;

    //     emit ClaimReward(msg.sender, Reward, block.timestamp);
    // }

    // function _calculateReward(address _user) public view returns (uint256) {
    //     StakeInfo memory info = UserInfo[_user];
    //     require(info.Staker == _user, "You are not Staker");
    //     require(info.NftFractions > 0, "No Staked Fractions Available");

    //     //uint256 calculateReward = (info.NftFractions * APY ) / 12 * 100;

    //     uint256 timeElapsed = block.timestamp - info.startTime;
    //     uint256 timeElapsedInMonths = timeElapsed / 2592000;
    //     uint256 monthlyRate = APY / 12;
    //     uint256 calculateReward = info.NftFractions *
    //         monthlyRate *
    //         timeElapsedInMonths;

    //     return calculateReward;
    // }
}
