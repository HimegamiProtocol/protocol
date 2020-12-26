// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IOrchestrator {
    function rebase() external;

    function setRebaseSalePool(address pool_, uint256 amount_) external;

    function setRebaseSalePaused(bool paused) external;

    function addUniPair(address token1, address token2) external;

    function deleteUniPair(uint256 index) external;

    function setUniPairEnabled(uint256 index, bool enabled) external;
}
