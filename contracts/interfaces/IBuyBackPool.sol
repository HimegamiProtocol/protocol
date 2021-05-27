// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBuyBackPool {
    function setToken(address kgr_) external;

    function setExchangeRate(uint256 rate_) external;

    function sellKGR(uint256 amountKGR) external;
}
