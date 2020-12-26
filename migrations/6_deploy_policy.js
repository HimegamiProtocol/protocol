const KGRToken = artifacts.require("KGRToken");
const MonetaryPolicy = artifacts.require("MonetaryPolicy");

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const { saveContractAddress } = require("./utils");

module.exports = async function (deployer, network) {
  let token = await KGRToken.deployed();
  await deployProxy(MonetaryPolicy, [token.address], {
    deployer,
    initializer: "initialize",
  });
  let monetaryPolicy = await MonetaryPolicy.deployed();
  console.log("MonetaryPolicy deployed to:", monetaryPolicy.address);
  saveContractAddress(network, "MonetaryPolicy", monetaryPolicy.address);
};
