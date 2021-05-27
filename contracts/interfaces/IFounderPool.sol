// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IFounderPool {
    function setToken(address kgr_) external;

    function addFounder(address addr_, uint256 weight_) external;

    function withdraw() external;
}
