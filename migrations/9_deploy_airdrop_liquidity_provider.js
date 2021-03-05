const AirdropLiquidityProviderPool = artifacts.require("AirdropLiquidityProviderPool");

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const { getConfig, getSavedContractAddresses, saveContractAddress } = require("./utils");

module.exports = async function (deployer, network) {
  const config = getConfig()[network];
  const addresses = getSavedContractAddresses()[network];
  await deployProxy(AirdropLiquidityProviderPool, [addresses.KGRToken, config.WETHToken], {
    deployer,
    unsafeAllowCustomTypes: true,
    initializer: "initialize",
  });
  let pool = await AirdropLiquidityProviderPool.deployed();
  console.log("AirdropLiquidityProviderPool deployed to:", pool.address);
  saveContractAddress(network, "AirdropLiquidityProviderPool", pool.address);
};
