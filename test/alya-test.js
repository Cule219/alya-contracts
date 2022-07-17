const { expect } = require('chai');
const { ethers } = require('hardhat');
const constants = require('../scripts/constants');

describe('Alya', function () {
  it('Should ', async function () {
    const AlyaValley = await ethers.getContractFactory('AlyaValley');
    const alya = await AlyaValley.deploy();
    await alya.deployed();

    expect(await alya.greet()).to.equal('Hello, world!');

    const setGreetingTx = await greeter.setGreeting('Hola, mundo!');

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal('Hola, mundo!');
  });
});
