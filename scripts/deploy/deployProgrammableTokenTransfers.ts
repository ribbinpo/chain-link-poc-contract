import hre, { ethers } from "hardhat";

import { getAddressList, setAddress } from "../../utils/address.util";

export async function deployProgrammableTokenTransfers() {
  const [owner] = await ethers.getSigners();

  const addressList = getAddressList();

  const ProgrammableTokenTransfers = await ethers.getContractFactory(
    "ProgrammableTokenTransfers",
    owner
  );
  const programmableTokenTransfers = await ProgrammableTokenTransfers.deploy(
    addressList.Router
  );

  await programmableTokenTransfers.waitForDeployment();

  const programmableTokenTransfersAddress =
    await programmableTokenTransfers.getAddress();

  setAddress("programmableTokenTransfers", programmableTokenTransfersAddress);

  console.log(`Deployed to ${programmableTokenTransfersAddress}`);

  return programmableTokenTransfers;
}

deployProgrammableTokenTransfers().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
