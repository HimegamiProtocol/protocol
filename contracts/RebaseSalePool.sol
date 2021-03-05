// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import "./interfaces/IElasticToken.sol";

contract RebaseSalePool is OwnableUpgradeSafe {
    using SafeMath for uint256;

    IElasticToken public KGR;

    // Exchangerate ETHKGR with fixed point 18 decimal
    uint256 private constant DECIMALS = 18;
    // Keep this variable for save upgrade contract
    uint256 public rateETHKGR;

    uint256 public rateBuy;

    uint256 public saleCommissionPercent;

    event LogBuy(address buyer, uint256 amountKGR, uint256 amountETH);

    function initialize() external initializer {
        __Ownable_init();
    }

    function setToken(address kgr_) external onlyOwner {
        KGR = IElasticToken(kgr_);
    }

    function setRateBuy(uint256 rate_) external onlyOwner {
        rateBuy = rate_;
    }

    function setSaleCommissionPercent(uint256 percent_) external onlyOwner {
        require(percent_ < 100);
        saleCommissionPercent = percent_;
    }

    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    /*
     * @title Customer buy KGR with fixed price use ETH
     * owner will receive sale commission
     */
    function buyKGR() external payable {
        require(rateBuy > 0 && msg.value > 0);
        uint256 amountKGR = msg.value.mul(rateBuy).div(10**DECIMALS);
        if (saleCommissionPercent > 0) {
            uint256 commission = msg.value.mul(saleCommissionPercent).div(100);
            payable(owner()).transfer(commission);
        }
        KGR.transfer(msg.sender, amountKGR);
        emit LogBuy(msg.sender, amountKGR, msg.value);
    }

    function getRateBuy() external view returns (uint256) {
        return rateBuy;
    }
}
