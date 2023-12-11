import { ethers } from "hardhat";
import { run } from "../utils/helper";

run(async () => {
  const [owner] = await ethers.getSigners();
  const bowlAddress = // replace this with the deployed SaladBowl contract address;

  const rewardCF = await ethers.getContractFactory("SaladToken");
  if (!process.env.ADDR_REWARD_TOKEN)
    throw new Error("ADDR_REWARD_TOKEN env variable not set");

  const rewardContract = rewardCF.attach(process.env.ADDR_REWARD_TOKEN);

  if (!bowlAddress)
    throw new Error("SaladBowl contract address not set");

  await rewardContract.connect(owner).updateSaladBowl(bowlAddress);
});