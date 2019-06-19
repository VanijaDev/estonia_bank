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

  let bank;

  beforeEach("setup", async () => {
    await time.advanceBlock();
    bank = await Bank.new();
  });

  describe("Create wallet", () => {
    it("should fail if onlyWhileWalletCreationAllowed == false", async () => {
      await bank.updateWalletCreationAllowance(false);

      await expectRevert(bank.createWallet(WALLET_OWNER_1, {
        value: ether("1")
      }), "No new wallets");
    });

    it("should fail if msg.value < minDeposit", async () => {
      await expectRevert(bank.createWallet(WALLET_OWNER_1, {
        value: ether("0.01")
      }), "wrong value");
    });

    it("should fail if wallets limit reached", async () => {
      //  1
      await bank.createWallet(WALLET_OWNER_1, {
        value: ether("1")
      });

      //  2
      await bank.createWallet(WALLET_OWNER_1, {
        value: ether("1.1")
      });

      //  3
      await expectRevert(bank.createWallet(WALLET_OWNER_1, {
        value: ether("1.3")
      }), "limit reached");
    });

    it("should add newly created wallet address to walletAddressesForOwnerAddress", async () => {
      await bank.createWallet(WALLET_OWNER_1, {
        value: ether("1")
      });

      let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
      assert.equal(walletAddresses.length, 1, "should be 1 address");
    });

    it("should increase walletsAmount", async () => {
      await bank.createWallet(WALLET_OWNER_1, {
        value: ether("1")
      });

      assert.equal(await bank.walletsAmount.call(), 1, "wrong walletsAmount");
    });

    it("should update depositsTotal", async () => {
      await bank.createWallet(WALLET_OWNER_1, {
        value: ether("1")
      });

      assert.equal(0, (await bank.getDepositsTotal.call()).cmp(ether("1")), "wrong depositsTotal");
    });
  });

  describe("deposit", () => {
    beforeEach("create wallet", async () => {
      await bank.createWallet(WALLET_OWNER_1, {
        value: ether("1")
      });
    });

    it("should fail if onlyWhileWalletManagementAllowed == false", async () => {
      // 1
      await bank.updateWalletManagementAllowance(false);

      let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);

      // 2
      await expectRevert(bank.depositWallet(walletAddresses[0], {
        from: WALLET_OWNER_1,
        value: ether("2")
      }), "No wallet modifying");
    });

    it("should fail if wrong deposit value", async () => {
      let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
      await expectRevert(bank.depositWallet(walletAddresses[0], {
        from: WALLET_OWNER_1,
        value: ether("0.02")
      }), "wrong deposit value");
    });

    it("should fail if not wallet owner", async () => {
      let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
      await expectRevert(bank.depositWallet(walletAddresses[0], {
        from: WALLET_OWNER_2,
        value: ether("1")
      }), "not wallet owner");
    });

    it("should update Wallet balance", async () => {
      let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
      await bank.depositWallet(walletAddresses[0], {
        from: WALLET_OWNER_1,
        value: ether("1")
      });

      let wallet = await Wallet.at(walletAddresses[0]);
      assert.equal(0, (await wallet.getBalance.call()).cmp(ether("2")), "wrong balance");
    });

    it("should update depositsTotal", async () => {
      let walletAddresses = await bank.walletAddressesForAddress.call(WALLET_OWNER_1);
      await bank.depositWallet(walletAddresses[0], {
        from: WALLET_OWNER_1,
        value: ether("1")
      });

      assert.equal(0, (await bank.getDepositsTotal.call()).cmp(ether("2")), "wrong depositTotal");
    });
  });
});