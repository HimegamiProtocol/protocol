// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import "./interfaces/IElasticToken.sol";

contract RebaseSalePool is OwnableUpgradeSafe {
    using SafeMath for uint256;

    IElasticToken public KGR;

    // Exchangerate ETHKGR with fixed point 18 decimal
    uint256 public rateETHKGR;

    event LogSalePoolRateUpdated(uint256 newRate_);
    event LogSalePoolSell(address buyer, uint256 amountKGR, uint256 amountETH);

    function initialize() external initializer {
        __Ownable_init();
    }

    function setToken(address kgr_) external onlyOwner {
        KGR = IElasticToken(kgr_);
    }

    function setExchangeRate(uint256 rate_) external onlyOwner {
        rateETHKGR = rate_;
        emit LogSalePoolRateUpdated(rate_);
    }

    /*
     * @title Customer buy KGR with fixed price use ETH
     * ETH Will be foward to owner address
     */
    function buyKGR() external payable {
        require(rateETHKGR > 0 && msg.value > 0);
        uint256 amountKGR = msg.value.mul(rateETHKGR).div(10**18);
        payable(owner()).transfer(msg.value);
        KGR.transfer(msg.sender, amountKGR);
        emit LogSalePoolSell(msg.sender, amountKGR, msg.value);
    }
}
