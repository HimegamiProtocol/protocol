const Orchestrator = artifacts.require("Orchestrator");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const { getSavedContractAddresses, saveContractAddress } = require("./utils");

module.exports = async function (deployer, network) {
  const addresses = getSavedContractAddresses()[network];
  await upgradeProxy(addresses.Orchestrator, Orchestrator, {
    deployer,
    unsafeAllowCustomTypes: true,
    initializer: "initialize",
  });
  let orchestrator = await Orchestrator.deployed();
  console.log("Orchestrator deployed to:", orchestrator.address);
  saveContractAddress(network, "OrchestratorV2", orchestrator.address);
};
