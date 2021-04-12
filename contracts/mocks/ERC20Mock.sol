// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract ERC20Mock is ERC20 {

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _supply
  ) ERC20(_name, _symbol) public {
    _mint(msg.sender, _supply);
  }

  function mint(address _recipient, uint256 _amount) external {
    _mint(_recipient, _amount);
  }

  function burn(address _account, uint256 _amount) external {
    _burn(_account, _amount);
  }

}
