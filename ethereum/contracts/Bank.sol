pragma solidity ^0.5.9;

import "./Wallet.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

//  TODO: add whitelist of bank employees to make changes.
/**
 * √ позволяет создать кошелек
 * √ позволяет получить список адресов с текущими балансами.
 * √ позволяет получить баланс отдельного адреса. 
 * √ создать перевод c возможностью установить комиссию.
 */

contract Bank is Ownable {
  using SafeMath for uint256;

  bool public walletCreationAllowed;  //  allows/disallows to create new wallets
  bool public walletManagementAllowed;  //  allows/disallows to modify in any way wallet by user

  uint256 public transferFee = 0.01 ether;
  uint256 public minDeposit = 0.1 ether;
  uint256 public walletLimitForAddress = 2;

  uint256 public walletsAmount;
  uint256 private depositsTotal;
  mapping(address => address[]) private walletAddressesForOwnerAddress;

  modifier onlyWhileWalletCreationAllowed() {
    require(walletCreationAllowed, "No new wallets");
    _;
  }

  modifier onlyWhileWalletManagementAllowed() {
    require(walletManagementAllowed, "No wallet modifying");
    _;
  }

  /**
   * @dev Constructor for contract
   */
  constructor() public {
  }

  /**
   * BANK MANAGEMENT
   */

   /**
   * @dev Gets total deposits.
   * @return Total deposits.
   */
   function getDepositsTotal() public view onlyOwner returns(uint256) {
     return depositsTotal;
   }

  /**
   * @dev Gets wallet balance.
   * @param _address Wallet address.
   * @return Wallet balance.
   */
  function walletBalance(address _address) public view onlyOwner returns(uint256) {
    require(ownerAddressForWalletAddress(_address) != address(0), "no wallet");
    return address(_address).balance;
  }

  function ownerAddressForWalletAddress(address _address) public view onlyOwner returns (address) {
    return Wallet(_address).getWalletOwner();
  }

  /**
   * @dev Gets wallet addresses for owner address.
   * @param _address Owner address.
   * @return Array of addresses.
   */
  function walletAddressesForAddress(address _address) public view onlyOwner returns (address[] memory) {
    return walletAddressesForOwnerAddress[_address];
  }

  /**
   * @dev Updates transfer fee.
   * @param _transferFee Fee value to be set.
   */
  function updateTransferFee(uint256 _transferFee) public onlyOwner {
    require(_transferFee > 0, "must be > 0");
    require(_transferFee != transferFee, "same value");
    transferFee = _transferFee;
  }

  /**
   * @dev Updates minimum deposit value.
   * @param _minDeposit New minimum deposit value.
   */
  function updateMinimumDeposit(uint256 _minDeposit) public onlyOwner {
    require(_minDeposit > 0, "must be > 0");
    require(_minDeposit != minDeposit, "same value");

    minDeposit = _minDeposit;
  }

  /**
   * @dev Updates wallet limit for single address.
   * @param _walletLimitForAddress New limit value.
   */
  function updateWalletLimitForAddress(uint256 _walletLimitForAddress) public onlyOwner {
    require(_walletLimitForAddress > 0, "must be > 0");
    require(_walletLimitForAddress != walletLimitForAddress, "same value");

    walletLimitForAddress = _walletLimitForAddress;
  }

  /**
   * @dev Updates if new wallets allowed to be created.
   * @param _allowed Allowed or not.
   */
  function updateWalletCreationAllowance(bool _allowed) public onlyOwner {
    require(walletCreationAllowed != _allowed, "wrong value");

    walletCreationAllowed = _allowed;
  }

  /**
   * @dev Updates if wallets can be modified by users.
   * @param _allowed Allowed or not.
   */
  function updateWalletManagementAllowance(bool _allowed) public onlyOwner {
    require(walletManagementAllowed != _allowed, "wrong value");

    walletManagementAllowed = _allowed;
  }

  /**
   * @dev Withdraws bank fees
   */
  function withdrawBankFees() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  /**
   * WALLET MANAGEMENT
   */
  /**
   * @dev Creates new wallet.
   */
  function createWallet() public payable onlyWhileWalletCreationAllowed {
    require(msg.value >= minDeposit, "wrong value");
    require(walletAddressesForOwnerAddress[msg.sender].length <= walletLimitForAddress, "limit reached");

    Wallet wallet = (new Wallet).value(msg.value)(address(msg.sender));

    walletAddressesForOwnerAddress[msg.sender].push(address(wallet));

    walletsAmount = walletsAmount.add(1);
    depositsTotal = depositsTotal.add(msg.value);
  }

  /**
   * @dev Deposits wallet.
   * @param _address Wallet address.
   */
  function depositWallet(address _address) public payable onlyWhileWalletManagementAllowed {
    require(msg.value >= minDeposit, "wrong deposit value");
    require(ownerAddressForWalletAddress(_address) == msg.sender, "not wallet owner");

    Wallet(_address).deposit.value(msg.value);

    depositsTotal = depositsTotal.add(msg.value);
  }

  /**
   * @dev Withdraws wallet.
   * @param _address Wallet address.
   */
  function withdrawWallet(address _address) public payable onlyWhileWalletManagementAllowed {
    require(ownerAddressForWalletAddress(_address) == msg.sender, "not wallet owner");

    Wallet(_address).withdraw(msg.value);

    depositsTotal = depositsTotal.sub(msg.value);
  }
  
  /**
   * @dev Transfers funds.
   * @param _address Wallet address.
   * @param _amount Amount to transfer.
   * @param _to Receiver address.
   */
  function transferFunds(address _address, uint256 _amount, address payable _to) public payable onlyWhileWalletManagementAllowed {
    require(msg.value == transferFee, "wrong fee provided");
    require(_amount > 0, "wrong amount");
    require(_to != address(0), "wrong to");
    require(ownerAddressForWalletAddress(_address) == msg.sender, "not wallet owner");

    Wallet(_address).transferFunds(_amount, _to);
  }
}
