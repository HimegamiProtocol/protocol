// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";

contract AirdropTokenHolderPool is OwnableUpgradeSafe {
    using Address for address;
    using SafeMath for uint256;

    event LogTimingParameterUpdate(uint256 interval);
    event LogDistributionLagUpdate(uint256 lag);
    event LogElasticTokenUpdate(address elasticTokenAddr);
    event LogGovTokenUpdate(address govTokenAddr);
    event LogAddTokenHolder(address holderAddr);
    event LogDistribution(uint256 afterTotalSupply);
    event LogAirdropPaused(bool paused);
    event LogLatestSupplyUpdate(uint256 supply);

    IERC20 public elasticToken;
    IERC20 public govToken;

    uint256 public totalSupply;

    uint256 public distributionLag;

    uint256 public lastDistributionTimestampSec;

    uint256 public minDistributionTimeIntervalSec;

    bool public airdropPaused;

    address[] public holders;
    mapping(address => bool) activeHolders;

    modifier whenAirdropNotPaused() {
        require(!airdropPaused);
        _;
    }

    function initialize(address elasticTokenAddr_) external initializer {
        __Ownable_init();

        elasticToken = IERC20(elasticTokenAddr_);

        distributionLag = 20;
        airdropPaused = true;
        minDistributionTimeIntervalSec = 1385 minutes;

        lastDistributionTimestampSec = now.sub(
            now.mod(minDistributionTimeIntervalSec)
        );

        totalSupply = elasticToken.totalSupply();
    }

    function updateLatestSupply() external onlyOwner {
        lastDistributionTimestampSec = now.sub(
            now.mod(minDistributionTimeIntervalSec)
        );

        totalSupply = elasticToken.totalSupply();

        emit LogLatestSupplyUpdate(totalSupply);
    }

    function distribute() external onlyOwner whenAirdropNotPaused {
        require(
            lastDistributionTimestampSec.add(minDistributionTimeIntervalSec) <
                now
        );
        lastDistributionTimestampSec = now.sub(
            now.mod(minDistributionTimeIntervalSec)
        );
        if (
            lastDistributionTimestampSec
                .add(minDistributionTimeIntervalSec)
                .add(minDistributionTimeIntervalSec) < now
        ) {
            //skip airdrop when missing update totalsupply
            totalSupply = elasticToken.totalSupply();
            return;
        }

        uint256 beforeTotalSupply = totalSupply;
        totalSupply = elasticToken.totalSupply();

        emit LogDistribution(totalSupply);

        if (beforeTotalSupply >= totalSupply) {
            return;
        }

        uint256 supplyDelta = totalSupply.sub(beforeTotalSupply);
        uint256 distributeAmount = supplyDelta.div(distributionLag);
        if (distributeAmount > govToken.balanceOf(address(this))) {
            distributeAmount = govToken.balanceOf(address(this));
        }

        for (uint256 i = 0; i < holders.length; i++) {
            uint256 elasticTokenBalance = elasticToken.balanceOf(holders[i]);
            uint256 govTokenDelta =
                elasticTokenBalance.mul(distributeAmount).div(totalSupply);
            govToken.transfer(holders[i], govTokenDelta);
        }
    }

    function distributev2(address holderAddr, uint256 amount)
        external
        onlyOwner
        whenAirdropNotPaused
    {
        govToken.transfer(holderAddr, amount);
    }

    function isExist(address holderAddr) external view returns (bool) {
        return activeHolders[holderAddr];
    }

    function addTokenHolder(address holderAddr) external onlyOwner {
        require(holderAddr.isContract() == false);
        require(elasticToken.balanceOf(holderAddr) > 0);
        require(activeHolders[holderAddr] == false);
        holders.push(holderAddr);
        activeHolders[holderAddr] = true;

        emit LogAddTokenHolder(holderAddr);
    }

    function setAirdropPaused(bool paused) external onlyOwner {
        airdropPaused = paused;

        emit LogAirdropPaused(paused);
    }

    function setTimingParameter(uint256 minDistributionTimeIntervalSec_)
        external
        onlyOwner
    {
        minDistributionTimeIntervalSec = minDistributionTimeIntervalSec_;

        emit LogTimingParameterUpdate(minDistributionTimeIntervalSec);
    }

    function setDistributionLag(uint256 lag) external onlyOwner {
        distributionLag = lag;

        emit LogDistributionLagUpdate(distributionLag);
    }

    function setElasticToken(address elasticTokenAddr_) external onlyOwner {
        elasticToken = IERC20(elasticTokenAddr_);
        totalSupply = elasticToken.totalSupply();

        emit LogElasticTokenUpdate(elasticTokenAddr_);
    }

    function setGovToken(address govTokenAddr_) external onlyOwner {
        govToken = IERC20(govTokenAddr_);

        emit LogGovTokenUpdate(govTokenAddr_);
    }
}
