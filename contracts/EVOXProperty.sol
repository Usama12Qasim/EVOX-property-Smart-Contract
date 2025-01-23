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
    ERC1155SupplyUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    
    event BuyPropertyFractions(
        uint256 PropertyID,
        uint256 PropertyFractions,
        uint256 purchasePrice
    );

    event ClaimROIAmount(
        address FractionOwner,
        uint256 RoiAmount,
        uint256 ClaimTime
    );

    struct PropertyDetail {
        address PropertyOwner;
        string PropertyName;
        string PropertyUri;
        uint256 totalFractions;
        uint256 PropertyID;
        uint256 availableFractions;
    }

    PropertyDetail public propertyDetails;
    mapping(address => mapping(uint256 => uint256)) public TrackFractions;
    mapping(address => mapping(uint256 => uint256)) public lastClaimROITime;
    address public FactoryAddress;
    IERC20 public EvoxToken;

    mapping(uint256 => string) private _tokenURIs;

    function initialize(
        string memory _propertyName,
        string memory _propertyUri,
        uint256 fractions,
        address owner,
        address _factoryAddress,
        address _EVOXToken,
        uint256 _propertyID
    ) public initializer {
        __ERC1155_init(_propertyUri);
        __Ownable_init(owner);
        __ERC1155Supply_init();
        __ReentrancyGuard_init();

        propertyDetails.PropertyOwner = owner;
        propertyDetails.PropertyUri = _propertyUri;
        propertyDetails.PropertyName = _propertyName;
        propertyDetails.PropertyID = _propertyID;
        propertyDetails.totalFractions = fractions;
        propertyDetails.availableFractions = fractions;
        FactoryAddress = _factoryAddress;
        EvoxToken = IERC20(_EVOXToken);

        _setTokenURI(_propertyID, _propertyUri);
    }

    function buyPropertyFractions(
        uint256 propertyFractions
    ) external payable nonReentrant {
        require(exists(propertyDetails.PropertyID), "Property: Not Existed");
        require(
            propertyFractions > 0 &&
                propertyFractions <= propertyDetails.availableFractions,
            "Property: Out Of Stock"
        );

        require(msg.value > 0, "InSufficient Amount");

        propertyDetails.availableFractions -= propertyFractions;
        TrackFractions[msg.sender][
            propertyDetails.PropertyID
        ] += propertyFractions;

        payable(propertyDetails.PropertyOwner).transfer(msg.value);

        _mint(msg.sender, propertyDetails.PropertyID, propertyFractions, "");

        emit BuyPropertyFractions(
            propertyDetails.PropertyID,
            propertyFractions,
            msg.value
        );
    }

    function buyFractionByEVOXTokens(
        uint256 propertyFractions,
        uint256 amount
    ) external nonReentrant {
        require(exists(propertyDetails.PropertyID), "Property: Not Existed");
        require(
            propertyFractions > 0 &&
                propertyFractions <= propertyDetails.availableFractions,
            "Property: Out Of Stock"
        );

        require(
            EvoxToken.balanceOf(msg.sender) >= amount,
            "Insufficient Amount to purchase Property"
        );

        propertyDetails.availableFractions -= propertyFractions;
        TrackFractions[msg.sender][
            propertyDetails.PropertyID
        ] += propertyFractions;

        EvoxToken.transferFrom(
            msg.sender,
            propertyDetails.PropertyOwner,
            amount
        );

        _mint(msg.sender, propertyDetails.PropertyID, propertyFractions, "");

        emit BuyPropertyFractions(
            propertyDetails.PropertyID,
            propertyFractions,
            amount
        );
    }

    function claimROI(
        uint256 propertyID,
        uint256 amount
    ) external nonReentrant {
        uint256 userShares = TrackFractions[msg.sender][propertyID];
        require(userShares > 0, "No Property Fractions Owned");
        require(msg.sender != address(0), "Invalid Address");

        _claimROI(propertyID, amount);
    }

    function _claimROI(uint256 propertyID, uint256 amount) internal {
        require(
            block.timestamp >=
                lastClaimROITime[msg.sender][propertyID] + 30 days,
            "ROI can only be claimed once per month"
        );

        require(amount > 0, "No ROI available for claim");

        lastClaimROITime[msg.sender][propertyID] = block.timestamp;

        payable(msg.sender).transfer(amount);

        emit ClaimROIAmount(msg.sender, amount, block.timestamp);
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
