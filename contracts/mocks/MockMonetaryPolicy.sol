pragma solidity 0.6.12;

import "./Mock.sol";

contract MockMonetaryPolicy is Mock {
    function rebase() external {
        emit FunctionCalled("MonetaryPolicy", "rebase", msg.sender);
    }

    function stablize(address, uint256) external {
        emit FunctionCalled("MonetaryPolicy", "stablize", msg.sender);
    }
}
