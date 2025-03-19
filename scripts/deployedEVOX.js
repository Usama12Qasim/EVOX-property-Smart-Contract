// scripts/deployEventDeployer.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  // // Replace with actual token and funds wallet addresses
  let [owner, admin, addr1, addr2, addr3, addr4, addr5, walletAddress] = await ethers.getSigners();

  const EVOXFactoryContract = await ethers.getContractFactory("EVOXFactory");
  let deployedEVOXFactoryContract = await EVOXFactoryContract.deploy();
  await deployedEVOXFactoryContract.connect(owner).waitForDeployment();

  console.log("EVOX Factory Contract deployed to:", deployedEVOXFactoryContract.target);

  // //EVOX Ticketing Nft Contract
  const EVOXNftContract = await ethers.getContractFactory("PropertyCreation");

  let deployedEVOXTicketingContract = await EVOXNftContract.deploy();

  // Wait for the contract to be deployed
  await deployedEVOXTicketingContract.connect(owner).waitForDeployment();
  console.log("EVOX ERC-1155 deployed to:", deployedEVOXTicketingContract.target);

  // const EVOXStaking = await ethers.getContractFactory("IGOPresale");

  // let deployedEVOXStaking = await EVOXStaking.deploy();

  // // Wait for the contract to be deployed
  // await deployedEVOXStaking.connect(owner).waitForDeployment();
  // console.log("EvoxPresale deployed to:", deployedEVOXStaking.target);

}
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });


//EVOX Factory Contract deployed to: 0xc6ab2F05AaA3F7C2C579B60589f2744fA1583e28
//NatirumToken deployed to: 0x34b0733295e97bA6Dcd0674977cEe51Fcd12f46a