const Migrations = artifacts.require("Migrations");

module.exports = function(deployer, network, accounts) {
  return deployer.deploy(Migrations, {from: accounts[0]}).then(() => {
  });
};
