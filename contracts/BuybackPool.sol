// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./interfaces/IElasticToken.sol";

contract BuybackPool is OwnableUpgradeSafe {
    using SafeMath for uint256;

    IElasticToken public KGR;

    // Exchangerate ETHKGR with fixed point 18 decimal
    uint256 public rateETHKGR;

    uint256 private constant DECIMALS = 18;

    event LogBuybackPoolRateUpdated(uint256 newRate_);
    event LogBuybackPoolPoolBuy(
        address seller,
        uint256 amountKGR,
        uint256 amountETH
    );

    function initialize() external initializer {
        __Ownable_init();
    }

    function setToken(address kgr_) external onlyOwner {
        KGR = IElasticToken(kgr_);
    }

    function setExchangeRate(uint256 rate_) external onlyOwner {
        rateETHKGR = rate_;
        emit LogBuybackPoolRateUpdated(rate_);
    }

    /*
     * @dev Customer sell KGR with fixed price use ETH
     * KGR Will be transfered to owner address
     * approve() function need to be called before hand
     */
    function sellKGR(uint256 amountKGR) external {
        require(amountKGR > 0);
        require(rateETHKGR > 0);
        uint256 amountETH = amountKGR.div(rateETHKGR).mul(DECIMALS);
        KGR.transferFrom(msg.sender, owner(), amountKGR);
        msg.sender.transfer(amountETH);
        emit LogBuybackPoolPoolBuy(msg.sender, amountKGR, amountETH);
    }
}
