import { catchRevert } from "./helpers/exceptions";
import { getSignData } from "./helpers/signData";
import { pk } from "./helpers/testPrivateKey";
import { increaseTime } from "./helpers/time";

const PolyLocker = artifacts.require("PolyLocker");
const PolyLockerProxy = artifacts.require("PolyLockerProxy");
const PolyToken = artifacts.require("PolyTokenFaucet");
const MockPolyLocker = artifacts.require("MockPolyLocker");

const Web3 = require("web3");
let BN = Web3.utils.BN;
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545")); // Hardcoded development port

contract("PolyLocker", async(accounts) => {

    let POLYLOCKER;
    let POLYLOCKERPROXY;
    let POLYTOKEN;
    let I_POLYLOCKER;
    let MOCKPOLYLOCKER;
    let ACCOUNT1;
    let ACCOUNT2;
    let ACCOUNT3;
    let ACCOUNT4;
    let ACCOUNT5;
    let OWNER;
    let SIGNER;
    let SIGNERPRIVATEKEY;
    let contract_balance = 0;

    before(async() => {

        OWNER = accounts[0];
        ACCOUNT1 = accounts[1];
        ACCOUNT2 = accounts[2];
        ACCOUNT3 = accounts[3];
        ACCOUNT4 = accounts[4];
        ACCOUNT5 = accounts[5];


        POLYTOKEN = await PolyToken.new();
        POLYLOCKER = await PolyLocker.new();
        POLYLOCKERPROXY = await PolyLockerProxy.new("1.0.0", POLYLOCKER.address, POLYTOKEN.address, {from: OWNER});

        console.log(`
            -------------- Deployed Address -------------------
            * PolyLockerAddress - ${POLYLOCKER.address}
            * PolyLockerProxy - ${POLYLOCKERPROXY.address}
            * PolyToken - ${POLYTOKEN.address}
            ---------------------------------------------------
        `);

    });

    describe("Verify the constructor details and lock functionality of the contract", async() => {

        it("Should fail to deploy the PolyLockerProxy contract -- Implementation address should not be 0x", async() => {
            await catchRevert(
                PolyLockerProxy.new("1.0.0", "0x0000000000000000000000000000000000000000", POLYTOKEN.address, {from: OWNER}),
                "Implementation address should not be 0x"
            );
        });

        it("Should fail to deploy the PolyLockerProxy contract -- Invalid address", async() => {
            await catchRevert(
                PolyLockerProxy.new("1.0.0", POLYLOCKER.address, "0x0000000000000000000000000000000000000000", {from: OWNER}),
                "Invalid address"
            );
        });

        it("Should polyToken address is non zero", async() => {
            let implementationAddress = await POLYLOCKERPROXY.implementation.call({from: OWNER});
            assert.equal(implementationAddress, POLYLOCKER.address, "Invalid implementation address set");
            I_POLYLOCKER = await PolyLocker.at(POLYLOCKERPROXY.address);
            let polytoken_address = await I_POLYLOCKER.polyToken.call();
            assert.equal(polytoken_address, POLYTOKEN.address);
        });

        it("Should mint tokens to multiple investors", async() => {
            let signer = web3.eth.accounts.create();
            SIGNER = signer.address;
            SIGNERPRIVATEKEY = signer.privateKey;

            await POLYTOKEN.getTokens(web3.utils.toWei("4000"), ACCOUNT1);
            await POLYTOKEN.getTokens(web3.utils.toWei("50.672910247811341"), ACCOUNT2);
            await POLYTOKEN.getTokens(web3.utils.toWei("100.456789"), ACCOUNT3);
            await POLYTOKEN.getTokens(web3.utils.toWei("50000"), ACCOUNT4);
            await POLYTOKEN.getTokens(web3.utils.toWei("5000"), SIGNER);

            assert.equal(
                web3.utils.fromWei((await POLYTOKEN.balanceOf.call(ACCOUNT1)).toString()),
                4000
            );
            assert.equal(
                web3.utils.fromWei((await POLYTOKEN.balanceOf.call(ACCOUNT2)).toString()),
                50.672910247811341
            );
            assert.equal(
                web3.utils.fromWei((await POLYTOKEN.balanceOf.call(ACCOUNT3)).toString()),
                100.456789
            );
            assert.equal(
                web3.utils.fromWei((await POLYTOKEN.balanceOf.call(ACCOUNT4)).toString()),
                50000
            );
            assert.equal(
                web3.utils.fromWei((await POLYTOKEN.balanceOf.call(SIGNER)).toString()),
                5000
            );
        });

        it("Should fail to lock Poly -- Insufficient allowance", async() => {
            const meshAddress = "5FLSigC9HGRKVhB9FiEo4Y3koPsNmBmLJbpXg2mp1hXcS59Y";

            await POLYTOKEN.approve(I_POLYLOCKER.address, web3.utils.toWei("500"), { from: ACCOUNT1 });
            await catchRevert(
                I_POLYLOCKER.lock(meshAddress, {from: ACCOUNT1}),
                "Insufficient tokens allowable"
            );
        });

        it("Should fail to lock POLY -- Invalid length of meshAddress", async() => {
            const meshAddress = "5FLSigC9HGRKVhB9FiEo4Y3koPsNmBmLJbpXg2mp1hXcS5Y";
            let account1_balance = await POLYTOKEN.balanceOf.call(ACCOUNT1);
            await POLYTOKEN.approve(I_POLYLOCKER.address, account1_balance, { from: ACCOUNT1 });

            await catchRevert(
                I_POLYLOCKER.lock(meshAddress, {from: ACCOUNT1}),
                "Invalid length of mesh address"
            );
        });

        it("Should fail to lock Poly -- Invalid locked amount", async() => {
            const meshAddress = "5FLSigC9HGRKVhB9FiEo4Y3koPsNmBmLJbpXg2mp1hXcS59Y";
            await catchRevert(
                I_POLYLOCKER.lock(meshAddress, {from: ACCOUNT5}),
                "Minimum amount to transfer to Polymesh is 1 POLYX -- Reason given: Minimum amount to transfer to Polymesh is 1 POLYX."
            );
        });

        it("Should successfully lock tokens", async() => {
            const meshAddress = "5FLSigC9HGRKVhB9FiEo4Y3koPsNmBmLJbpXg2mp1hXcS59Y";
            let tx = await I_POLYLOCKER.lock(meshAddress, {from: ACCOUNT1});
            contract_balance = parseFloat(web3.utils.fromWei((await POLYTOKEN.balanceOf.call(I_POLYLOCKER.address)).toString()));

            assert.equal(await I_POLYLOCKER.noOfeventsEmitted.call(), 1);
            assert.equal((await POLYTOKEN.balanceOf.call(ACCOUNT1)).toString(), 0);
            assert.equal(contract_balance, 4000);
            assert.equal(tx.logs[0].args._id, 0);
            assert.equal(tx.logs[0].args._holder, ACCOUNT1);
            assert.equal(tx.logs[0].args._meshAddress, meshAddress);
            assert.equal(tx.logs[0].args._polymeshBalance.toNumber(), 4000000000);
        });
    });

    describe("Test case for the limit lock", async() => {

        it("Should fail to lock the Poly -- Insufficient funds", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            await POLYTOKEN.approve(I_POLYLOCKER.address, web3.utils.toWei("500"), { from: ACCOUNT5 });
            await catchRevert(
                I_POLYLOCKER.limitLock(meshAddress, web3.utils.toWei("500"), {from: ACCOUNT5}),
                "Insufficient funds"
            );
        });

        it("Should successfully lock the tokens using limit lock", async() => {
            await POLYTOKEN.approve(I_POLYLOCKER.address, web3.utils.toWei("500.24"), { from: ACCOUNT4 });
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let tx = await I_POLYLOCKER.limitLock(meshAddress, web3.utils.toWei("500.24"), {from: ACCOUNT4});
            contract_balance = parseFloat(web3.utils.fromWei((await POLYTOKEN.balanceOf.call(I_POLYLOCKER.address)).toString()));

            assert.equal(web3.utils.fromWei((await POLYTOKEN.balanceOf.call(ACCOUNT4)).toString()), 49499.76);
            assert.equal(contract_balance, 4500.24);
            assert.equal(tx.logs[0].args._holder, ACCOUNT4);
            assert.equal(tx.logs[0].args._meshAddress, meshAddress);
            assert.equal(tx.logs[0].args._polymeshBalance.toNumber(), 500240000);
        });

        it("Should successfully lock poly which doesn't has right precision leave dust behind", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let account2_balance = await POLYTOKEN.balanceOf.call(ACCOUNT2);
            await POLYTOKEN.approve(I_POLYLOCKER.address, account2_balance, { from: ACCOUNT2 });
            let tx = await I_POLYLOCKER.lock(meshAddress, {from: ACCOUNT2});
            contract_balance = parseFloat(web3.utils.fromWei((await POLYTOKEN.balanceOf.call(I_POLYLOCKER.address)).toString()));
            assert.equal((await POLYTOKEN.balanceOf.call(ACCOUNT2)).toNumber(), 247811341000);
            assert.equal(contract_balance, 4550.91291);
            assert.equal(tx.logs[0].args._holder, ACCOUNT2);
            assert.equal(tx.logs[0].args._meshAddress, meshAddress);
            assert.equal((tx.logs[0].args._polymeshBalance).toNumber(), 50672910);
        });

        it("Should fail to lock dust because of invalid granularity of the tokens", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            await catchRevert(
                I_POLYLOCKER.lock(meshAddress, {from: ACCOUNT2}),
                "Minimum amount to transfer to Polymesh is 1 POLYX"
            );
        });

        it("Should successfully lock all POLY as balance has valid granularity", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let account3_balance = await POLYTOKEN.balanceOf.call(ACCOUNT3);
            await POLYTOKEN.approve(I_POLYLOCKER.address, account3_balance, { from: ACCOUNT3 });
            let tx = await I_POLYLOCKER.lock(meshAddress, {from: ACCOUNT3});
            contract_balance = parseFloat(web3.utils.fromWei((await POLYTOKEN.balanceOf.call(I_POLYLOCKER.address)).toString()));

            assert.equal(web3.utils.fromWei((await POLYTOKEN.balanceOf.call(ACCOUNT3)).toString()), 0);
            assert.equal(contract_balance, 4651.369699);
            assert.equal(tx.logs[0].args._holder, ACCOUNT3);
            assert.equal(tx.logs[0].args._meshAddress, meshAddress);
            assert.equal(tx.logs[0].args._polymeshBalance.toNumber(), 100456789);
        });
    });

    describe("Test the functionality of lockWithData", async() => {

        it("Should fail to lock Poly using lockWithData -- Invalid address", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let signer_balance = await POLYTOKEN.balanceOf.call(SIGNER);
            await web3.eth.personal.importRawKey(SIGNERPRIVATEKEY, "");
            await web3.eth.personal.unlockAccount(SIGNER, "", 6000);
            await web3.eth.sendTransaction({ from: ACCOUNT5, to: SIGNER, value: web3.utils.toWei("5")});

            await POLYTOKEN.approve(I_POLYLOCKER.address, signer_balance, { from: SIGNER });
            let data = getSignData(I_POLYLOCKER.address, meshAddress, web3.utils.toWei("1000"), 1, SIGNERPRIVATEKEY);
            await catchRevert(
                I_POLYLOCKER.lockWithData(meshAddress, "0x0000000000000000000000000000000000000000", web3.utils.toWei("1000"), data, {from: ACCOUNT5}),
                "Invalid address"
            );
        });

        it("Should fail to lock Poly using lockWithData -- Invalid target address", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let data = getSignData(ACCOUNT2, meshAddress, web3.utils.toWei("1000"), 1, SIGNERPRIVATEKEY);
            await catchRevert(
                I_POLYLOCKER.lockWithData(meshAddress, SIGNER, web3.utils.toWei("1000"), data, {from: ACCOUNT5}),
                "Invalid target address"
            );
        });

        it("Should fail to lock Poly using lockWithData -- Invalid amount of tokens", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let data = getSignData(I_POLYLOCKER.address, meshAddress, web3.utils.toWei("500"), 1, SIGNERPRIVATEKEY);
            await catchRevert(
                I_POLYLOCKER.lockWithData(meshAddress, SIGNER, web3.utils.toWei("1000"), data, {from: ACCOUNT5}),
                "Invalid amount of tokens"
            );
        });

        it("Should fail to lock Poly using lockWithData -- Invalid mesh address", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let data = getSignData(I_POLYLOCKER.address, "5FFArh9PRVqtGYRNZM8FxQALrgv185zoB91aXPszCLV9Jjr3", web3.utils.toWei("1000"), 1, SIGNERPRIVATEKEY);
            await catchRevert(
                I_POLYLOCKER.lockWithData(meshAddress, SIGNER, web3.utils.toWei("1000"), data, {from: ACCOUNT5}),
                "Invalid mesh address"
            );
        });

        it("Should successfully lock Poly tokens using lockWithData", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let data = getSignData(I_POLYLOCKER.address, meshAddress, new BN(web3.utils.toWei("1000")), new BN(1), SIGNERPRIVATEKEY);
            let tx = await I_POLYLOCKER.lockWithData(meshAddress, SIGNER, new BN(web3.utils.toWei("1000")), data, {from: ACCOUNT5});
            contract_balance = parseFloat(web3.utils.fromWei((await POLYTOKEN.balanceOf.call(I_POLYLOCKER.address)).toString()));

            assert.equal(web3.utils.fromWei((await POLYTOKEN.balanceOf.call(SIGNER)).toString()), 4000);
            assert.equal(contract_balance, 5651.369699);
            assert.equal(tx.logs[0].args._holder, SIGNER);
            assert.equal(tx.logs[0].args._meshAddress, meshAddress);
            assert.equal((tx.logs[0].args._polymeshBalance).toNumber(), 1000000000);
        });

        it("Should fail to lock Poly using lockWithData -- Already used signature", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let data = getSignData(I_POLYLOCKER.address, meshAddress, web3.utils.toWei("1000"), new BN(1), SIGNERPRIVATEKEY);
            await catchRevert(
                I_POLYLOCKER.lockWithData(meshAddress, SIGNER, web3.utils.toWei("1000"), data, {from: ACCOUNT5}),
                "Already used signature"
            );
        });

        it("Should fail to lock Poly using lockWithData -- Incorrect Signer", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let data = getSignData(I_POLYLOCKER.address, meshAddress, web3.utils.toWei("1000"), new BN(2), SIGNERPRIVATEKEY);
            await catchRevert(
                I_POLYLOCKER.lockWithData(meshAddress, ACCOUNT4, web3.utils.toWei("1000"), data, {from: ACCOUNT5}),
                "Incorrect Signer"
            );
        });

        it("Should fail to lock Poly using lockWithData -- Insufficient funds", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            // generate new account
            let signer = web3.eth.accounts.create();
            let data = getSignData(I_POLYLOCKER.address, meshAddress, web3.utils.toWei("1000"), new BN(2), signer.privateKey);
            await catchRevert(
                I_POLYLOCKER.lockWithData(meshAddress, signer.address, web3.utils.toWei("1000"), data, {from: ACCOUNT5}),
                "Insufficient funds"
            );
        });

    });

    describe("Update the logic contract of the locker contract", async() => {

        it("Should propose the contract", async() => {
            MOCKPOLYLOCKER = await MockPolyLocker.new();
            await POLYLOCKERPROXY.proposeUpgrade("1.1.0", MOCKPOLYLOCKER.address, "0x0", {from: OWNER});
        });

        it("Should fail to upgrade -- Cold period not pass", async() => {
            await catchRevert(
                POLYLOCKERPROXY.upgradeTo({from: OWNER}),
                "Proposal is in unmatured state"
            );
        });

        it("Should successfully upgrade", async() => {
            await increaseTime(86470); // 24 hours increase + 70 seconds buffer
            await POLYLOCKERPROXY.upgradeTo({from: OWNER});
            assert.equal(
                await POLYLOCKERPROXY.implementation.call({from: OWNER}),
                MOCKPOLYLOCKER.address
            );
            assert.equal(
                await POLYLOCKERPROXY.version.call({from: OWNER}),
                "1.1.0"
            );
        });
    });
})
