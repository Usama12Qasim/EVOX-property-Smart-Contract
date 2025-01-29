const { expect } = require("chai")
const { ethers, upgrades } = require("hardhat");

describe("Natrium Marketpalce", function () {

  let owner;
  let admin;
  let addr1;
  let buyer1;
  let buyer2;
  let buyer3;
  let buyer4;

  let deployedEVOXFactoryContract;
  let deployedEVOXTicketingContract;
  let deployedEVOXMarketplace;
  let deployedEVOXStaking;
  let deployedEVOXToken;

  beforeEach(async () => {
    [
      owner,
      admin,
      addr1,
      minter1,
      minter2,
      minter3,
      buyer1,
      buyer2,
      buyer3,
      buyer4,
      walletlet,
      _usdtTokenlet
    ] = await ethers.getSigners();


    const EVOXFactoryContract = await ethers.getContractFactory("EVOXFactory");
    deployedEVOXFactoryContract = await EVOXFactoryContract.deploy();
    await deployedEVOXFactoryContract.connect(owner).waitForDeployment();

    //console.log("EVOX Factory Contract deployed to:", deployedEVOXFactoryContract.target);

    //EVOX Ticketing Nft Contract
    const EVOXNftContract = await ethers.getContractFactory("PropertyCreation");

    deployedEVOXTicketingContract = await EVOXNftContract.deploy();

    // Wait for the contract to be deployed
    await deployedEVOXTicketingContract.connect(owner).waitForDeployment();
    //console.log("EVOX ERC-1155 deployed to:", deployedEVOXTicketingContract.target);

    //console.log("EVOX Marketplace deployed to:", deployedEVOXMarketplace.target);

    const EVOXStaking = await ethers.getContractFactory("EVOXStaking");

    deployedEVOXStaking = await EVOXStaking.deploy();

    // Wait for the contract to be deployed
    await deployedEVOXStaking.connect(owner).waitForDeployment();
    //console.log("EVOX Staking deployed to:", deployedEVOXStaking.target);

    const EVOXToken = await ethers.getContractFactory("MyToken");

    deployedEVOXToken = await EVOXToken.deploy();

    // Wait for the contract to be deployed
    await deployedEVOXToken.connect(owner).waitForDeployment();
    //console.log("EVOX Token deployed to:", deployedEVOXToken.target);

  });

  describe("Create Property", function () {
    it("should deploy new property", async () => {
      let _propertyName = "EVOX";
      let _propertyUri = "EVOX.com"
      let _maxSupply = 100;

      await deployedEVOXFactoryContract.connect(buyer1).deployNewProperty(
        _propertyName,
        _propertyUri,
        _maxSupply,
        addr1.address
      )
      await deployedEVOXFactoryContract.connect(buyer1).deployNewProperty(
        _propertyName,
        _propertyUri,
        _maxSupply,
        addr1.address
      )
      await deployedEVOXFactoryContract.connect(buyer1).deployNewProperty(
        _propertyName,
        _propertyUri,
        _maxSupply,
        addr1.address
      )
      await deployedEVOXFactoryContract.connect(buyer1).deployNewProperty(
        _propertyName,
        _propertyUri,
        _maxSupply,
        addr1.address
      )

      let PropertyID0 = await deployedEVOXFactoryContract.deployedContractAddresses(0);
      let PropertyID1 = await deployedEVOXFactoryContract.deployedContractAddresses(1);
      let PropertyID2 = await deployedEVOXFactoryContract.deployedContractAddresses(2);
      let PropertyID3 = await deployedEVOXFactoryContract.deployedContractAddresses(3);
      console.log("Property ID of 0", PropertyID0);
      console.log("Property ID of 1", PropertyID1);
      console.log("Property ID of 2", PropertyID2);
      console.log("Property ID of 3", PropertyID3);

    });

    it("Stake Nfts and get EVOX Reward", async () => {
      let _propertyName = "Sea Side Villa";
      let _propertyUri = "ww.EVOX.com";
      let fractions = 10;
      let _propertyID = 1;
      await deployedEVOXTicketingContract.connect(buyer1).initialize(
        _propertyName, 
        _propertyUri, 
        fractions, 
        buyer1.address, 
        deployedEVOXFactoryContract.target, 
        deployedEVOXToken.target,
        _propertyID
      );

      await deployedEVOXTicketingContract.connect(buyer2).buyPropertyFractions(5, {value: ethers.parseEther("5")});

      let BalanceofBuyer2 = await deployedEVOXTicketingContract.balanceOf(buyer2.address, 1);
      console.log("Balance of Buyer2 ", BalanceofBuyer2);

      await deployedEVOXStaking.connect(addr1).initialize(deployedEVOXToken.target, 12);

      let getBlockNumber = await ethers.provider.getBlockNumber();
      getBlock = await ethers.provider.getBlock(getBlockNumber);
      blockTimestamp = getBlock.timestamp;

      let endTime = blockTimestamp + (365 * 86400);

      await deployedEVOXTicketingContract.connect(buyer2).setApprovalForAll(deployedEVOXStaking.target, true);
      await deployedEVOXStaking.connect(buyer2).stakeNft(deployedEVOXTicketingContract.target,_propertyID, 5, endTime);

      let PassedDay = 30 * (24 * 60 * 60);

      await ethers.provider.send('evm_increaseTime', [PassedDay]);
      await ethers.provider.send('evm_mine')

      let Reward = await deployedEVOXStaking._calculateReward(buyer2.address);
      console.log("Reward", Reward);

      await deployedEVOXStaking.connect(buyer2).claimReward();
      let PassedDay30 = 30 * (24 * 60 * 60);

      await ethers.provider.send('evm_increaseTime', [PassedDay30]);
      await ethers.provider.send('evm_mine')
      await deployedEVOXStaking.connect(buyer2).claimReward();

      let checkReward = await deployedEVOXStaking.RewardAmount(buyer2.address);
      console.log("Check Reward", checkReward);
    })
  });
});