// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import "./ERC20UpgradeSafe.sol";

contract OMKToken is ERC20UpgradeSafe, OwnableUpgradeSafe {
    using SafeMath for uint256;

    uint256 private constant TOTAL_SUPPLY = 100_000_000 * 10**18;

    function initialize(
        uint256 totalWeight,
        address airdropHolderPool,
        uint256 airdropHolderPoolWeight,
        address airdropLiquidityProviderPool,
        uint256 airdropLiquidityProviderPoolWeight,
        uint256 ownerWeight
    ) external initializer {
        require(
            airdropHolderPoolWeight.add(airdropLiquidityProviderPoolWeight).add(
                ownerWeight
            ) == totalWeight
        );
        __ERC20_init("Omoikane", "OMK");
        __Ownable_init();

        uint256 ownerBalance = TOTAL_SUPPLY.mul(ownerWeight).div(totalWeight);
        uint256 airdropHolderBalance =
            TOTAL_SUPPLY.mul(airdropHolderPoolWeight).div(totalWeight);
        uint256 airdropLiquidityProviderBalance =
            TOTAL_SUPPLY.mul(airdropLiquidityProviderPoolWeight).div(
                totalWeight
            );

        _mint(owner(), ownerBalance);
        _mint(airdropHolderPool, airdropHolderBalance);
        _mint(airdropLiquidityProviderPool, airdropLiquidityProviderBalance);
    }
}
