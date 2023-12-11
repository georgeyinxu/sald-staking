import { ethers } from "hardhat";
import { deployContract, run } from "../utils/helper";

run(async () => {
  const tokenContract = await deployContract("SaladToken");
  const height = await ethers.provider.getBlockNumber();
  const bowlContract = await deployContract("SaladBowl", tokenContract.address, 1e9, height + 10, height + 10 + 5000);
});