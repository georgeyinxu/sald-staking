import { ethers } from "hardhat";
import * as networkHelpers from "@nomicfoundation/hardhat-network-helpers";
import { deployContract, run } from "../utils/helper";
import { BigNumber } from "bignumber.js";

run(async () => {
  const tokenContract = await deployContract("SaladToken");
  const height = await ethers.provider.getBlockNumber();
  const bowlContract = await deployContract(
    "SaladBowl",
    tokenContract.address,
    1e9,
    height + 10,
    height + 10 + 5000
  );

  const [owner, wallet1, wallet2] = await ethers.getSigners();

  console.log("height", await ethers.provider.getBlockNumber());

  const decimals = await tokenContract.decimals();
  const amount1 = new BigNumber(100).shiftedBy(decimals);
  const amount2 = new BigNumber(200).shiftedBy(decimals);

  await tokenContract
    .connect(owner)
    .transfer(wallet1.address, amount1.toString(10));
  await tokenContract
    .connect(wallet1)
    .approve(bowlContract.address, amount1.toString(10));
  await bowlContract.connect(wallet1).deposit(amount1.toString(10));

  await tokenContract
    .connect(owner)
    .transfer(wallet2.address, amount2.toString(10));
  await tokenContract
    .connect(wallet2)
    .approve(bowlContract.address, amount2.toString(10));
  await bowlContract.connect(wallet2).deposit(amount2.toString(10));

  await networkHelpers.mine(1000);

  console.log(
    "1 token balance",
    await tokenContract.balanceOf(wallet1.address)
  );
  console.log("1 vault balance", await bowlContract.balanceOf(wallet1.address));

  console.log(
    "2 token balance",
    await tokenContract.balanceOf(wallet2.address)
  );
  console.log("2 vault balance", await bowlContract.balanceOf(wallet2.address));

  await bowlContract.connect(wallet1).withdraw(amount1.toString(10));
  await bowlContract.connect(wallet2).harvest();

  console.log("height", await ethers.provider.getBlockNumber());
  console.log(
    "1 token balance",
    await tokenContract.balanceOf(wallet1.address)
  );
  console.log("1 vault balance", await bowlContract.balanceOf(wallet1.address));

  console.log(
    "2 token balance",
    await tokenContract.balanceOf(wallet2.address)
  );
  console.log("2 vault balance", await bowlContract.balanceOf(wallet2.address));

  await networkHelpers.mine(5000);
  await bowlContract.connect(wallet2).harvest();

  console.log("height", await ethers.provider.getBlockNumber());
  console.log(
    "2 token balance",
    await tokenContract.balanceOf(wallet2.address)
  );
  console.log("2 vault balance", await bowlContract.balanceOf(wallet2.address));
});
