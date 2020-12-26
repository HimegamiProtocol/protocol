// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import "./interfaces/IElasticToken.sol";

// Founder pool that lock founder/advisor/tech balance. The period will be:
// 6 Months: max 15% share
// 9 months: max 25% share
// 12 months: max 75% share
// 18 months: max 85% share
// 24 months: max 15% share

contract FounderPool is OwnableUpgradeSafe {
    using SafeMath for uint256;

    modifier validAddress(address addr) {
        require(addr != address(0x0) && addr != address(this));
        _;
    }

    struct Founder {
        address addr;
        uint256 weight;
    }

    uint256 public withdrewPct;
    uint256 public totalWeight;
    uint256 public startTime;

    Founder[] public founders;

    IElasticToken public KGR;

    uint256 constant p1 = 180 days;
    uint256 constant p2 = 270 days;
    uint256 constant p3 = 360 days;
    uint256 constant p4 = 540 days;
    uint256 constant p5 = 720 days;

    event FounderAdded(address founder_, uint256 weight_);
    event FounderWithdraw(address founder_, uint256 amount_);

    function initialize() external initializer {
        __Ownable_init();
        startTime = now;
    }

    function setToken(address kgr_) external onlyOwner {
        KGR = IElasticToken(kgr_);
    }

    function addFounder(address addr_, uint256 weight_)
        external
        validAddress(addr_)
    {
        require(now < startTime + 7 days);
        founders.push(Founder(addr_, weight_));
        totalWeight += weight_;
        emit FounderAdded(addr_, weight_);
    }

    function withdraw() external onlyOwner {
        uint256 diff = now.sub(startTime);
        uint256 maxPct = 0;
        if (diff >= p5) {
            maxPct = 100;
        } else if (diff >= p4) {
            maxPct = 85;
        } else if (diff >= p3) {
            maxPct = 75;
        } else if (diff >= p2) {
            maxPct = 25;
        } else if (diff >= p1) {
            maxPct = 15;
        }
        require(maxPct > withdrewPct, "Need to wait more");
        uint256 balance = KGR.balanceOf(address(this));
        uint256 KGRPerPct = balance.div(100 - withdrewPct);
        for (uint256 i = 0; i < founders.length; i++) {
            uint256 amount =
                KGRPerPct.mul(maxPct - withdrewPct).mul(founders[i].weight).div(
                    totalWeight
                );
            KGR.transfer(founders[i].addr, amount);
            emit FounderWithdraw(founders[i].addr, amount);
        }
        withdrewPct = maxPct;
    }
}
