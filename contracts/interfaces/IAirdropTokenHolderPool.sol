// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IAirdropTokenHolderPool {
    event LogTimingParameterUpdate(uint256 interval);
    event LogDistributionLagUpdate(uint256 lag);
    event LogElasticTokenUpdate(address elasticTokenAddr);
    event LogGovTokenUpdate(address govTokenAddr);
    event LogAddTokenHolder(address holderAddr);
    event LogDistribution(uint256 afterTotalSupply);
    event LogAirdropPaused(bool paused);
    event LogLatestSupplyUpdate(uint256 supply);

    function distribute() external;

    function distributev2(address holderAddr, uint256 amount) external;

    function addTokenHolder(address holderAddr) external;

    function setTimingParameter(uint256 minDistributionTimeIntervalSec)
        external;

    function setDistributionLag(uint256 lag) external;

    function setElasticToken(address elasticTokenAddr) external;

    function setGovToken(address govTokenAddr) external;

    function isExist(address holderAddr) external view returns (bool);

    function setAirdropPaused(bool paused) external;

    function updateLatestSupply() external;
}
