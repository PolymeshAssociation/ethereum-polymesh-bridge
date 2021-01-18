const PolyLocker      = artifacts.require("PolyLocker.sol");
const PolyToken       = artifacts.require("PolyTokenFaucet.sol");

module.exports = async function(deployer, network, accounts) {

    let owner;
    let polyTokenAddress;
    if (network === "development" || network === "coverage" || network === "develop" || network === "test") {
      owner = accounts[0];
      await deployer.deploy(PolyToken, {from: owner});
      polyTokenAddress = (await PolyToken.deployed()).address;
    } else if (network === "kovan" || network === "kovan-fork") {
      owner = accounts[0];
      polyTokenAddress = web3.utils.toChecksumAddress("0xb347b9f5b56b431b2cf4e1d90a5995f7519ca792");
    } else if (network === "goerli") {
      owner = accounts[0];
      polyTokenAddress = web3.utils.toChecksumAddress("0x5af7f19575c1b0638994158e1137698701a18c67");
    } else if (network === "mainnet") {
      owner = accounts[0];
      polyTokenAddress = web3.utils.toChecksumAddress("0x9992eC3cF6A55b00978cdDF2b27BC6882d88D1eC");
    }
    // Deploy the contract set over the selected network
    await deployer.deploy(PolyLocker, polyTokenAddress, {from: owner});
    let polyLockerAddress = (await PolyLocker.deployed()).address;
    console.log(`
      ----------------------- Locker Contracts Details ------------------------------
      PolyLocker:                       ${polyLockerAddress}
      PolyToken:                        ${polyTokenAddress}
      --------------------------------------------------------------------------------
    `);
};
