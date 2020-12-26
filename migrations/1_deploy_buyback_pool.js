const BuyBackPool = artifacts.require("BuybackPool");

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const { saveContractAddress } = require("./utils");

module.exports = async function (deployer, network) {
  await deployProxy(BuyBackPool, [], { deployer, initializer: "initialize" });
  let buyBackPool = await BuyBackPool.deployed();
  console.log("BuyBackPool deployed to:", buyBackPool.address);
  saveContractAddress(network, "BuyBackPool", buyBackPool.address);
};
