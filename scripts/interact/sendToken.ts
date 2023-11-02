import hre, { ethers } from "hardhat";

import { getAddressList } from "../../utils/address.util";
import { CHAIN_SELECTOR } from "../../constants/chain-selector";

export async function sendMessage() {
  const [owner] = await ethers.getSigners();

  // const sourceChain = "mumbai";
  const destChain = "fuji";

  const addressList = getAddressList(hre.network.name);

  const MessagePassing = await ethers.getContractAt(
    "TokenSender",
    addressList.tokenSender,
    owner
  );

  const messagePassingAddress = await MessagePassing.getAddress();

  console.log(`TokenSender Address: ${messagePassingAddress}`);

  const tokenAmounts = [
    {
      token: "0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05",
      amount: ethers.parseEther("1"),
    },
  ];

  const res = await MessagePassing.sendToken(
    CHAIN_SELECTOR[destChain],
    "0xE3876f1D0D0DbC782d7844FdE8675c75628E36a2",
    tokenAmounts,
    1
  );

  console.log(res.hash);

  return MessagePassing;
}

sendMessage().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
