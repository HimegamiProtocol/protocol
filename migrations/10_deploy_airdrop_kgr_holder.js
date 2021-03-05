const AirdropTokenHolderPool = artifacts.require("AirdropTokenHolderPool");

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const { getSavedContractAddresses, saveContractAddress } = require("./utils");

module.exports = async function (deployer, network) {
  const addresses = getSavedContractAddresses()[network];
  await deployProxy(AirdropTokenHolderPool, [addresses.KGRToken], {
    deployer,
    initializer: "initialize",
  });
  let pool = await AirdropTokenHolderPool.deployed();
  console.log("AirdropTokenHolderPool deployed to:", pool.address);
  saveContractAddress(network, "AirdropTokenHolderPool", pool.address);
};
