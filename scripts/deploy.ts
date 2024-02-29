import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  const keyHash = "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c"; 
  const fee = 5; 
  const tokenAddress = "0x5F9cf1Aecf388d23c0f710f4a64C8458545B4248"; 
  const vrfCoordinator="0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625"; 
  const linkToken="0x779877A7B0D9E8603169DdbD7836e478b4624789";
  
  const GamingAirdrop = await ethers.deployContract("GamingAirdrop",[vrfCoordinator,
    linkToken,
    keyHash,
    fee,
    tokenAddress]); 
  await GamingAirdrop.waitForDeployment();
  
    console.log(
    `GamingAirdrop contract deployed to ${GamingAirdrop.target}`
  );
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
