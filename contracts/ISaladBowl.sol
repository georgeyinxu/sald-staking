// ISaladBowl.sol
pragma solidity 0.8.19;

interface ISaladBowl {
  event Deposit(address indexed owner, uint256 amount, uint256 balance);
  event Withdraw(address indexed owner, uint256 amount, uint256 balance);
  event Harvest(address indexed owner, uint256 amount);
}