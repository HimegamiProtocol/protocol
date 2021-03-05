// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";

import "./Utils.sol";

contract AirdropLiquidityProviderPool is OwnableUpgradeSafe, Utils {
    using Address for address;
    using SafeMath for uint256;

    event LogElasticTokenUpdate(address token);
    event LogGovTokenUpdate(address token);
    event LogDistributionLagUpdate(uint256 lag);
    event LogTimingParameterUpdate(uint256 windowSec);
    event LogDistributeIncentive(address provider, uint256 amount);
    event LogAirdropPaused(bool paused);

    IERC20 public elasticToken;
    IERC20 public govToken;

    IUniswapV2Pair public pair;

    uint256 public minDistributionWindowSec;

    uint256 public distributionLag;

    bool public airdropPaused;

    struct LPRecord {
        uint256 tokenReserveBalance;
        uint256 tokenReserveSupply;
        uint256 tokenPairBalance;
        uint256 timeInterval;
    }
    mapping(address => LPRecord) public histories;

    modifier whenAirdropNotPaused() {
        require(!airdropPaused);
        _;
    }

    function initialize(address elasticTokenAddr_, address tokenBAddr_)
        external
        initializer
    {
        __Ownable_init();

        elasticToken = IERC20(elasticTokenAddr_);

        minDistributionWindowSec = 30 * 1385 minutes;

        distributionLag = 50;
        airdropPaused = true;

        pair = genUniAddr(elasticTokenAddr_, tokenBAddr_);
    }

    function setAirdropPaused(bool paused) external onlyOwner {
        airdropPaused = paused;

        emit LogAirdropPaused(paused);
    }

    function setElasticToken(address token_) external onlyOwner {
        elasticToken = IERC20(token_);

        emit LogElasticTokenUpdate(token_);
    }

    function setGovToken(address token_) external onlyOwner {
        govToken = IERC20(token_);

        emit LogGovTokenUpdate(token_);
    }

    function setDistributionLag(uint256 lag_) external onlyOwner {
        distributionLag = lag_;

        emit LogDistributionLagUpdate(lag_);
    }

    function setTimingParameter(uint256 windowSec_) external onlyOwner {
        minDistributionWindowSec = windowSec_;

        emit LogTimingParameterUpdate(minDistributionWindowSec);
    }

    function pairInfo()
        internal
        view
        returns (uint256 reserve, uint256 totalSupply)
    {
        totalSupply = pair.totalSupply();
        (uint256 reserves0, uint256 reserves1, ) = pair.getReserves();
        reserve = address(elasticToken) == pair.token0()
            ? reserves0
            : reserves1;
    }

    function recordLiquidityProvider(address provider)
        external
        onlyOwner
        whenAirdropNotPaused
    {
        require(provider.isContract() == false);

        LPRecord storage record = histories[provider];
        uint256 tokenPairBalance = pair.balanceOf(provider);
        bool distributeIncentive = false;
        if (record.timeInterval == 0) {
            require(tokenPairBalance > 0);
        } else {
            require(
                record.timeInterval.add(minDistributionWindowSec) < now,
                "It is not time to get incentive"
            );
            distributeIncentive = true;
        }

        uint256 tokenReserveSupply = elasticToken.totalSupply();
        uint256 totalTokenReserveBalance;
        uint256 tokenPairSupply;
        (totalTokenReserveBalance, tokenPairSupply) = pairInfo();
        uint256 tokenReserveBalance =
            totalTokenReserveBalance.mul(tokenPairBalance).div(tokenPairSupply);
        if (distributeIncentive) {
            uint256 incentive;
            if (tokenPairBalance >= record.tokenPairBalance) {
                incentive = record
                    .tokenReserveBalance
                    .mul(tokenReserveSupply)
                    .div(record.tokenReserveSupply)
                    .div(distributionLag);
            } else {
                incentive = tokenReserveBalance.div(distributionLag);
            }
            if (incentive <= govToken.balanceOf(address(this))) {
                govToken.transfer(provider, incentive);
                emit LogDistributeIncentive(provider, incentive);
            } else {
                airdropPaused = true;
                incentive = govToken.balanceOf(address(this));
                govToken.transfer(provider, incentive);
                emit LogDistributeIncentive(provider, incentive);
            }
        }
        histories[provider].tokenReserveBalance = tokenReserveBalance;
        histories[provider].tokenReserveSupply = tokenReserveSupply;
        histories[provider].tokenPairBalance = tokenPairBalance;
        histories[provider].timeInterval = now;
    }
}
