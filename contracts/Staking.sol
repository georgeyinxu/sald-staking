// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Staking is Ownable {
    using SafeMath for uint256;

    IERC20 private _saldToken;
    uint256 private _totalStaked;
    mapping(address => uint256) private _stakedBalances;
    mapping(address => uint256) private _lastClaimedTime;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(address saldTokenAddress) {
        _saldToken = IERC20(saldTokenAddress);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake zero tokens");
        _saldToken.transferFrom(msg.sender, address(this), amount);

        _stakedBalances[msg.sender] = _stakedBalances[msg.sender].add(amount);
        _totalStaked = _totalStaked.add(amount);

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Cannot withdraw zero tokens");
        require(amount <= _stakedBalances[msg.sender], "Not enough staked tokens");

        _stakedBalances[msg.sender] = _stakedBalances[msg.sender].sub(amount);
        _totalStaked = _totalStaked.sub(amount);

        _saldToken.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() external {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No rewards to claim");

        _lastClaimedTime[msg.sender] = block.timestamp;
        _saldToken.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function calculateReward(address user) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp.sub(_lastClaimedTime[user]);
        uint256 stakedAmount = _stakedBalances[user];

        // Assuming a simple linear reward distribution over time.
        // You may want to implement a more sophisticated reward algorithm.
        uint256 rewardPerSecond = 1; // Adjust this value based on your requirements
        uint256 reward = rewardPerSecond.mul(timeElapsed).mul(stakedAmount).div(1e18);

        return reward;
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function stakedBalanceOf(address account) external view returns (uint256) {
        return _stakedBalances[account];
    }

    function lastClaimedTime(address account) external view returns (uint256) {
        return _lastClaimedTime[account];
    }
}
