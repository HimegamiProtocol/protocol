const KGRToken = artifacts.require("KGRToken");
const FounderPool = artifacts.require("FounderPool");
const StakePool = artifacts.require("StakePool");

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const { getConfig, saveContractAddress } = require("./utils");

module.exports = async function (deployer, network) {
  const config = getConfig()[network];
  let founderPool = await FounderPool.deployed();
  let stakePool = await StakePool.deployed();

  await deployProxy(
    KGRToken,
    [
      config.totalWeight,
      founderPool.address,
      config.founderPoolWeight,
      stakePool.address,
      config.stakePookWeight,
      config.presalePoolWeight,
    ],
    {
      deployer,
      initializer: "initialize",
    }
  );
  let token = await KGRToken.deployed();
  console.log("KGRToken deployed to:", token.address);
  saveContractAddress(network, "KGRToken", token.address);
};
