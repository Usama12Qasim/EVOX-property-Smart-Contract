//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PropertyCreation} from "./EVOXProperty.sol";

contract EVOXFactory is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    mapping(uint256 => address) public deployedContractAddresses;
    uint256 public contractCount;

    address public fundsWallet;
    IERC20 public EVOXToken;

    function initialize(
        address _fundsWallet,
        address _EVOXToken
    ) public initializer {
        __Ownable_init(msg.sender);
        fundsWallet = _fundsWallet;
        EVOXToken = IERC20(_EVOXToken);
    }

    function setFundsWallet(address _fundsWallet) public onlyOwner {
        fundsWallet = _fundsWallet;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        EVOXToken = IERC20(_tokenAddress);
    }

    function deployNewProperty(
        string memory _propertyName,
        string memory _propertyUri,
        uint256 _propertyPrice,
        uint256 _perFractionPrice,
        uint256 _ROIPercentage,
        uint256 _maxSupply,
        IERC20 _EVOXToken,
        address _fundsWallet
    ) public returns (address) {
        PropertyCreation newProperty = new PropertyCreation();
        newProperty.initialize(
            _propertyName,
            _propertyUri,
            _propertyPrice,
            _perFractionPrice,
            _maxSupply,
            _ROIPercentage,
            msg.sender,
            address(this),
            _fundsWallet,
            address(_EVOXToken),
            contractCount
        );

        deployedContractAddresses[contractCount] = address(newProperty);
        contractCount++;

        return address(newProperty);
    }
}
