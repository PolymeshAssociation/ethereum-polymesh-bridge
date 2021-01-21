module.exports = {
    norpc: true,
    port: 8545,
    copyPackages: ['openzeppelin-solidity'],
    testCommand: 'node --max-old-space-size=3500 ../node_modules/.bin/truffle test `find test/*.js` --network coverage',
    skipFiles: ['mock'],
};
