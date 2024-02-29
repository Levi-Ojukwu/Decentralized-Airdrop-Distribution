import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  const keyHash = "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c"; 
  const fee = 5; 
  const tokenAddress = "0x779877a7b0d9e8603169ddbd7836e478b4624789"; 
  const vrfCoordinator="0x8103b0a8a00be2ddc778e6e7eaa21791cd364625"; 
  const linkToken="0x779877a7b0d9e8603169ddbd7836e478b4624789";
  
  const PriceDistribution = await ethers.deployContract("PriceDistribution",[vrfCoordinator,
    linkToken,
    keyHash,
    fee,
    tokenAddress]); 
  await PriceDistribution.waitForDeployment();
  
    console.log(
    `PriceDistribution contract deployed to ${PriceDistribution.target}`
  );
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
