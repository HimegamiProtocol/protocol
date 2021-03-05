pragma solidity 0.6.12;

import "./interfaces/IUniswapV2Pair.sol";

contract Utils {
    address constant uniFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    function genUniAddr(address left, address right)
        internal
        pure
        returns (IUniswapV2Pair)
    {
        address first = left < right ? left : right;
        address second = left < right ? right : left;
        address pairAddr =
            address(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            uniFactory,
                            keccak256(abi.encodePacked(first, second)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                        )
                    )
                )
            );
        return IUniswapV2Pair(pairAddr);
    }
}
