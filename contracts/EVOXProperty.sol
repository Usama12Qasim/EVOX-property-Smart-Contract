// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {ERC1155SupplyUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract PropertyCreation is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    ERC1155SupplyUpgradeable
{
    struct PropertyDetail {
        address PropertyOwner;
        string PropertyName;
        string PropertyUri;
        uint256 PropertyPrice;
        uint256 perFractionprice;
        uint256 totalFractions;
        uint256 PropertyID;
        uint256 ROIPercentage;
    }

    PropertyDetail public propertyDetails;
    address public FactoryAddress;
    address public fundsWallet;
    IERC20 public EVOXToken;

    mapping(uint256 => PropertyDetail) properties;
    mapping(uint256 => string) private _tokenURIs;

    function initialize(
        string memory _propertyName,
        string memory _propertyUri,
        uint256 _propertyPrice,
        uint256 _perFractionPrice,
        uint256 _maxSupply,
        uint256 _ROIPercentage,
        address owner,
        address _factoryAddress,
        address _fundsWallet,
        address _EVOXToken,
        uint256 _propertyID
    ) public initializer {
        __ERC1155_init(_propertyUri);
        __Ownable_init(owner);
        __ERC1155Supply_init();

        fundsWallet = _fundsWallet;
        EVOXToken = IERC20(_EVOXToken);

        propertyDetails.PropertyOwner = owner;
        propertyDetails.PropertyUri = _propertyUri;
        propertyDetails.PropertyName = _propertyName;
        propertyDetails.PropertyPrice = _propertyPrice;
        propertyDetails.perFractionprice = _perFractionPrice;
        propertyDetails.ROIPercentage = _ROIPercentage;
        FactoryAddress = _factoryAddress;

        _mint(_propertyID, _propertyUri, _maxSupply);
    }

    function _mint(
        uint256 propertyID,
        string memory _propertyUri,
        uint256 amount
    ) internal {
        propertyDetails.totalFractions = amount;
        propertyDetails.PropertyID = propertyID;

        _mint(msg.sender, propertyID, amount, "");
        _setTokenURI(propertyID, _propertyUri);
    }

    function getPropertyInfo(
        uint256 _propertyID
    ) public view returns (PropertyDetail memory) {
        return properties[_propertyID];
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
}
