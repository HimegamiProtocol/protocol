const AirdropLiquidityProviderPool = artifacts.require("AirdropLiquidityProviderPool");
const AirdropTokenHolderPool = artifacts.require("AirdropTokenHolderPool");
const OMKToken = artifacts.require("OMKToken");

const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const { saveContractAddress } = require("./utils");

module.exports = async function (deployer, network) {
  let tokenHolderPool = await AirdropTokenHolderPool.deployed();
  let liquidityProviderPool = await AirdropLiquidityProviderPool.deployed();

  await deployProxy(
    OMKToken,
    [100, tokenHolderPool.address, 50, liquidityProviderPool.address, 30, 20],
    {
      deployer,
      initializer: "initialize",
    }
  );
  let omk = await OMKToken.deployed();
  console.log("OMKToken deployed to:", omk.address);
  saveContractAddress(network, "OMKToken", omk.address);

  await tokenHolderPool.setGovToken(omk.address);
  console.log("Added Gov token to Airdrop Token Holder Pool");

  await liquidityProviderPool.setGovToken(omk.address);
  console.log("Added Gov token to Airdrop Liquidity Provider Pool");
};
