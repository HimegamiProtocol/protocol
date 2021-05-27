// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IElasticToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external returns (uint256);

    function rebase(uint256 epoch, int256 supplyDelta)
        external
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function getSharePerToken() external view returns (uint256);

    function stablize(address pool, uint256 amount) external;
}
