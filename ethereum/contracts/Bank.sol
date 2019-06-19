pragma solidity ^0.5.9;


import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract Bank is Ownable {
  uint256 public transferFee;

  /**
   * @dev Constructor for contract
   * @param _transferFee Fee value to be set.
   */
  constructor(uint256 _transferFee) public {
    setTransferFee(_transferFee);
  }

  /**
   * @dev Updates transfer fee.
   * @param _transferFee Fee value to be set.
   */
  function updateTransferFee(uint256 _transferFee) public onlyOwner {
    setTransferFee(_transferFee);
  }



  /**
   * PRIVATE
   */
  /**
   * @dev Sets transfer fee.
   * @param _transferFee Fee value to be set.
   */
  function setTransferFee(uint256 _transferFee) private {
    require(_transferFee > 0, "Fee must be > 0");
    transferFee = _transferFee;
  }
}
