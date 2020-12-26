const StakePool = artifacts.require("StakePool");

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const { saveContractAddress } = require("./utils");

module.exports = async function (deployer, network) {
  await deployProxy(StakePool, [], {
    deployer,
    unsafeAllowCustomTypes: true,
    initializer: "initialize",
  });
  let stakePool = await StakePool.deployed();
  console.log("StakePool deployed to:", stakePool.address);
  saveContractAddress(network, "StakePool", stakePool.address);
};
