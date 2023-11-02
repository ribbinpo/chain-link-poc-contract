import hre, { ethers } from "hardhat";

import { getAddressList, setAddress } from "../../utils/address.util";

export async function deployMessagePassing() {
  const [owner] = await ethers.getSigners();

  const addressList = getAddressList(hre.network.name);
  console.log(addressList.Link);

  const MessagePassing = await ethers.getContractFactory(
    "MessagePassing",
    owner
  );
  const messagePassing = await MessagePassing.deploy(
    addressList.Router,
    addressList.Link
  );

  await messagePassing.waitForDeployment();

  const messagePassingAddress = await messagePassing.getAddress();

  setAddress("messagePassing", messagePassingAddress);

  console.log(`Deployed to ${messagePassingAddress}`);

  return messagePassing;
}

deployMessagePassing().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
