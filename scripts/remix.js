(async function () {
  const options = { gasPrice: 1000000000, gasLimit: 8500000, value: 0 };
  // {value: ethers.utils.parseEther("0.07")}
  try {
    // load data
    const fileAlphaGangOG = await remix.call(
      'fileManager',
      'getFile',
      'browser/contracts/artifacts/AlphaGang.json'
    );
    const metadataAlphaGangOG = JSON.parse(fileAlphaGangOG);
    const metadataGangToken = JSON.parse(
      await remix.call(
        'fileManager',
        'getFile',
        'browser/contracts/artifacts/GangToken.json'
      )
    );
    const fileAlphaGangG2 = await remix.call(
      'fileManager',
      'getFile',
      'browser/contracts/artifacts/AlphaGangGenerative.json'
    );
    const metadataAlphaGangG2 = JSON.parse(fileAlphaGangG2);

    const metdataAGStake = JSON.parse(
      await remix.call(
        'fileManager',
        'getFile',
        'browser/contracts/artifacts/AGStakeX.json'
      )
    );

    // the variable web3Provider is a remix global variable object
    const signer = new ethers.providers.Web3Provider(web3Provider).getSigner();
    console.log('signers address', signer);

    // Create an instance of a Contract Factory
    const factoryAlphaGang = new ethers.ContractFactory(
      metadataAlphaGangOG.abi,
      metadataAlphaGangOG.data.bytecode.object,
      signer
    );
    const factoryGangToken = new ethers.ContractFactory(
      metadataGangToken.abi,
      metadataGangToken.data.bytecode.object,
      signer
    );
    const factoryAlphaGangG2 = new ethers.ContractFactory(
      metadataAlphaGangG2.abi,
      metadataAlphaGangG2.data.bytecode.object,
      signer
    );

    const factoryAGStake = new ethers.ContractFactory(
      metdataAGStake.abi,
      metdataAGStake.data.bytecode.object,
      signer
    );

    const ipfsURL = 'ipfs://QmXtSDsWm2nQC497UeVsgPH2hT21WoZe8pi831iQugQ1Q3/';
    const merkleRoot =
      '0x5a1e2b6ddaf93ecb4ac9bfb937f36b6a406b245ed78c6ecdedecc14996c0f436';

    // // Notice we pass the constructor's parameters here
    const AlphaGangOGContract = await factoryAlphaGang.deploy(ipfsURL, options);
    const GangTokenContract = await factoryGangToken.deploy(options);

    // string memory _initBaseURI,
    // bytes32 _wlMRI,
    // bytes32 _wlMRII,
    // bytes32 _w8lMR
    const AlphaGangG2Contract = await factoryAlphaGangG2.deploy(
      ipfsURL,
      merkleRoot,
      merkleRoot,
      merkleRoot,
      options
    );

    const alphaGangOGAddress = AlphaGangOGContract.address;
    const alphaGangG2Address = AlphaGangG2Contract.address;
    const gangTokenAddress = GangTokenContract.address;

    // IAlphaGangOG _og,
    // IAlphaGangGenerative _G2,
    // IGangToken _token
    const AGStakeContract = await factoryAGStake.deploy(
      alphaGangOGAddress,
      alphaGangG2Address,
      gangTokenAddress
    );

    const agStakeAddress = AGStakeContract.address;

    // Addresses Contracts WILL have once mined
    console.log(
      'gangTokenAddress',
      gangTokenAddress,
      'alphaGangG2Address',
      alphaGangG2Address,
      'agStakeAddress',
      agStakeAddress
    );

    await AlphaGangOGContract.deployed();
    await GangTokenContract.deployed();
    await AlphaGangG2Contract.deployed();
    await AGStakeContract.deployed();
    console.log('contracts deployed');

    // allow minting contract to mint $GANG
    await GangTokenContract.addController(agStakeAddress);
    console.log('added controllers');

    await AlphaGangOGContract.setApprovalForAll(agStakeAddress, true);
    console.log('setApprovalForAll');

    // Set the staking address in Generative Contract to allow mint and stake fn
    AlphaGangG2Contract.setAGStake(agStakeAddress);

    const ammountNFTOne = 1;
    const ammountNFTTwo = 4;

    await AlphaGangOGContract.mintForAddress(
      signer.getAddress(),
      1,
      ammountNFTOne
    );
    await AlphaGangOGContract.mintForAddress(
      signer.getAddress(),
      2,
      ammountNFTTwo
    );
    console.log('minted nfts');

    // enable og minting
    await AlphaGangG2Contract.setSale(1);
    console.log('Og minting enabled');

    // stake all available tokens and mint G2: 5 in total + 2 as a base
    const value = (ammountNFTOne + ammountNFTTwo + 2) * 0.049;
    await AGStakeContract.stakeOGForMint({
      gasPrice: 1000000000,
      gasLimit: 8500000,
    });
    console.log('Staked and Minted, passing in value: ', value);

    await AlphaGangG2Contract.ogMint(7, 0, {
      gasPrice: 1000000000,
      gasLimit: 8500000,
      value: ethers.utils.parseEther(value.toString())
    })

    await AlphaGangG2Contract.ogMint(7, 0, {
      gasPrice: 1000000000,
      gasLimit: 8500000,
      value: ethers.utils.parseEther(value.toString())
    })

    const ammountNFTTree = 4;
    await AlphaGangOGContract.mintForAddress(
      signer.getAddress(),
      3,
      ammountNFTTree
    );

    const tokenG2CountOwner = await AlphaGangG2Contract.balanceOf(
      signer.getAddress(),
      options
    );

    const tokenG2CountContract = await AlphaGangG2Contract.balanceOf(
      alphaGangG2Address,
      options
    );
    console.log('Generative token count: ', 'owner:', tokenG2CountOwner, 'contract', tokenG2CountContract);

    // enable White List minting
    await AlphaGangG2Contract.setSale(2);
    console.log('White List minting enabled');

    const proof = [
      '0x26c3e24e0eb263c3163ceaafd4fe0b466b79a2be988fafbeb20f9f06b56275ed',
      '0x6584c64e1b10cf0deaada66ce4f48ef7a4d1c0928aba88023e8b17a2fde81dde',
      '0xbac7953455ec632d2b497c435cef7b8020d468a750ff596190ffa4edf3ea9c55',
      '0x818bfbd3fa2a470f1a1b86b0483061f2ad602d2589b722df0fb30bb0f49bd2f6',
      '0x7e1f2b3591b4db6b06e4a71cbe664d03a63614bb8bbfe648f09b7c512cec22ca',
    ];

    // buy 2 on whitelist, stake
    await AlphaGangG2Contract.mintWhiteListII(proof, true, {
      gasPrice: 1000000000,
      gasLimit: 8500000,
      value: ethers.utils.parseEther('0.138'),
    });

    console.log('Bought WhiteListII');

    // await AGStakeContract.stakeSingleOG(1, 1, options);
    // console.log('single staked');

    // await AGStakeContract.stakeAll();
    // console.log('all staked');

    setTimeout(async () => {
      await AGStakeContract.claim(options);

      let rewards = await GangTokenContract.balanceOf(
        signer.getAddress(),
        options
      );
      // const rewardInt = rewards.integerValue(); , ParseInt(rewards, 16)
      console.log(rewards.toString());
    }, 30 * 1000);

    // const [owner, second, buyer] = await ethers.getSigners();
    // console.log(owner, second, buyer);

    // newContractInstance = await contract.send({
    //   from: accounts[0],
    //   gas: 1500000,
    //   gasPrice: '30000000000'
    // })
  } catch (e) {
    console.log(e.message);
  }
})();
