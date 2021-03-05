pragma solidity 0.6.12;

import "./Mock.sol";
import "../lib/UInt256Lib.sol";

contract MockUInt256Lib is Mock {
    function toInt256Safe(uint256 a) external returns (int256) {
        int256 result = UInt256Lib.toInt256Safe(a);
        emit ReturnValueInt256(result);
        return result;
    }
}
