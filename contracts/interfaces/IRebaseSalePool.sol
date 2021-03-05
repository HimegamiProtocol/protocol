// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IRebaseSalePool {
    function setToken(address kgr_) external;

    function setRateBuy(uint256 rate_) external;

    function setSaleCommissionPercent(uint256 percent_) external;

    function withdraw() external;

    function buyKGR() external;

    function getRateBuy() external view returns (uint256);
}
