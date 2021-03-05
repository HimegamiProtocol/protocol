const AirdropTokenHolderPool = artifacts.require("AirdropTokenHolderPool");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const { getSavedContractAddresses, saveContractAddress } = require("./utils");

module.exports = async function (deployer, network) {
  const addresses = getSavedContractAddresses()[network];
  await upgradeProxy(addresses.AirdropTokenHolderPool, AirdropTokenHolderPool, {
    deployer,
    initializer: "initialize",
  });
  let pool = await AirdropTokenHolderPool.deployed();
  console.log("AirdropTokenHolderPool deployed to:", pool.address);
  saveContractAddress(network, "AirdropTokenHolderPoolV2", pool.address);
};
