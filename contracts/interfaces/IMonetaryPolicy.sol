// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IOracle.sol";

interface IMonetaryPolicy {
    function setOrchestrator(address orchestrator_) external;

    function setTokenPriceOracle(IOracle tokenPriceOracle_) external;

    function setDeviationThreshold(uint256 deviationThreshold_) external;

    function setRebaseLag(uint256 rebaseLag_) external;

    function setRebaseTimingParameters(
        uint256 minRebaseTimeIntervalSec_,
        uint256 rebaseWindowOffsetSec_,
        uint256 rebaseWindowLengthSec_
    ) external;

    function stablize(address pool, uint256 amount) external;

    function rebase() external;
}
