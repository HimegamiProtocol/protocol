const FounderPool = artifacts.require("FounderPool");

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const { saveContractAddress } = require("./utils");

module.exports = async function (deployer, network) {
  await deployProxy(FounderPool, [], {
    deployer,
    unsafeAllowCustomTypes: true,
    initializer: "initialize",
  });
  let founderPool = await FounderPool.deployed();
  console.log("FounderPool deployed to:", founderPool.address);
  saveContractAddress(network, "FounderPool", founderPool.address);
};
