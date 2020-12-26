const RebaseSalePool = artifacts.require("RebaseSalePool");

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const { saveContractAddress } = require("./utils");

module.exports = async function (deployer, network) {
  await deployProxy(RebaseSalePool, [], { deployer, initializer: "initialize" });
  let rebaseSalePool = await RebaseSalePool.deployed();
  console.log("RebaseSalePool deployed to:", rebaseSalePool.address);
  saveContractAddress(network, "RebaseSalePool", rebaseSalePool.address);
};
