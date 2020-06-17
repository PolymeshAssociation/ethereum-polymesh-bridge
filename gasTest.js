const Web3 = require("web3");
const BN = Web3.utils.BN;
require("dotenv").config();

const web3 = new Web3(new Web3.providers.HttpProvider(process.env.KOVAN_ENDPOINT));
const polyLockerProxyAddress = web3.utils.toChecksumAddress(process.env.POLY_LOCKER_PROXY_ADDRESS);
const polyTokenAddress = web3.utils.toChecksumAddress(process.env.POLY_TOKEN_ADDRESS);
const from = web3.utils.toChecksumAddress(process.env.GAS_PAYER);
const privateKey = process.env.PRIVATE_KEY;
const burstContractAddress = web3.utils.toChecksumAddress("0x16ae02bd627217c04b25b2a1444a6f8928adecc0");
const burstContractABI = [
	{
		"constant": false,
		"inputs": [
			{
				"name": "_contractAddress",
				"type": "address"
			},
			{
				"name": "_tokenAddress",
				"type": "address"
			}
		],
		"name": "approveToken",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_contractAddress",
				"type": "address"
			},
			{
				"name": "_iterations",
				"type": "uint256"
			},
			{
				"name": "_meshAddress",
				"type": "string"
			}
		],
		"name": "burstPolyLimitLock",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_contractAddress",
				"type": "address"
			},
			{
				"name": "_iterations",
				"type": "uint256"
			},
			{
				"name": "_meshAddress",
				"type": "string"
			}
		],
		"name": "burstPolyLock",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	}
]

let lockerABI;
let polyTokenABI;

try {
    lockerABI = JSON.parse(require("fs").readFileSync("./build/contracts/PolyLocker.json", "utf-8").toString()).abi;
    polyTokenABI = JSON.parse(require("fs").readFileSync("./build/contracts/PolyTokenFaucet.json", "utf-8").toString()).abi;
} catch (error) {
    console.log(error);
    process.exit(1);
}

