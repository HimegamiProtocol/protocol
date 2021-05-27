pragma solidity 0.6.12;

interface IAirdropLiquidityProviderPool {
    event LogElasticTokenUpdate(address token);
    event LogGovTokenUpdate(address token);
    event LogDistributionLagUpdate(uint256 lag);
    event LogTimingParameterUpdate(uint256 windowSec);
    event LogDistributeIncentive(address provider, uint256 amount);
    event LogAirdropPaused(bool paused);

    function setElasticToken(address token) external;

    function setGovToken(address token) external;

    function setDistributionLag(uint256 lag) external;

    function setTimingParameter(uint256 windowSec) external;

    function recordLiquidityProvider(address provider) external;

    function setAirdropPaused(bool paused) external;
}
