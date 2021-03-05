// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import "./interfaces/IElasticToken.sol";
import "./interfaces/IMonetaryPolicy.sol";

import "./Utils.sol";

contract Orchestrator is OwnableUpgradeSafe, Utils {
    using SafeMath for uint256;

    IMonetaryPolicy public monetaryPolicy;

    address public rebaseSalePool;
    uint256 public salePerRebase;
    bool public rebaseSalePaused;

    uint256 private _syncGas;

    event LogAddNewUniPair(address token1, address token2);
    event LogDeleteUniPair(bool enabled, address uniPair);
    event LogSetUniPairEnabled(uint256 index, bool enabled);
    event LogRebaseSalePausedUpdate(bool paused);
    event LogRebaseSalePoolUpdate(address pool, uint256 amount);
    event LogUseStaticSalePerRebaseUpdate(bool used);
    event LogSalePerRebaseBaseSupplyPerThousandUpdate(uint256 perThousand);

    struct UniPair {
        bool enabled;
        IUniswapV2Pair pair;
    }

    UniPair[] public uniSyncs;

    //Orchestrator V2
    IElasticToken public KGR;
    bool public useStaticSalePerRebase;
    uint256 public salePerRebaseBaseSupplyPerThousand;

    modifier indexInBounds(uint256 index) {
        require(
            index < uniSyncs.length,
            "Index must be less than array length"
        );
        _;
    }

    function initialize(address monetaryPolicy_) external initializer {
        __Ownable_init();
        monetaryPolicy = IMonetaryPolicy(monetaryPolicy_);

        rebaseSalePaused = true;
        _syncGas = 0;
    }

    function setElasticToken(address addr) external onlyOwner {
        KGR = IElasticToken(addr);
    }

    function setSyncGas(uint256 syncGas) external onlyOwner {
        _syncGas = syncGas;
    }

    function setRebaseSalePool(address pool_, uint256 amount_)
        external
        onlyOwner
    {
        rebaseSalePool = pool_;
        salePerRebase = amount_;
        rebaseSalePaused = false;
        emit LogRebaseSalePoolUpdate(rebaseSalePool, salePerRebase);
    }

    function setRebaseSalePaused(bool paused) external onlyOwner {
        rebaseSalePaused = paused;
        if (
            rebaseSalePaused == true &&
            address(rebaseSalePool) != address(0x0) &&
            address(KGR) != address(0x0) &&
            KGR.balanceOf(rebaseSalePool) > 0
        ) {
            monetaryPolicy.stablize(rebaseSalePool, 0);
        }
        emit LogRebaseSalePausedUpdate(paused);
    }

    function setUseStaticSalePerRebase(bool used) external onlyOwner {
        useStaticSalePerRebase = used;
        emit LogUseStaticSalePerRebaseUpdate(used);
    }

    function setSalePerRebaseBaseSupplyPerThousand(uint256 perThousand)
        external
        onlyOwner
    {
        require(salePerRebaseBaseSupplyPerThousand < 1000);
        salePerRebaseBaseSupplyPerThousand = perThousand;
        emit LogSalePerRebaseBaseSupplyPerThousandUpdate(perThousand);
    }

    function addUniPair(address token1, address token2) external onlyOwner {
        uniSyncs.push(UniPair(true, genUniAddr(token1, token2)));

        emit LogAddNewUniPair(token1, token2);
    }

    function deleteUniPair(uint256 index)
        external
        onlyOwner
        indexInBounds(index)
    {
        UniPair memory instanceToDelete = uniSyncs[index];

        if (index < uniSyncs.length.sub(1)) {
            uniSyncs[index] = uniSyncs[uniSyncs.length.sub(1)];
        }
        emit LogDeleteUniPair(
            instanceToDelete.enabled,
            address(instanceToDelete.pair)
        );

        uniSyncs.pop();
        delete instanceToDelete;
    }

    function setUniPairEnabled(uint256 index, bool enabled)
        external
        onlyOwner
        indexInBounds(index)
    {
        UniPair storage instance = uniSyncs[index];
        instance.enabled = enabled;

        emit LogSetUniPairEnabled(index, enabled);
    }

    function rebase() external {
        require(msg.sender == tx.origin, "msg.sender != tx.origin");

        monetaryPolicy.rebase();

        if (rebaseSalePaused == false) {
            if (useStaticSalePerRebase) {
                monetaryPolicy.stablize(rebaseSalePool, salePerRebase);
            } else {
                require(address(KGR) != address(0x0));
                require(salePerRebaseBaseSupplyPerThousand > 0);
                uint256 amount =
                    KGR
                        .totalSupply()
                        .mul(salePerRebaseBaseSupplyPerThousand)
                        .div(1000);
                monetaryPolicy.stablize(rebaseSalePool, amount);
            }
        }

        for (uint256 i = 0; i < uniSyncs.length; i++) {
            if (uniSyncs[i].enabled) {
                if (_syncGas > 0) {
                    address(uniSyncs[i].pair).call{gas: _syncGas}(
                        abi.encode(uniSyncs[i].pair.sync.selector)
                    );
                } else {
                    address(uniSyncs[i].pair).call(
                        abi.encode(uniSyncs[i].pair.sync.selector)
                    );
                }
            }
        }
    }
}
