// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

import "./ERC20UpgradeSafe.sol";

contract KGRbToken is ERC20UpgradeSafe, OwnableUpgradeSafe {
    address private _minter;

    modifier onlyMinter() {
        require(msg.sender == _minter);
        _;
    }

    function initialize() external initializer {
        __ERC20_init("Kagra Bond", "KGRb");
        __Ownable_init();
    }

    function setMinter(address minter_) external onlyOwner {
        require(minter_ != address(0x0));
        _minter = minter_;
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }
}
