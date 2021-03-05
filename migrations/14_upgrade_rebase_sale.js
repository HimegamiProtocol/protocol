const RebaseSalePool = artifacts.require("RebaseSalePool");
const BuyBackPool = artifacts.require("BuybackPool");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const { getSavedContractAddresses, saveContractAddress } = require("./utils");

module.exports = async function (deployer, network) {
  const addresses = getSavedContractAddresses()[network];
  await upgradeProxy(addresses.RebaseSalePool, RebaseSalePool, {
    deployer,
    initializer: "initialize",
  });
  let salepool = await RebaseSalePool.deployed();
  console.log("RebaseSalePool deployed to:", salepool.address);
  saveContractAddress(network, "RebaseSalePoolV2", salepool.address);

  await upgradeProxy(addresses.BuyBackPool, BuyBackPool, {
    deployer,
    initializer: "initialize",
  });
  let bbpool = await BuyBackPool.deployed();
  console.log("BuyBackPool deployed to:", bbpool.address);
  saveContractAddress(network, "BuyBackPoolV2", bbpool.address);
};
