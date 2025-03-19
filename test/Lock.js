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
  let deployedEVOXPreSale;
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

    const EVOXToken = await ethers.getContractFactory("EVOXToken");

    deployedEVOXToken = await EVOXToken.deploy();

    // Wait for the contract to be deployed
    await deployedEVOXToken.connect(owner).waitForDeployment();
    //console.log("EVOX Token deployed to:", deployedEVOXToken.target);

    const EVOXPreSale = await ethers.getContractFactory("IGOPresale");

    deployedEVOXPreSale = await EVOXPreSale.deploy();

    // Wait for the contract to be deployed
    await deployedEVOXPreSale.connect(owner).waitForDeployment();
    //console.log("EVOX Token deployed to:", deployedEVOXToken.target);

  });

  describe("Create Property", function () {
    it("Stake Nfts and get EVOX Reward", async () => {
      // let fractionprice = "0.16539132899721";
      // let perFractionPrice = ethers.parseUnits(fractionprice);
      // let _perFractionPriceInEVOX = ethers.parseUnits("500");
      // let _propertyUri = "ww.EVOX.com";
      // let ROIAmount = ethers.parseUnits("500")
      // let fractions = 200;
      // let _propertyID = 1;
      // let ROIPerccenatge = 12000000000000000000n;
      // await deployedEVOXTicketingContract.connect(buyer1).initialize(
      //   perFractionPrice,
      //   _perFractionPriceInEVOX,
      //   _propertyUri,
      //   fractions,
      //   buyer1.address,
      //   deployedEVOXFactoryContract.target,
      //   deployedEVOXToken.target,
      //   deployedEVOXToken.target,
      //   _propertyID,
      //   ROIPerccenatge,
      //   0
      // );



      // // let bool = await deployedEVOXTicketingContract.PropertyCreated(deployedEVOXTicketingContract.target);
      // // console.log("BOOL", bool);

      //  await deployedEVOXTicketingContract.connect(buyer2).buyPropertyFractions(7, { value: ethers.parseUnits("50") });

      // await deployedEVOXToken.connect(buyer2).mint(50000000)
      // await deployedEVOXToken.connect(buyer2).approve(deployedEVOXTicketingContract.target, 500000000000000000000000n);


      // await deployedEVOXTicketingContract.connect(buyer2).buyFractionByEVOXTokens(10);


      // // let TrackFraction = await deployedEVOXTicketingContract.getOwnedPropertyShares(buyer2.address, 1);
      // // console.log("TRACK Fraction", TrackFraction);

      // await deployedEVOXToken.connect(buyer1).mint(5000)
      // await deployedEVOXToken.connect(buyer1).approve(deployedEVOXTicketingContract.target, 10000000000000000000000n)
      // let amount = await deployedEVOXTicketingContract.calculateDepositROIAmount();
      // await deployedEVOXTicketingContract.connect(buyer1).depositROI(ROIAmount);
      // await deployedEVOXTicketingContract.connect(buyer1).depositROI(ROIAmount);
      // await deployedEVOXTicketingContract.connect(buyer1).depositROI(ROIAmount);
      // let due = await deployedEVOXTicketingContract.calculateDepositROIAmount();
      // console.log("Amount", due)
       
      // let ListNFT2 = await deployedEVOXTicketingContract.queryFilter("DepositData");
      // let NFT2 = ListNFT2[0];
      // let PropertyID = NFT2.args.DepositAmount;
      // let DepositAmount = NFT2.args.DueAmount;
      // let DepositTime = NFT2.args.DepositTime;
      // let TransactionStatus = NFT2.args.TransactionStatus;


      // console.log(PropertyID,DepositAmount,DepositTime,TransactionStatus
      // );


      // //  await deployedEVOXTicketingContract.connect(buyer2).claimROI();

      // // let PassedDay = 365 * (24 * 60 * 60);

      // // await ethers.provider.send('evm_increaseTime', [PassedDay]);
      // // await ethers.provider.send('evm_mine')

      // // await deployedEVOXTicketingContract.connect(buyer2).claimROI();


      // // let ListNFT = await deployedEVOXTicketingContract.queryFilter("ClaimROIAmount");
      // // let NFT = ListNFT[0];
      // // let BuyeR = NFT.args.FractionOwner;
      // // let propertyAddress = NFT.args.RoiAmount;



      // //  console.log(BuyeR, propertyAddress)

      // // let ListNFT2 = await deployedEVOXFactoryContract.queryFilter("PropertyInfo");
      // // let NFT2 = ListNFT2[1];
      // // let Buyer = NFT2.args.PropertyName;
      // // let PropertyAddress = NFT2.args.PropertyOwner;
      // // let PropertyID = NFT2.args.perFractionPriceInNative;
      // // let PurchasingTime = NFT2.args.perFractionPriceInEVOX;
      // // let PropertyURI = NFT2.args.PropertyUri;
      // // let NAtive = NFT2.args.totalFractions;
      // // let EVOX = NFT2.args.availableFractions;
      // // let Fractions = NFT2.args.ROIDepositAmount;

      // // console.log(Buyer, PropertyAddress, PropertyID, PurchasingTime, PropertyURI, NAtive, EVOX, Fractions)

      // // await deployedEVOXStaking.connect(buyer1).initialize(deployedEVOXToken.target, 1200);
      // // //await deployedEVOXStaking.connect(buyer1).initialize(deployedEVOXToken.target, 12);

      // // let getBlockNumber = await ethers.provider.getBlockNumber();
      // // getBlock = await ethers.provider.getBlock(getBlockNumber);
      // // let EventStartDate = getBlock.timestamp;
      // // let EventEndDate = EventStartDate + (365 * 86400);
      // // await deployedEVOXToken.connect(buyer2).mint(1)

      // // await deployedEVOXToken.connect(buyer2).approve(deployedEVOXStaking.target, 10000000000000000000n);

      // // await deployedEVOXStaking.connect(buyer2).stakeToken(10000000000000000000n
      // // );

      
      // // let Passed = 360 * (24 * 60 * 60);

      // // await ethers.provider.send('evm_increaseTime', [Passed]);
      // // await ethers.provider.send('evm_mine')

      // // await deployedEVOXStaking.connect(buyer2).claimReward();

      // // let Pass = 30 * (24 * 60 * 60);

      // // await ethers.provider.send('evm_increaseTime', [Pass]);
      // // await ethers.provider.send('evm_mine')
      // // await deployedEVOXStaking.connect(buyer2).claimReward();

      // // let RewardAmount = await deployedEVOXStaking.connect(buyer2)._calculateReward(buyer2.address);
      // // console.log("reward amount", RewardAmount);

      // // let RewardAmounts = await deployedEVOXStaking.connect(buyer2).RewardAmount(buyer2.address);
      // // console.log("reward amount", RewardAmounts);
    });
    it("should Pre-Sale tokens", async() => {
      const currentTimestamp = Math.floor(Date.now() / 1000);
      let getBlockNumber = await ethers.provider.getBlockNumber();
      getBlock = await ethers.provider.getBlock(getBlockNumber);
      let EventStartDate = getBlock.timestamp;
      let _bnbAddress = addr1.address;
      let _usdtAddress = admin.address;
      let _priceFeedBNB = addr1.address;
      let _priceFeedUSDT = admin.address;
      let _fundsWallet = buyer1.address;
      let _maxCap = 1000000000000000000000000000n;
      let _token = deployedEVOXToken.target;
      let _minBuyAmount = 1000000000000000000n;
      let _maxBuyAmount = 10000000000000000000000000n
      let _tokenPrice = ethers.parseUnits("1");
      let _initialUnlock = 5;
      let _cliffDuration = 0;
      let TGE = EventStartDate + (30 * 86400);

      let _vestingDuration = 12;
      let _active = true;

      await deployedEVOXPreSale.connect(buyer1).initialize(
        _bnbAddress,
        _usdtAddress,
        _priceFeedBNB,
        _priceFeedUSDT,
        _fundsWallet,
        _maxCap,
        _token
      );

      await deployedEVOXPreSale.connect(buyer1).startRound(
        _minBuyAmount,
        6,
        _tokenPrice,
        _initialUnlock,
        _cliffDuration,
        _vestingDuration,
        _active
      );

      // let Rounds = await deployedEVOXPreSale.rounds(0);
      // console.log("Rounds", Rounds);

      await deployedEVOXToken.connect(buyer2).mint(10000);
      await deployedEVOXToken.connect(buyer2).approve(deployedEVOXPreSale.target, 100000000000000000000n);

       await deployedEVOXPreSale.connect(buyer2).buyWithToken(deployedEVOXToken.target, 5000000000000000000n);
       await deployedEVOXPreSale.connect(buyer2).buyWithToken(deployedEVOXToken.target, 7000000000000000000n);
       await deployedEVOXPreSale.connect(buyer2).buyWithToken(deployedEVOXToken.target, 9000000000000000000n);
      //await deployedEVOXPreSale.connect(buyer2).buyWithBNB({value: ethers.parseUnits("0.01")});

      await deployedEVOXPreSale.connect(buyer1).openClaiming();
      await deployedEVOXPreSale.connect(buyer1).tgeTime(TGE);
       await deployedEVOXToken.connect(buyer1).mint(200000000);
       await deployedEVOXToken.connect(buyer1).approve(deployedEVOXPreSale.target, 120620000000000000000000n);

      let PassedDay = 30 * (24 * 60 * 60);

      await ethers.provider.send('evm_increaseTime', [PassedDay]);
      await ethers.provider.send('evm_mine')

      await deployedEVOXPreSale.connect(buyer2).claim(0);

      let LET = 30 * (24 * 60 * 60);

      await ethers.provider.send('evm_increaseTime', [LET]);
      await ethers.provider.send('evm_mine')

     await deployedEVOXPreSale.connect(buyer2).claim(1);
      let Passedday = 1 * (30 * 24 * 60 * 60);

      await ethers.provider.send('evm_increaseTime', [Passedday]);
      await ethers.provider.send('evm_mine')

       await deployedEVOXPreSale.connect(buyer2).claimAll();

//        let one = 2 * (30 * 24 * 60 * 60);

//        await ethers.provider.send('evm_increaseTime', [one]);
//        await ethers.provider.send('evm_mine')
 
//         await deployedEVOXPreSale.connect(buyer2).claim(1);

//         let two = 3 * (30 * 24 * 60 * 60);

//         await ethers.provider.send('evm_increaseTime', [two]);
//         await ethers.provider.send('evm_mine')
  
//          await deployedEVOXPreSale.connect(buyer2).claim(1);

//          let three = 3 * (30 * 24 * 60 * 60);

//          await ethers.provider.send('evm_increaseTime', [three]);
//          await ethers.provider.send('evm_mine')
//         await deployedEVOXPreSale.connect(buyer2).claim(1);

//         let four = 3 * (30 * 24 * 60 * 60);

//         await ethers.provider.send('evm_increaseTime', [four]);
//         await ethers.provider.send('evm_mine')
//        await deployedEVOXPreSale.connect(buyer2).claim(1);

//        let five = 3 * (30 * 24 * 60 * 60);

//        await ethers.provider.send('evm_increaseTime', [five]);
//        await ethers.provider.send('evm_mine')
//       await deployedEVOXPreSale.connect(buyer2).claim(1);

//       let six = 3 * (30 * 24 * 60 * 60);

//       await ethers.provider.send('evm_increaseTime', [six]);
//       await ethers.provider.send('evm_mine')
//      await deployedEVOXPreSale.connect(buyer2).claim(1);

//      let sevene = 3 * (30 * 24 * 60 * 60);

//      await ethers.provider.send('evm_increaseTime', [sevene]);
//      await ethers.provider.send('evm_mine')
//     await deployedEVOXPreSale.connect(buyer2).claim(1);

//     let eight = 3 * (30 * 24 * 60 * 60);

//     await ethers.provider.send('evm_increaseTime', [eight]);
//     await ethers.provider.send('evm_mine')
//    await deployedEVOXPreSale.connect(buyer2).claim(1);

//    let nine = 3 * (30 * 24 * 60 * 60);

//    await ethers.provider.send('evm_increaseTime', [nine]);
//    await ethers.provider.send('evm_mine')
//   await deployedEVOXPreSale.connect(buyer2).claim(1);

//   let ten = 3 * (30 * 24 * 60 * 60);

//   await ethers.provider.send('evm_increaseTime', [ten]);
//   await ethers.provider.send('evm_mine')
//  await deployedEVOXPreSale.connect(buyer2).claim(1);

//  let eleven = 3 * (30 * 24 * 60 * 60);

//  await ethers.provider.send('evm_increaseTime', [ten]);
//  await ethers.provider.send('evm_mine')
// await deployedEVOXPreSale.connect(buyer2).claim();

      let UserPucahse = await deployedEVOXPreSale.connect(buyer2).userPurchases(buyer2.address, 0);
      console.log("User Purchase", UserPucahse);

      // let userdata = await deployedEVOXPreSale.connect(buyer2).getUserData(buyer2.address);
      // console.log("User Purchase", userdata);


    })
  });
});