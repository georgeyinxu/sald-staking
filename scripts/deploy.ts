import { ethers } from "hardhat";
import { deployContract, run } from "../utils/helper";

run(async () => {
  const tokenContract = await deployContract("SaladToken");
  const stakingContract = await deployContract("Staking", tokenContract.address);
});