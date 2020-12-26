// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import "./interfaces/IMonetaryPolicy.sol";

interface IUniV2Pair {
    function sync() external;
}

contract Orchestrator is OwnableUpgradeSafe {
    using SafeMath for uint256;

    IMonetaryPolicy public monetaryPolicy;

    address public rebaseSalePool;
    uint256 public salePerRebase;
    bool public rebaseSalePaused;

    event LogAddNewUniPair(address token1, address token2);
    event LogDeleteUniPair(bool enabled, address uniPair);
    event LogSetUniPairEnabled(uint256 index, bool enabled);
    event LogRebaseSalePausedUpdate(bool paused);
    event LogRebaseSalePoolUpdate(address pool, uint256 amount);

    uint256 constant SYNC_GAS = 50000;
    address constant uniFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    struct UniPair {
        bool enabled;
        IUniV2Pair pair;
    }

    UniPair[] public uniSyncs;

    modifier indexInBounds(uint256 index) {
        require(
            index < uniSyncs.length,
            "Index must be less than array length"
        );
        _;
    }

    function genUniAddr(address left, address right)
        internal
        pure
        returns (IUniV2Pair)
    {
        address first = left < right ? left : right;
        address second = left < right ? right : left;
        address pair =
            address(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            uniFactory,
                            keccak256(abi.encodePacked(first, second)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                        )
                    )
                )
            );
        return IUniV2Pair(pair);
    }

    function initialize(address monetaryPolicy_) external initializer {
        __Ownable_init();
        monetaryPolicy = IMonetaryPolicy(monetaryPolicy_);

        rebaseSalePaused = true;
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
        emit LogRebaseSalePausedUpdate(paused);
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
            monetaryPolicy.stablize(rebaseSalePool, salePerRebase);
        }

        for (uint256 i = 0; i < uniSyncs.length; i++) {
            if (uniSyncs[i].enabled) {
                address(uniSyncs[i].pair).call{gas: SYNC_GAS}(
                    abi.encode(uniSyncs[i].pair.sync.selector)
                );
            }
        }
    }
}
