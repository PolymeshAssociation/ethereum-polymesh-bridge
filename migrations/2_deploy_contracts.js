const PolyLocker = artifacts.require("PolyLocker.sol");
const PolyLockerProxy = artifacts.require("PolyLockerProxy.sol");
const PolyToken = artifacts.require("PolyTokenFaucet.sol");

module.exports = function(deployer, network, accounts) {
  
  if (network === "development" || network === "coverage") {
    let Owner = accounts[0];
    deployer.deploy(PolyToken, {from: Owner}).then((polyToken) => {
      deployer.deploy(PolyLocker, {from: Owner}).then((polylocker) => {
        deployer.deploy(PolyLockerProxy, "1.0.0", polylocker.address, polyToken.address, {from: Owner}).then(() => {
        });
      });
    });
  } 
};
