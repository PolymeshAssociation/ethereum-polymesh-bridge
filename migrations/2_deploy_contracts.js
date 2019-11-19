const PolyLocker = artifacts.require("PolyLocker.sol");
const PolyLockerProxy = artifacts.require("PolyLockerProxy.sol");

module.exports = function(deployer) {
  deployer.deploy(PolyLocker);
  deployer.deploy(PolyLockerProxy, PolyLocker, "1.0.0");
};
