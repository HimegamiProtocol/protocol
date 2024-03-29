pragma solidity 0.6.12;

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function token0() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function sync() external;
}
