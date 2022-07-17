const hre = require('hardhat');

async function main() {
  // const Contract = await hre.ethers.getContractFactory('Saibapanku');
  // const contractd = await Contract.deploy();
  // console.log('Contract deployed to:', contractd.address);
  const contract = '0x0E76CbDbc42384770ceEc738B910b9c7c08557DE';
  await hre.run('verify:verify', {
    address: contract,
    constructorArguments: [],
  });
  console.log('verified');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
