const BuyBackPool = artifacts.require("BuybackPool");
const FounderPool = artifacts.require("FounderPool");
const KGRToken = artifacts.require("KGRToken");
const MonetaryPolicy = artifacts.require("MonetaryPolicy");
const Orchestrator = artifacts.require("Orchestrator");
const RebaseSalePool = artifacts.require("RebaseSalePool");
const StakePool = artifacts.require("StakePool");

const { getConfig } = require("./utils");

const BN = web3.utils.BN;

const TEN_POW_18 = new BN(10).pow(new BN(18));
const REBASE_SALE = new BN(100000).mul(TEN_POW_18);

module.exports = async function (deployer, network) {
  const config = getConfig()[network];

  let buyBackPool = await BuyBackPool.deployed();
  let founderPool = await FounderPool.deployed();
  let stakePool = await StakePool.deployed();
  let rebaseSalePool = await RebaseSalePool.deployed();
  let token = await KGRToken.deployed();
  let monetaryPolicy = await MonetaryPolicy.deployed();
  let orchestrator = await Orchestrator.deployed();

  //set token
  await buyBackPool.setToken(token.address);
  await founderPool.setToken(token.address);
  await stakePool.setToken(token.address);
  await rebaseSalePool.setToken(token.address);
  console.log("Done! Set token address");

  //set orchestrator
  await monetaryPolicy.setOrchestrator(orchestrator.address);
  console.log("Done! Set orchestrator");

  //set oracle
  await monetaryPolicy.setTokenPriceOracle(config.tokenPriceOracle);
  console.log("Done! Set Oracle");

  //set monetory policy
  await token.setMonetaryPolicy(monetaryPolicy.address);
  console.log("Done! Set Policy");

  //set rebase sale pool
  await orchestrator.setRebaseSalePool(rebaseSalePool.address, REBASE_SALE);
  console.log("Done! Set Rebase Sale Pool");

  //set founders
  for (let i = 0; i < config.founders.length; i++) {
    await founderPool.addFounder(config.founders[i].address, config.founders[i].weight);
  }
  console.log("Done! Set Founder");
};
