// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStakePool {
    function setToken(address kgr_) external;

    function withdraw(uint256 amount) external;

    function createDeal(uint256 level_, uint256 amount_) external;

    function takeProfit() external returns (bool);
}
