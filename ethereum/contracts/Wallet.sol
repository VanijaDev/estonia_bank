pragma solidity ^0.5.9;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Wallet is Ownable {
  address payable private walletOwner;
  uint256 private createdAt;
  uint256 private lastDepositAt;
  uint256 private lastWithdrawalAt;
  uint256 private lastTransferAt;

  event WalletCreated(address indexed walletOwner, uint256 indexed deposit, uint256 indexed createdAt);
  event WalletDepositted(uint256 indexed deposit, uint256 indexed lastDepositAt);
  event WalletWithdrawn(uint256 indexed withdrawn, uint256 indexed lastWithdrawalAt);
  event WalletTransferred(address indexed from, address indexed to, uint256 indexed amount, uint256 lastTransferAt);

  /**
   * @dev Wallet constructor.
   * @param _walletOwner Wallet owner address.
   */
  constructor(address payable _walletOwner) public payable {
    require(_walletOwner != address(0), "empty owner");

    walletOwner = _walletOwner;
    createdAt = now;

    emit WalletCreated(_walletOwner, msg.value, now);
  }

  /**
   * @dev Gets balance of current wallet.
   * @return Balance.
   * @notice No reason in onlyOwner - visible on Blockchain.
   */
  function getBalance() public view returns(uint256) {
    return address(this).balance;
  }

  /**
   * @dev Gets walletOwner/
   * @return walletOwner address.
   */
  function getWalletOwner() public view onlyOwner returns(address) {
    return walletOwner;
  }

  /**
   * @dev Gets createdAt.
   * @return createdAt timestamp.
   */
  function getCreatedAt() public view onlyOwner returns(uint256) {
    return createdAt;
  }

  /**
   * @dev Gets lastDepositAt.
   * @return lastDepositAt timestamp.
   */
  function getLastDepositAt() public view onlyOwner returns(uint256) {
    return lastDepositAt;
  }

  /**
   * @dev Gets lastWithdrawalAt.
   * @return lastWithdrawalAt timestamp.
   */
  function getLastWithdrawalAt() public view onlyOwner returns(uint256) {
    return lastWithdrawalAt;
  }

  /**
   * @dev Gets lastTransferAt.
   * @return lastTransferAt timestamp.
   */
  function getLastTransferAt() public view onlyOwner returns(uint256) {
    return lastTransferAt;
  }

  /**
   * @dev Deposits funds to wallet.
   */
  function deposit() public payable onlyOwner {
    require(msg.value > 0, "no deposit provided");

    lastDepositAt = now;
    emit WalletDepositted(msg.value, now);
  }

  /**
   * @dev Withdraws funds from wallet
   * @param _amount Amount ot withdraw.
   */
   function withdraw(uint256 _amount) public onlyOwner {
     require(_amount <= getBalance(), "not enough funds");
     walletOwner.transfer(_amount);

     lastWithdrawalAt = now;
     emit WalletWithdrawn(_amount, lastWithdrawalAt);
   }

  /**
   * @dev Transfers funds from wallet.
   * @param _amount Amount ot transfer.
   * @param _to Receiver address.
   */
   function transferFunds(uint256 _amount, address payable _to) public onlyOwner {
     require(_amount <= getBalance(), "not enough funds");
     _to.transfer(_amount);

    lastTransferAt = now;

    emit WalletTransferred(walletOwner, _to, _amount, now);
   }
}
