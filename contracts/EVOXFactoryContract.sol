//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PropertyCreation} from "./EVOXProperty.sol";
import {EVOXSubgraph} from "./EVOXSubgraphData.sol";

contract EVOXFactory is OwnableUpgradeable, EVOXSubgraph {
    using SafeERC20 for IERC20;
    using Address for address payable;

    event deployedProperty(
        address PropertyDeveloper,
        address Property,
        uint256 perFractionPriceInNative,
        uint256 perFractionPriceInEVOX,
        string PropertyUri,
        uint256 PropertyFractions,
        uint256 PropertyID,
        uint256 _ROIPercentage
    );

    mapping(uint256 => address) public deployedContractAddresses;
    uint256 public contractCount;

    function initialize() public override initializer {
        __Ownable_init(msg.sender);
        EVOXSubgraph.initialize();
    }

    function deployNewProperty(
        uint256 _perFractionPriceInNative,
        uint256 _perFractionPriceInEVOX,
        string memory _propertyUri,
        uint256 fractions,
        uint256 _ROIPercentage,
        IERC20 _EVOXToken,
        IERC20 _usdtTokenAddress,
        uint8 _roiPeriod
    ) public returns (address) {
        PropertyCreation newProperty = new PropertyCreation();
        newProperty.initialize(
            _perFractionPriceInNative,
            _perFractionPriceInEVOX,
            _propertyUri,
            fractions,
            msg.sender,
            address(this),
            address(_EVOXToken),
            address(_usdtTokenAddress),
            contractCount,
            _ROIPercentage,
            _roiPeriod
        );

        deployedContractAddresses[contractCount] = address(newProperty);

        emit deployedProperty(
            msg.sender,
            address(newProperty),
            _perFractionPriceInNative,
            _perFractionPriceInEVOX,
            _propertyUri,
            fractions,
            contractCount,
            _ROIPercentage
        );

        contractCount++;

        return address(newProperty);
    }
}
