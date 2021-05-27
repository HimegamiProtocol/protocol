// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import "./interfaces/IElasticToken.sol";

import "./KGRbToken.sol";

contract RebaseSalePool is OwnableUpgradeSafe {
    using SafeMath for uint256;

    IElasticToken public KGR;

    // Exchangerate ETHKGR with fixed point 18 decimal
    uint256 private constant DECIMALS = 18;
    // Keep this variable for save upgrade contract
    uint256 public rateETHKGR;

    uint256 public rateBuy;

    uint256 public saleCommissionPercent;

    // Upgrade contract v3
    uint256 public rateSell;

    uint256 public kgrbGenerationPercent;

    uint256 private constant FEE_DECIMALS = 4;
    uint256 public exchangeFeePerTenThousand;

    KGRbToken public KGRb;

    event LogBuy(address buyer, uint256 amountKGR, uint256 amountETH);
    event LogSell(address seller, uint256 amountKGR, uint256 amountETH);

    function initialize() external initializer {
        __Ownable_init();
    }

    function setToken(address kgr_) external onlyOwner {
        KGR = IElasticToken(kgr_);
    }

    function setBondToken(address kgrb_) external onlyOwner {
        KGRb = KGRbToken(kgrb_);
    }

    function setRateBuy(uint256 rate_) external onlyOwner {
        require(rate_ > 0);
        rateBuy = rate_;
    }

    function getRateBuy() external view returns (uint256) {
        return rateBuy;
    }

    function setRateSell(uint256 rate_) external onlyOwner {
        require(rate_ > 0);
        rateSell = rate_;
    }

    function getRateSell() external view returns (uint256) {
        return rateSell;
    }

    function setSaleCommissionPercent(uint256 percent_) external onlyOwner {
        require(percent_ < 100);
        saleCommissionPercent = percent_;
    }

    function setKGRbGenerationPercent(uint256 percent_) external onlyOwner {
        require(percent_ < 100);
        kgrbGenerationPercent = percent_;
    }

    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setExchangeFeePerTenThousand(uint256 fee_) external onlyOwner {
        require(fee_ > 0 && fee_ < 10000);
        exchangeFeePerTenThousand = fee_;
    }

    function getExchangeFeePerTenThousand() external view returns (uint256) {
        return exchangeFeePerTenThousand;
    }

    function buyKGR() external payable {
        require(rateBuy > 0 && msg.value > 0);

        uint256 fee =
            msg.value.mul(exchangeFeePerTenThousand).div(10**FEE_DECIMALS);
        uint256 amountKGR = msg.value.sub(fee).mul(rateBuy).div(10**DECIMALS);
        if (saleCommissionPercent > 0) {
            uint256 commission =
                msg.value.sub(fee).mul(saleCommissionPercent).div(100);
            payable(owner()).transfer(commission.add(fee));
        }
        KGR.transfer(msg.sender, amountKGR);
        emit LogBuy(msg.sender, amountKGR, msg.value);
    }

    function sellKGR(uint256 amountKGR) external {
        require(amountKGR > 0);
        require(rateSell > 0);

        uint256 fee =
            amountKGR.mul(exchangeFeePerTenThousand).div(10**FEE_DECIMALS);
        KGR.transferFrom(msg.sender, owner(), fee);

        uint256 convertAmount = amountKGR.sub(fee);
        KGR.transferFrom(msg.sender, address(this), convertAmount);

        uint256 kgrbAmount = convertAmount.mul(kgrbGenerationPercent).div(100);
        KGRb.mint(msg.sender, kgrbAmount);

        uint256 amountETH =
            convertAmount.sub(kgrbAmount).mul(10**DECIMALS).div(rateSell);
        msg.sender.transfer(amountETH);

        emit LogSell(msg.sender, amountKGR, amountETH);
    }
}
