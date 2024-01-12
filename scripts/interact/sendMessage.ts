import hre, { ethers } from "hardhat";

import { getAddressList } from "../../utils/address.util";
import { CHAIN_SELECTOR } from "../../constants/chain-selector";

export async function sendMessage() {
  const [owner] = await ethers.getSigners();

  const sourceChain = "mumbai";
  const destChain = "mumbai";

  const addressList = getAddressList(hre.network.name);
  const addressListSepolia = getAddressList(destChain);

  const MessagePassing = await ethers.getContractAt(
    "MessagePassing",
    addressList.messagePassing,
    owner
  );

  const messagePassingAddress = await MessagePassing.getAddress();

  console.log(`Message Passing Address: ${messagePassingAddress}`);

  const res = await MessagePassing.sendMessage(
    CHAIN_SELECTOR[destChain],
    addressListSepolia.messagePassing,
    "Hello Bro!!",
    1
  );

  // console.log(`Fee: ${ethers.formatEther(res[0])}, messageId: ${res[1]}`);

  console.log(res.hash);

  return MessagePassing;
}

sendMessage().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
