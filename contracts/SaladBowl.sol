// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SaladBowl is ISaladBowl, Context, ReentrancyGuard {
  using Math for uint256;

  uint256 private constant REWARD_PRECISION = 1e12;

  IERC20 private immutable _sald;

  uint256 public immutable rewardPerBlock;
  uint256 public immutable rewardStartBlock;
  uint256 public immutable rewardEndBlock;

  uint public lastRewardBlock = 0;
  mapping(address => uint256) private _balances;
  uint256 private _totalSupply;
  uint256 private _rewardPerShare;
  mapping(address => uint256) private _rewardDebtPerShare;

  constructor(
    IERC20 sald_,
    uint256 rewardPerBlock_,
    uint256 rewardStartBlock_,
    uint256 rewardEndBlock_
  ) {
    _sald = sald_;

    lastRewardBlock = block.number;

    require(rewardStartBlock_ > block.number, "SaladBowl: rewardStartBlock must be greater than current block");
    require(rewardEndBlock_ > rewardStartBlock_, "SaladBowl: rewardEndBlock must be greater than rewardStartBlock");
    require(rewardPerBlock_ > 0, "SaladBowl: rewardPerBlock must be greater than zero");

    rewardPerBlock = rewardPerBlock_;
    rewardStartBlock = rewardStartBlock_;
    rewardEndBlock = rewardEndBlock_;
  }

  function deposit(uint256 amount) nonReentrant public virtual {
    require(amount > 0, "SaladBowl: deposit amount must be greater than zero");
    address account = _msgSender();

    _withdrawRewards(account);
    uint256 balance = _mintBalance(account, amount);
    SafeERC20.safeTransferFrom(_sald, account, address(this), amount);

    emit Deposit(account, amount, balance);
  }

  function withdraw(uint256 amount) nonReentrant public virtual {
    address account = _msgSender();

    _withdrawRewards(account);
    uint256 balance = _burnBalance(account, amount);
    SafeERC20.safeTransfer(_sald, account, amount);

    emit Withdraw(account, amount, balance);
  }

  function harvest() nonReentrant public virtual {
    _withdrawRewards(_msgSender());
  }

  function emergencyWithdraw() nonReentrant public virtual {
    address account = _msgSender();

    uint256 amount = _balances[account];
    uint256 balance = _burnBalance(account, amount);
    SafeERC20.safeTransfer(_sald, account, amount);

    emit Withdraw(account, amount, balance);
  }

  function asset() external view returns (address) {
    return address(_sald);
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual returns (uint256) {
    return _balances[account];
  }

  function pendingRewards(address account) public view virtual returns (uint256) {
    uint256 shares = _balances[account];
    uint256 pendingRewardPerShare = _rewardPerShare - _rewardDebtPerShare[account];
    return shares * pendingRewardPerShare / REWARD_PRECISION;
  }

  function _updateRewards() internal {
    uint currentBlock = block.number;

    if (
      lastRewardBlock == currentBlock ||
      lastRewardBlock >= rewardEndBlock ||
      currentBlock < rewardStartBlock
    ) return;

    uint rewardUntilBlock = Math.min(currentBlock, rewardEndBlock);

    if (_totalSupply > 0) {
      uint blocks = rewardUntilBlock - Math.max(lastRewardBlock, rewardStartBlock);
      uint256 newReward = blocks * rewardPerBlock;
      _rewardPerShare = _rewardPerShare + (newReward * REWARD_PRECISION / _totalSupply);
    }

    lastRewardBlock = rewardUntilBlock;
  }

  function _withdrawRewards(address account) internal {
    _updateRewards();

    uint256 rewardOwed = pendingRewards(account);

    _rewardDebtPerShare[account] = _rewardPerShare;

    if (rewardOwed > 0) {
      _sald.transfer(account, rewardOwed);
      emit Harvest(account, rewardOwed);
    }
  }

  function _mintBalance(address account, uint256 amount) internal returns (uint256) {
    unchecked {
      _balances[account] += amount;
      _totalSupply += amount;
    }

    return _balances[account];
  }

  function _burnBalance(address account, uint256 amount) internal returns (uint256) {
    uint256 fromBalance = _balances[account];
    require(fromBalance >= amount, "SaladBowl: withdraw amount exceeds balance");

    unchecked {
      _balances[account] -= amount;
      _totalSupply -= amount;
    }

    if (_balances[account] == 0) {
      delete _balances[account];
    }

    return _balances[account];
  }
}
