var Bank = artifacts.require("./Bank.sol");
var Wallet = artifacts.require("./Wallet.sol");

const {
    BN,
    time,
    ether,
    balance,
    constants,
    expectEvent,
    expectRevert
} = require('openzeppelin-test-helpers');
const {
    expect
} = require('chai');

contract("createWallet", function (accounts) {
    const BANK_OWNER = accounts[0];
    const WALLET_OWNER_1 = accounts[1];
    const WALLET_OWNER_2 = accounts[2];
    const OTHER = accounts[3];

    let bank;

    beforeEach("setup", async () => {
        await time.advanceBlock();
        bank = await Bank.new();
    });

    describe("withdraw", () => {
        beforeEach("create wallet", async () => {
            await bank.createWallet(WALLET_OWNER_1, {
                value: ether("1")
            });
        });

        it("should fail if onlyWhileWalletManagementAllowed == false", async () => {
            await bank.updateWalletManagementAllowance(false);

            let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
            await expectRevert(bank.withdrawWallet(walletAddresses[0], ether("0.5"), {
                from: WALLET_OWNER_1
            }), "No wallet modifying");
        });

        it("should fail if not wallet owner", async () => {
            let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
            await expectRevert(bank.withdrawWallet(walletAddresses[0], ether("0.5"), {
                from: WALLET_OWNER_2
            }), "not wallet owner");
        });

        it("should transfer funds", async () => {
            let balanceBefore = new BN(await web3.eth.getBalance(WALLET_OWNER_1));

            let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
            let tx = await bank.withdrawWallet(walletAddresses[0], ether("0.5"), {
                from: WALLET_OWNER_1
            });
            let gasUsed = new BN(tx.receipt.gasUsed);
            let txInfo = await web3.eth.getTransaction(tx.tx);
            let gasPrice = new BN(txInfo.gasPrice);
            let gasSpent = gasUsed.mul(gasPrice);

            let balanceAfter = new BN(await web3.eth.getBalance(WALLET_OWNER_1));

            assert.equal(0, balanceAfter.add(gasSpent).sub(ether("0.5")).cmp(balanceBefore), "wrong balance after withdraw");
        });

        it("should update depositsTotal", async () => {
            let depositsTotalBefore = await bank.getDepositsTotal.call();

            let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
            let tx = await bank.withdrawWallet(walletAddresses[0], ether("0.5"), {
                from: WALLET_OWNER_1
            });
            let depositsTotalAfter = await bank.getDepositsTotal.call();

            assert.equal(0, depositsTotalBefore.sub(depositsTotalAfter).cmp(ether("0.5")), "wrong depositsTotal after withdrawal");
        });
    });

    describe("transfer", () => {
        beforeEach("create wallet", async () => {
            await bank.createWallet(WALLET_OWNER_1, {
                value: ether("1")
            });
        });

        it("should fail if onlyWhileWalletManagementAllowed == false", async () => {
            await bank.updateWalletManagementAllowance(false);

            let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
            await expectRevert(bank.transferFunds(walletAddresses[0], ether("0.2"), OTHER, {
                from: WALLET_OWNER_1,
                value: ether("0.01")
            }), "No wallet modifying");
        });

        it("should fail if wrong fee provided", async () => {
            let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
            await expectRevert(bank.transferFunds(walletAddresses[0], ether("0.2"), OTHER, {
                from: WALLET_OWNER_1,
                value: ether("0.1")
            }), "wrong fee provided");
        });

        it("should fail if amount == 0", async () => {
            let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
            await expectRevert(bank.transferFunds(walletAddresses[0], ether("0"), OTHER, {
                from: WALLET_OWNER_1,
                value: ether("0.01")
            }), "wrong amount");
        });

        it("should fail if receiver is 0x0", async () => {
            let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
            await expectRevert(bank.transferFunds(walletAddresses[0], ether("0.3"), "0x0000000000000000000000000000000000000000", {
                from: WALLET_OWNER_1,
                value: ether("0.01")
            }), "wrong to");
        });

        it("should fail if not wallet owner", async () => {
            let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
            await expectRevert(bank.transferFunds(walletAddresses[0], ether("0.3"), OTHER, {
                from: WALLET_OWNER_2,
                value: ether("0.01")
            }), "not wallet owner");
        });

        it("should transfer funds", async () => {
            let balanceBefore = new BN(await web3.eth.getBalance(OTHER));

            let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
            await bank.transferFunds(walletAddresses[0], ether("0.2"), OTHER, {
                from: WALLET_OWNER_1,
                value: ether("0.01")
            });

            let balanceAfter = new BN(await web3.eth.getBalance(OTHER));

            assert.equal(0, balanceAfter.sub(balanceBefore).cmp(ether("0.2")), "wrong balance after transfer");
        });
    });
});