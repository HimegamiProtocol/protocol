// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import "./interfaces/IElasticToken.sol";

//Stake pool
// Level 1: 5% ~ 30 days
// Level 2: 6% ~ 90 days
// Level 3: 7.5% ~ 180 days
// Level 4: 9.9% ~ 360 days
contract StakePool is OwnableUpgradeSafe {
    using SafeMath for uint256;

    struct Deal {
        uint256 level;
        uint256 amountTokens;
        uint256 amountShares;
        uint256 startTime;
        bool isActive;
    }

    mapping(address => Deal) activeDeals;

    IElasticToken KGR;

    uint256 private constant YEAR = 365 days;

    event LogAdminWithdraw(uint256 amount);
    event LogDealCreated(address trader, uint256 level, uint256 amount);
    event LogDealTraderTakeProfit(
        address trader,
        uint256 level,
        uint256 preAmount,
        uint256 afterAmount
    );

    function initialize() external initializer {
        __Ownable_init();
    }

    function setToken(address kgr_) external onlyOwner {
        KGR = IElasticToken(kgr_);
    }

    function withdraw(uint256 amount) external onlyOwner {
        KGR.transfer(owner(), amount);
        emit LogAdminWithdraw(amount);
    }

    function createDeal(uint256 level_, uint256 amount_) external {
        require(level_ >= 0 && level_ <= 4);
        require(amount_ > 10000);

        Deal storage deal = activeDeals[msg.sender];
        require(
            deal.isActive == false,
            "Each user need to wait until current stake was ended"
        );

        uint256 sharePerKGR = KGR.getSharePerToken();

        Deal storage newDeal;
        newDeal.level = level_;
        newDeal.amountTokens = amount_;
        newDeal.amountShares = amount_.mul(sharePerKGR);
        newDeal.startTime = now;
        newDeal.isActive = true;
        activeDeals[msg.sender] = newDeal;

        KGR.transferFrom(msg.sender, address(this), amount_);
        emit LogDealCreated(msg.sender, newDeal.level, newDeal.amountTokens);
    }

    function takeProfit() external returns (bool) {
        Deal storage deal = activeDeals[msg.sender];
        require(deal.isActive == true);

        uint256 time = now - deal.startTime;
        uint256 sharePerKGR = KGR.getSharePerToken();

        uint256 period = 0;
        uint256 incentivePct = 0;
        if (deal.level == 1) {
            period = 30 days;
            incentivePct = 50;
        } else if (deal.level == 2) {
            period = 90 days;
            incentivePct = 60;
        } else if (deal.level == 2) {
            period = 180 days;
            incentivePct = 75;
        } else if (deal.level == 4) {
            period = 360 days;
            incentivePct = 99;
        } else {
            return false;
        }

        if (time < period) {
            //penalties. Trader will get back only 90%
            uint256 returnShares = deal.amountShares.mul(90).div(100);
            uint256 returnKGRs = returnShares.div(sharePerKGR);
            KGR.transfer(msg.sender, returnKGRs);
            emit LogDealTraderTakeProfit(
                msg.sender,
                deal.level,
                deal.amountTokens,
                returnKGRs
            );
        } else {
            uint256 incentiveShares =
                deal.amountShares.mul(incentivePct).mul(time).div(1000).div(
                    YEAR
                );
            uint256 returnShares = deal.amountShares.add(incentiveShares);
            uint256 returnKGRs = returnShares.div(sharePerKGR);
            KGR.transfer(msg.sender, returnKGRs);
            emit LogDealTraderTakeProfit(
                msg.sender,
                deal.level,
                deal.amountTokens,
                returnKGRs
            );
        }

        activeDeals[msg.sender].isActive = false;
        return true;
    }
}
