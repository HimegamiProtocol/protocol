// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IRebaseSalePool {
    function setToken(address kgr_) external;

    function setExchangeRate(uint256 rate_) external;

    function buyKGR() external;
}
