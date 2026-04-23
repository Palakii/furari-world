const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  // ← ใส่ wallet address ที่จะรับเงิน USDC (treasury)
  const TREASURY = "0x7b7B4c14cb900587d85300E3bB1CF4943928DCb9";

  const PackOpener = await ethers.getContractFactory("PackOpener");
  const contract = await PackOpener.deploy(TREASURY);
  await contract.waitForDeployment();

  console.log("✅ PackOpener deployed to:", await contract.getAddress());
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
