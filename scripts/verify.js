const hre = require('hardhat');
const {
  ipfsURL,
  hashesWL1RootHash,
  hashesWL2RootHash,
  hashesWaitListRootHash,
} = require('./constants');

async function main() {
  const contract = '';

  await hre.run('verify:verify', {
    address: contract,
    constructorArguments: [ipfsURL],
  });
  console.log('verified');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
