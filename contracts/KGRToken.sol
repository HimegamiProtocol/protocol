// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

import "./ERC20UpgradeSafe.sol";
import "./lib/SafeMathInt.sol";
import "./lib/UInt256Lib.sol";

/**
 * @title KGR ERC20 token
 * @dev KGR is a normal ERC20 token, but its supply can be adjusted by splitting and
 *      combining tokens proportionally across all wallets.
 *
 *      KGR balances are internally represented with a hidden denomination, 'shares'.
 *      We support splitting the currency in expansion and combining the currency on contraction by
 *      changing the exchange rate between the hidden 'shares' and the public 'KGR'.
 */
contract KGRToken is ERC20UpgradeSafe, OwnableUpgradeSafe {
    // PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
    // Anytime there is division, there is a risk of numerical instability from rounding errors. In
    // order to minimize this risk, we adhere to the following guidelines:
    // 1) The conversion rate adopted is the number of shares that equals 1 KGR.
    //    The inverse rate must not be used--totalShares is always the numerator and _totalSupply is
    //    always the denominator. (i.e. If you want to convert shares to KGR instead of
    //    multiplying by the inverse rate, you should divide by the normal rate)
    // 2) Share balances converted into KGR are always rounded down (truncated).
    //
    // We make the following guarantees:
    // - If address 'A' transfers x KGR to address 'B'. A's resulting external balance will
    //   be decreased by precisely x KGR, and B's external balance will be precisely
    //   increased by x KGR.
    //
    // We do not guarantee that the sum of all balances equals the result of calling totalSupply().
    // This is because, for any conversion function 'f()' that has non-zero rounding error,
    // f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... xn).
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event LogRebasePaused(bool paused);
    event LogTokenPaused(bool paused);
    event LogMonetaryPolicyUpdated(address monetaryPolicy);
    event LogRebaseSalePaused(bool paused);

    // Precautionary emergency controls.
    bool public rebasePaused;
    bool public tokenPaused;

    modifier whenRebaseNotPaused() {
        require(!rebasePaused);
        _;
    }

    modifier whenTokenNotPaused() {
        require(!tokenPaused);
        _;
    }

    address public monetaryPolicy;

    modifier onlyMonetaryPolicy() {
        require(msg.sender == monetaryPolicy);
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_INT256 = ~uint256(0);
    uint256 private constant INITIAL_SUPPLY = 70_000_000 * 10**DECIMALS;
    uint256 private constant INITIAL_SHARES =
        (MAX_INT256 / (10**18)) - ((MAX_INT256 / (10**18)) % INITIAL_SUPPLY);
    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 private constant MAX_SHARES = ~uint256(0);

    uint256 private _totalSupply;
    uint256 private _totalShares;
    uint256 private _sharePerKGR;

    mapping(address => uint256) private _shareBalances;
    mapping(address => mapping(address => uint256)) private _allowedKGR;

    function initialize(
        uint256 totalWeight_,
        address founderPool_,
        uint256 founderPoolWeight_,
        address stakePool_,
        uint256 stakePoolWeight_,
        uint256 presalePoolWeight_
    ) external initializer {
        require(
            founderPoolWeight_.add(presalePoolWeight_).add(stakePoolWeight_) ==
                totalWeight_
        );
        __ERC20_init("Kagra", "KGR");
        __Ownable_init();

        rebasePaused = false;
        tokenPaused = false;

        _totalSupply = INITIAL_SUPPLY;
        _totalShares = INITIAL_SHARES;
        _sharePerKGR = INITIAL_SHARES.div(_totalSupply);

        uint256 founderPoolVal =
            _totalSupply.mul(founderPoolWeight_).div(totalWeight_);
        uint256 founderPoolShares = founderPoolVal.mul(_sharePerKGR);
        uint256 presalePoolVal =
            _totalSupply.mul(presalePoolWeight_).div(totalWeight_);
        uint256 presalePoolShares = presalePoolVal.mul(_sharePerKGR);
        uint256 stakePoolVal =
            _totalSupply.mul(stakePoolWeight_).div(totalWeight_);
        uint256 stakePoolShares = stakePoolVal.mul(_sharePerKGR);

        _shareBalances[owner()] = presalePoolShares;
        _shareBalances[founderPool_] = founderPoolShares;
        _shareBalances[stakePool_] = stakePoolShares;

        emit Transfer(address(0x0), owner(), presalePoolVal);
        emit Transfer(address(0x0), founderPool_, founderPoolVal);
        emit Transfer(address(0x0), stakePool_, stakePoolVal);
    }

    function setMonetaryPolicy(address monetaryPolicy_) external onlyOwner {
        monetaryPolicy = monetaryPolicy_;
        emit LogMonetaryPolicyUpdated(monetaryPolicy);
    }

    function setRebasePaused(bool paused) external onlyOwner {
        rebasePaused = paused;
        emit LogRebasePaused(paused);
    }

    function setTokenPaused(bool paused) external onlyOwner {
        tokenPaused = paused;
        emit LogTokenPaused(paused);
    }

    function rebase(uint256 epoch, int256 supplyDelta)
        external
        whenRebaseNotPaused
        onlyMonetaryPolicy
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(supplyDelta.abs()));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }
        if (_totalShares > MAX_SHARES) {
            _totalShares = MAX_SHARES;
        }

        _sharePerKGR = _totalShares.div(_totalSupply);

        emit LogRebase(epoch, _totalSupply);

        return _totalSupply;
    }

    function stablize(address pool, uint256 amount)
        external
        whenRebaseNotPaused
        whenTokenNotPaused
        onlyMonetaryPolicy
    {
        uint256 currentShares = _shareBalances[pool];
        uint256 targetShares = amount.mul(_sharePerKGR);
        if (targetShares > currentShares) {
            uint256 shareDelta = targetShares - currentShares;
            _totalShares = _totalShares.add(shareDelta);
            _totalSupply = _totalSupply.add(shareDelta.div(_sharePerKGR));
        } else if (targetShares < currentShares) {
            uint256 shareDelta = currentShares - targetShares;
            _totalShares = _totalShares.sub(shareDelta);
            _totalSupply = _totalSupply.sub(shareDelta.div(_sharePerKGR));
        }
        _shareBalances[pool] = targetShares;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _shareBalances[who].div(_sharePerKGR);
    }

    function transfer(address to, uint256 value)
        public
        override
        whenTokenNotPaused
        validRecipient(to)
        returns (bool)
    {
        uint256 shareValue = value.mul(_sharePerKGR);
        _shareBalances[msg.sender] = _shareBalances[msg.sender].sub(shareValue);
        _shareBalances[to] = _shareBalances[to].add(shareValue);
        emit Transfer(msg.sender, to, value);

        return true;
    }

    function allowance(address owner_, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowedKGR[owner_][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenTokenNotPaused validRecipient(to) returns (bool) {
        _allowedKGR[from][msg.sender] = _allowedKGR[from][msg.sender].sub(
            amount
        );
        uint256 shareValue = amount.mul(_sharePerKGR);
        _shareBalances[from] = _shareBalances[from].sub(shareValue);
        _shareBalances[to] = _shareBalances[to].add(shareValue);
        emit Transfer(from, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        whenTokenNotPaused
        returns (bool)
    {
        _allowedKGR[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        whenTokenNotPaused
        returns (bool)
    {
        _allowedKGR[msg.sender][spender] = _allowedKGR[msg.sender][spender].add(
            addedValue
        );
        emit Approval(msg.sender, spender, _allowedKGR[msg.sender][spender]);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        whenTokenNotPaused
        returns (bool)
    {
        uint256 oldValue = _allowedKGR[msg.sender][spender];
        if (subtractedValue > oldValue) {
            _allowedKGR[msg.sender][spender] = 0;
        } else {
            _allowedKGR[msg.sender][spender] = _allowedKGR[msg.sender][spender]
                .sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedKGR[msg.sender][spender]);

        return true;
    }

    function getSharePerToken() external view returns (uint256) {
        return _sharePerKGR;
    }
}