async function testGas(type) {

    const polyLocker = await new web3.eth.Contract(lockerABI, polyLockerProxyAddress, {
        from: from,
        gasPrice: 1000000000 // 1 gwei
    });

    const polyToken = await new web3.eth.Contract(polyTokenABI, polyTokenAddress, {
        from: from,
        gasPrice: 1000000000 // 1 gwei
    });

    const burstTxns = await new web3.eth.Contract(burstContractABI, burstContractAddress, {
        from: from,
        gasPrice: 1000000000 // 1 gwei
    });

    // Approve sufficient amount
    console.log(`Allowance provided ${web3.utils.fromWei((await polyToken.methods.allowance(from, polyLockerProxyAddress).call()).toString())} POLY`);
    if ((await polyToken.methods.allowance(from, polyLockerProxyAddress).call()).toString() == 0) {
        let txData = polyToken.methods.approve(polyLockerProxyAddress, web3.utils.toWei("1000")).encodeABI();
        let estimatedGas = await polyToken.methods.approve(polyLockerProxyAddress, web3.utils.toWei("1000")).estimateGas({from: from});
        console.log(`Estimated gas for the txn - ${estimatedGas}`);
        await sendSignedTransaction(from, polyTokenAddress, estimatedGas, 0, txData);
    } 
    
    // check for the block-depth logic
    let currentBlock = await web3.eth.getBlockNumber();
    console.log("Current block number in kovan", currentBlock);

    switch(type) {
        case 1: {
            // Case 1: submitting a transaction one by one
            // Predicted behaviour - first 5 txn will have normal gas consumption while
            // next ones have 500K more as the penalty
            for (let i = 0; i < 12; i++) {
                let txData = polyLocker.methods.limitLock(process.env.DUMMY_MESH_ADDRESS, web3.utils.toWei("1")).encodeABI();
                let estimatedGas = await polyLocker.methods.limitLock(process.env.DUMMY_MESH_ADDRESS, web3.utils.toWei("1")).estimateGas({from: from});
                console.log(`Estimated gas for the Poly LimitLock txn no. ${i} - ${estimatedGas}`); 
                if (i > 5) {
                    estimatedGas = 500000 + 92272; // Penalty + actual usage
                    console.log(`Manual Estimated gas for the Poly LimitLock txn no. ${i} - ${estimatedGas}`); 
                }
                await sendSignedTransaction(from, polyLockerProxyAddress, parseInt(estimatedGas * 1.2), 0, txData);
            }
        }
        break;
        case 2:  {
            // Case 2: submit some txn one by one then submit a burst and check the gas usage
            // of the transaction performed after burst those should consume 4M

            for (let i = 0; i < 7; i++) {
                if (i == 2) {
                    console.log("Submit a burst");
                    console.log(`Balance of the Burst contract: ${web3.utils.fromWei((await polyToken.methods.balanceOf(burstContractAddress).call()).toString())} POLY`);

                    if ((await polyToken.methods.balanceOf(burstContractAddress).call()).toString() == 0) {
                        let txData = polyToken.methods.getTokens(web3.utils.toWei("100000"), burstContractAddress).encodeABI();
                        let estimatedGas = await polyToken.methods.getTokens(web3.utils.toWei("100000"), burstContractAddress).estimateGas({from: from});
                        console.log(`Estimated gas for the txn - ${estimatedGas}`);
                        await sendSignedTransaction(from, polyTokenAddress, parseInt(estimatedGas * 1.2), 0, txData);
                    } 

                    console.log(`Allowance provided ${web3.utils.fromWei((await polyToken.methods.allowance(burstContractAddress, polyLockerProxyAddress).call()).toString())} POLY`);

                    if ((await polyToken.methods.allowance(burstContractAddress, polyLockerProxyAddress).call()).toString() == 0) {
                        // Approving lots of Token
                        let txData = burstTxns.methods.approveToken(polyLockerProxyAddress, polyTokenAddress).encodeABI();
                        let estimatedGas = await burstTxns.methods.approveToken(polyLockerProxyAddress, polyTokenAddress).estimateGas({from: from});
                        console.log(`Estimated gas for the txn - ${estimatedGas}`);
                        await sendSignedTransaction(from, burstContractAddress, parseInt(estimatedGas * 1.2), 0, txData);
                    } 

                    let txData = burstTxns.methods.burstPolyLimitLock(polyLockerProxyAddress, 11, process.env.DUMMY_MESH_ADDRESS).encodeABI();
                    let estimatedGas = await burstTxns.methods.burstPolyLimitLock(polyLockerProxyAddress, 11, process.env.DUMMY_MESH_ADDRESS).estimateGas({from: from});
                    console.log(`Estimated gas for the burst txn no. ${i} - ${estimatedGas}`); 
                    await sendSignedTransaction(from, burstContractAddress, parseInt(estimatedGas * 1.1), 0, txData);
                } else {
                    let txData = polyLocker.methods.limitLock(process.env.DUMMY_MESH_ADDRESS, web3.utils.toWei("1")).encodeABI();
                    let estimatedGas = await polyLocker.methods.limitLock(process.env.DUMMY_MESH_ADDRESS, web3.utils.toWei("1")).estimateGas({from: from});
                    console.log(`Estimated gas for the Poly LimitLock txn no. ${i} - ${estimatedGas}`); 
                    if (i > 2) {
                        estimatedGas = 4000000 + 92272; // Penalty + actual usage
                        console.log(`Manual Estimated gas for the Poly LimitLock txn no. ${i} - ${estimatedGas}`); 
                    }
                    await sendSignedTransaction(from, polyLockerProxyAddress, parseInt(estimatedGas * 1.2), 0, txData);
                }
            }
        }
        break;
    } 
};

async function sendSignedTransaction(fromAddress, toAddress, gasLimit, value, txData) {
    
    const tx = {
        // this could be provider.addresses[0] if it exists
        from: fromAddress, 
        // target address, this could be a smart contract address
        to: toAddress, 
        // optional if you want to specify the gas limit 
        gas: gasLimit, 
        // optional if you are invoking say a payable function 
        value: value,
        // this encodes the ABI of the method and the arguments
        data: txData 
    };

    const signedTx = await web3.eth.accounts.signTransaction(tx, privateKey);
    const sentTx = await web3.eth.sendSignedTransaction(signedTx.raw || signedTx.rawTransaction);
    console.log(`
        Transaction hash: ${sentTx.transactionHash}
        Transaction Included in the block: ${sentTx.blockNumber}
        CumulativeGasUsed by the txn: ${sentTx.gasUsed}
        Is transaction passed: ${sentTx.status}
    `);
}

testGas(1);