import { catchRevert } from "./helpers/exceptions";

const PolyLocker = artifacts.require("PolyLocker");
const PolyToken = artifacts.require("PolyTokenFaucet");

const Web3 = require("web3");

contract("PolyLocker", async(accounts) => {

    let POLYLOCKER;
    let POLYTOKEN;
    let MOCKPOLYLOCKER;
    let ACCOUNT1;
    let ACCOUNT2;
    let ACCOUNT3;
    let ACCOUNT4;
    let ACCOUNT5;
    let OWNER;
    let contract_balance = 0;
    let WEB3;

    before(async() => {

        OWNER = accounts[0];
        ACCOUNT1 = accounts[1];
        ACCOUNT2 = accounts[2];
        ACCOUNT3 = accounts[3];
        ACCOUNT4 = accounts[4];
        ACCOUNT5 = accounts[5];


        POLYTOKEN = await PolyToken.new({from: OWNER});
        POLYLOCKER = await PolyLocker.new(POLYTOKEN.address, {from: OWNER});
        WEB3 = new Web3(web3.currentProvider);

        console.log(`
            -------------- Deployed Address -------------------
            * PolyLockerAddress - ${POLYLOCKER.address}
            * PolyToken - ${POLYTOKEN.address}
            ---------------------------------------------------
        `);

    });

    describe("Verify the constructor details and lock functionality of the contract", async() => {

        it("Should fail to deploy the PolyLocker contract -- Invalid address", async() => {
            await catchRevert(
                PolyLocker.new("0x0000000000000000000000000000000000000000", {from: OWNER}),
                "Invalid address"
            );
        });

        it("Should polyToken address is non zero", async() => {
            let polytoken_address = await POLYLOCKER.polyToken.call();
            assert.equal(polytoken_address, POLYTOKEN.address);
        });

        it("Should mint tokens to multiple investors", async() => {
            let signer = WEB3.eth.accounts.create();

            await POLYTOKEN.getTokens(WEB3.utils.toWei("4000"), ACCOUNT1);
            await POLYTOKEN.getTokens(WEB3.utils.toWei("50.672910247811341"), ACCOUNT2);
            await POLYTOKEN.getTokens(WEB3.utils.toWei("100.456789"), ACCOUNT3);
            await POLYTOKEN.getTokens(WEB3.utils.toWei("50000"), ACCOUNT4);

            assert.equal(
                WEB3.utils.fromWei((await POLYTOKEN.balanceOf.call(ACCOUNT1)).toString()),
                4000
            );
            assert.equal(
                WEB3.utils.fromWei((await POLYTOKEN.balanceOf.call(ACCOUNT2)).toString()),
                50.672910247811341
            );
            assert.equal(
                WEB3.utils.fromWei((await POLYTOKEN.balanceOf.call(ACCOUNT3)).toString()),
                100.456789
            );
            assert.equal(
                WEB3.utils.fromWei((await POLYTOKEN.balanceOf.call(ACCOUNT4)).toString()),
                50000
            );
        });

        it("Should fail to lock Poly -- Insufficient allowance", async() => {
            const meshAddress = "5FLSigC9HGRKVhB9FiEo4Y3koPsNmBmLJbpXg2mp1hXcS59Y";

            await POLYTOKEN.approve(POLYLOCKER.address, WEB3.utils.toWei("500"), { from: ACCOUNT1 });
            await catchRevert(
                POLYLOCKER.lock(meshAddress, {from: ACCOUNT1}),
                "Insufficient tokens allowable"
            );
        });

        it("Should fail to lock POLY -- Invalid length of meshAddress", async() => {
            const meshAddress = "5FLSigC9HGRKVhB9FiEo4Y3koPsNmBmLJbpXg2mp1hXcS5Y";
            let account1_balance = await POLYTOKEN.balanceOf.call(ACCOUNT1);
            await POLYTOKEN.approve(POLYLOCKER.address, account1_balance, { from: ACCOUNT1 });

            await catchRevert(
                POLYLOCKER.lock(meshAddress, {from: ACCOUNT1}),
                "Invalid length of mesh address"
            );
        });

        it("Should fail to lock Poly -- Invalid locked amount", async() => {
            const meshAddress = "5FLSigC9HGRKVhB9FiEo4Y3koPsNmBmLJbpXg2mp1hXcS59Y";
            await catchRevert(
                POLYLOCKER.lock(meshAddress, {from: ACCOUNT5}),
                "Insufficient amount"
            );
        });

        it("Should successfully lock tokens", async() => {
            const meshAddress = "5FLSigC9HGRKVhB9FiEo4Y3koPsNmBmLJbpXg2mp1hXcS59Y";
            let tx = await POLYLOCKER.lock(meshAddress, {from: ACCOUNT1});
            contract_balance = parseFloat(WEB3.utils.fromWei((await POLYTOKEN.balanceOf.call(POLYLOCKER.address)).toString()));

            assert.equal(await POLYLOCKER.noOfeventsEmitted.call(), 1);
            assert.equal((await POLYTOKEN.balanceOf.call(ACCOUNT1)).toString(), 0);
            assert.equal(contract_balance, 4000);
            assert.equal(tx.logs[0].args._id, 1);
            assert.equal(tx.logs[0].args._holder, ACCOUNT1);
            assert.equal(tx.logs[0].args._meshAddress, meshAddress);
            assert.equal(tx.logs[0].args._polymeshBalance.toNumber(), 4000000000);
        });
    });

    describe("Test case for the limit lock", async() => {

        it("Should fail to lock the Poly -- Insufficient funds", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            await POLYTOKEN.approve(POLYLOCKER.address, WEB3.utils.toWei("500"), { from: ACCOUNT5 });
            await catchRevert(
                POLYLOCKER.limitLock(meshAddress, WEB3.utils.toWei("500"), {from: ACCOUNT5}),
                "Insufficient tokens transferable"
            );
        });

        it("Should successfully lock the tokens using limit lock", async() => {
            await POLYTOKEN.approve(POLYLOCKER.address, WEB3.utils.toWei("500.24"), { from: ACCOUNT4 });
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let tx = await POLYLOCKER.limitLock(meshAddress, WEB3.utils.toWei("500.24"), {from: ACCOUNT4});
            contract_balance = parseFloat(WEB3.utils.fromWei((await POLYTOKEN.balanceOf.call(POLYLOCKER.address)).toString()));

            assert.equal(WEB3.utils.fromWei((await POLYTOKEN.balanceOf.call(ACCOUNT4)).toString()), 49499.76);
            assert.equal(contract_balance, 4500.24);
            assert.equal(tx.logs[0].args._holder, ACCOUNT4);
            assert.equal(tx.logs[0].args._meshAddress, meshAddress);
            assert.equal(tx.logs[0].args._polymeshBalance.toNumber(), 500240000);
        });

        it("Should successfully lock poly which doesn't has right precision leave dust behind", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let account2_balance = await POLYTOKEN.balanceOf.call(ACCOUNT2);
            await POLYTOKEN.approve(POLYLOCKER.address, account2_balance, { from: ACCOUNT2 });
            let tx = await POLYLOCKER.lock(meshAddress, {from: ACCOUNT2});
            contract_balance = parseFloat(WEB3.utils.fromWei((await POLYTOKEN.balanceOf.call(POLYLOCKER.address)).toString()));
            assert.equal((await POLYTOKEN.balanceOf.call(ACCOUNT2)).toNumber(), 247811341000);
            assert.equal(contract_balance, 4550.91291);
            assert.equal(tx.logs[0].args._holder, ACCOUNT2);
            assert.equal(tx.logs[0].args._meshAddress, meshAddress);
            assert.equal((tx.logs[0].args._polymeshBalance).toNumber(), 50672910);
        });

        it("Should fail to lock dust because of invalid granularity of the tokens", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            await catchRevert(
                POLYLOCKER.lock(meshAddress, {from: ACCOUNT2}),
                "Insufficient amount"
            );
        });

        it("Should successfully lock all POLY as balance has valid granularity", async() => {
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let account3_balance = await POLYTOKEN.balanceOf.call(ACCOUNT3);
            await POLYTOKEN.approve(POLYLOCKER.address, account3_balance, { from: ACCOUNT3 });
            let tx = await POLYLOCKER.lock(meshAddress, {from: ACCOUNT3});
            contract_balance = parseFloat(WEB3.utils.fromWei((await POLYTOKEN.balanceOf.call(POLYLOCKER.address)).toString()));

            assert.equal(WEB3.utils.fromWei((await POLYTOKEN.balanceOf.call(ACCOUNT3)).toString()), 0);
            assert.equal(contract_balance, 4651.369699);
            assert.equal(tx.logs[0].args._holder, ACCOUNT3);
            assert.equal(tx.logs[0].args._meshAddress, meshAddress);
            assert.equal(tx.logs[0].args._polymeshBalance.toNumber(), 100456789);
        });
    });

    describe("Test case for freezing and unfreezing locking", async () => {
        it("Should not allow unauthorized address to freeze locking", async () => {
            await catchRevert(
                POLYLOCKER.freezeLocking({
                    from: ACCOUNT5
                })
            );
        });

        it("Should not allow unfreezing when already unfrozen", async () => {
            await catchRevert(
                POLYLOCKER.unfreezeLocking({
                    from: OWNER
                }),
                "Already unfrozen"
            );
        });

        it("Should successfully freeze locking of tokens", async () => {
            await POLYLOCKER.freezeLocking({
                from: OWNER
            });
            assert.equal(await POLYLOCKER.frozen(), true);
            await POLYTOKEN.approve(
                POLYLOCKER.address,
                WEB3.utils.toWei("500"), {
                    from: ACCOUNT4
                }
            );
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            await catchRevert(
                POLYLOCKER.limitLock(meshAddress, WEB3.utils.toWei("500"), {
                    from: ACCOUNT4,
                }),
                "Locking frozen"
            );
        });

        it("Should not allow unauthorized address to unfreeze locking", async () => {
            await catchRevert(
                POLYLOCKER.unfreezeLocking({
                    from: ACCOUNT5
                })
            );
        });

        it("Should not allow freezing when already frozen", async () => {
            await catchRevert(
                POLYLOCKER.freezeLocking({
                    from: OWNER
                }),
                "Already frozen"
            );
        });

        it("Should successfully unfreeze locking of tokens", async () => {
            await POLYLOCKER.unfreezeLocking({
                from: OWNER
            });
            assert.equal(await POLYLOCKER.frozen(), false);

            await POLYTOKEN.approve(POLYLOCKER.address, WEB3.utils.toWei("500"), {
                from: ACCOUNT4,
            });
            const meshAddress = "5FFArh9PRVqtGYRNZM8FxQALrgv185zoA91aXPszCLV9Jjr3";
            let tx = await POLYLOCKER.limitLock(
                meshAddress,
                WEB3.utils.toWei("500"), {
                    from: ACCOUNT4
                }
            );

            assert.equal(tx.logs[0].args._holder, ACCOUNT4);
            assert.equal(tx.logs[0].args._meshAddress, meshAddress);
            assert.equal((tx.logs[0].args._polymeshBalance).toString(), 500000000);
        });
    });
})
