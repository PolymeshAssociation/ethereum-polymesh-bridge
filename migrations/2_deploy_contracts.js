const fs = require("fs");

const PolyLocker      = artifacts.require("PolyLocker.sol");
const PolyLockerProxy = artifacts.require("PolyLockerProxy.sol");
const PolyToken       = artifacts.require("PolyTokenFaucet.sol");

module.exports = function(deployer, network, accounts) {

    if(network === "development" || network === "coverage") {
        let Owner = accounts[0];
        let polyTokenAddress;
        let polyLockerAddress;

        deployer.deploy(PolyToken, {from: Owner})
        .then((polyToken) => {
            polyTokenAddress = polyToken.address;
            return deployer.deploy(PolyLocker, {from: Owner});
        })
        .then((polyLocker) => {
            polyLockerAddress = polyLocker.address;
            return deployer.deploy(PolyLockerProxy, "1.0.0", polyLockerAddress, polyTokenAddress, {from: Owner});
        })
        .then(() => {
            fs.writeFileSync('contracts.json', `
{
    "contracts": {
      "PolyToken": ${JSON.stringify(polyTokenAddress)},
      "PolyLocker": ${JSON.stringify(polyLockerAddress)}
    }
}
        `);
        })
        .catch((err) => {
            console.error("Deployment failed", err);
        });
    } else {
        let polyLockerAddress;

        deployer.deploy(PolyLocker)
        .then((polyLocker) => {
            polyLockerAddress = polyLocker.address;
            return deployer.deploy(PolyLockerProxy, "1.0.0", polyLockerAddress, process.env.POLY_TOKEN_ADDRESS);
        })
        .then(() => {
            fs.writeFileSync('contracts.json', `
{
    "contracts": {
      "PolyToken": ${JSON.stringify(process.env.POLY_TOKEN_ADDRESS)},
      "PolyLocker": ${JSON.stringify(polyLockerAddress)}
    }
}
        `);
        })
        .catch((err) => {
            console.error("Deployment failed", err);
        });
    }
};
