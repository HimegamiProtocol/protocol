const MonetaryPolicy = artifacts.require("MonetaryPolicy");
const Orchestrator = artifacts.require("Orchestrator");

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const { saveContractAddress } = require("./utils");

module.exports = async function (deployer, network) {
  let monetaryPolicy = await MonetaryPolicy.deployed();

  await deployProxy(Orchestrator, [monetaryPolicy.address], {
    deployer,
    unsafeAllowCustomTypes: true,
    initializer: "initialize",
  });
  let orchestrator = await Orchestrator.deployed();
  console.log("Orchestrator deployed to:", orchestrator.address);
  saveContractAddress(network, "Orchestrator", orchestrator.address);
};
