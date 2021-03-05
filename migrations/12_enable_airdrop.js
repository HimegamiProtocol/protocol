const AirdropLiquidityProviderPool = artifacts.require("AirdropLiquidityProviderPool");
const AirdropTokenHolderPool = artifacts.require("AirdropTokenHolderPool");

module.exports = async function (deployer, network) {
  let tokenHolderPool = await AirdropTokenHolderPool.deployed();
  let liquidityProviderPool = await AirdropLiquidityProviderPool.deployed();

  await tokenHolderPool.setAirdropPaused(false);

  await liquidityProviderPool.setAirdropPaused(false);

  await tokenHolderPool.updateLatestSupply();
};
