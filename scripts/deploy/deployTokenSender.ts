import hre, { ethers } from "hardhat";

import { getAddressList, setAddress } from "../../utils/address.util";

export async function deployTokenSender() {
  const [owner] = await ethers.getSigners();

  const addressList = getAddressList(hre.network.name);
  console.log(addressList.Link);

  const TokenSender = await ethers.getContractFactory("TokenSender", owner);
  const tokenSender = await TokenSender.deploy(
    addressList.Router,
    addressList.Link
  );

  await tokenSender.waitForDeployment();

  const tokenSenderAddress = await tokenSender.getAddress();

  setAddress("tokenSender", tokenSenderAddress);

  console.log(`Deployed to ${tokenSenderAddress}`);

  return tokenSender;
}

deployTokenSender().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
