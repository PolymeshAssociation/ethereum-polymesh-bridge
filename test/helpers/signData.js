const Web3 = require("web3");
//const sigUtil = require('eth-sig-util')
let BN = Web3.utils.BN;

function getSignData(tmAddress, meshAddress, value, nonce, pk) {
    let hash = web3.utils.soliditySha3({
        t: 'address',
        v: tmAddress
    }, {
        t: 'string',
        v: meshAddress
    }, {
        t: 'uint256',
        v: value
    }, {
        t: 'uint256',
        v: nonce
    });
    let signature = (web3.eth.accounts.sign(hash, pk)).signature;
    let data = web3.eth.abi.encodeParameters(
        ['address', 'string', 'uint256', 'uint256', 'bytes'], 
        [tmAddress, meshAddress, value.toString(), nonce.toString(), signature]
    );
    return data;
}

module.exports = {
    getSignData
}