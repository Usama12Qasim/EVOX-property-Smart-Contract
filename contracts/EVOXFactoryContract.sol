//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PropertyCreation} from "./EVOXProperty.sol";

contract EVOXFactory is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    mapping(uint256 => address) public deployedContractAddresses;
    uint256 public contractCount;

    function initialize() public initializer {
        __Ownable_init(msg.sender);
    }

    function deployNewProperty(
        string memory _propertyName,
        string memory _propertyUri,
        uint256 fractions,
        IERC20 _EVOXToken
    ) public returns (address) {
        PropertyCreation newProperty = new PropertyCreation();
        newProperty.initialize(
            _propertyName,
            _propertyUri,
            fractions,
            msg.sender,
            address(this),
            address(_EVOXToken),
            contractCount
        );

        deployedContractAddresses[contractCount] = address(newProperty);
        contractCount++;

        return address(newProperty);
    }
}
