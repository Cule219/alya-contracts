const hre = require('hardhat');
const { ipfsURL, hashesWL } = require('./constants');

async function main() {
  const Contract = await hre.ethers.getContractFactory('AlphaGangGenerative');

  // bytes32 _wl
  const contractd = await Contract.deploy(ipfsURL, hashesWL);

  // address for live site:
  const contractAddress = contractd.address;

  console.log('Contract deployed to:', contractAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
