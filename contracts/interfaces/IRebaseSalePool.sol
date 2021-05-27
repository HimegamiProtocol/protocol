// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IRebaseSalePool {
    function setToken(address kgr_) external;

    function setBondToken(address kgrb_) external;

    function setRateBuy(uint256 rate_) external;

    function getRateBuy() external view returns (uint256);

    function setRateSell(uint256 rate_) external;

    function getRateSell() external view returns (uint256);

    function setSaleCommissionPercent(uint256 percent_) external;

    function setKGRbGenerationPercent(uint256 percent_) external;

    function setExchangeFeePerTenThousand(uint256 fee_) external;

    function getExchangeFeePerTenThousand() external;

    function withdraw() external;

    function buyKGR() external;

    function sellKGR(uint256 amountKGR) external;
}
