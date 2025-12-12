const hre = require('hardhat');

async function main() {
  const CitadelVault = await hre.ethers.deployContract('CitadelVault');
  await CitadelVault.waitForDeployment();
  const addr = await CitadelVault.getAddress();
  console.log('CitadelVault deployed:', addr);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
