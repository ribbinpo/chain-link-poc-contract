import { getAddressList } from "../../utils/address.util";
import hre, { ethers } from "hardhat";

async function balance() {
  const [owner] = await ethers.getSigners();

  console.log(await owner.getAddress());

  const addressList = getAddressList(hre.network.name);

  const LinkToken = await ethers.getContractAt(
    "IERC20",
    addressList.Link,
    owner
  );

  const BnMToken = await ethers.getContractAt(
    "IERC20",
    "0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05",
    owner
  );

  // console.log(ethers.formatEther(await BnMToken.balanceOf(owner.getAddress())));

  // const res = await LinkToken.transfer(addressList.tokenSender, ethers.parseEther("1"));
  // console.log(res.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
balance().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
