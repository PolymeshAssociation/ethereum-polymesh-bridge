const PolyLocker = artifacts.require("PolyLocker.sol");
const PolyLockerProxy = artifacts.require("PolyLockerProxy.sol");
const PolyToken = artifacts.require("PolyTokenFaucet.sol");

module.exports = function(deployer, network, accounts) {
  
  if (network === "development") {
    deployer.deploy(PolyToken).then((polyToken) => {
      deployer.deploy(PolyLocker).then((polylocker) => {
        deployer.deploy(PolyLockerProxy, "1.0.0", polylocker.address, polyToken.address).then(() => {
        });
      });
    });
  }

  
};
