// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardsToken is IERC20 {
  function mint(address, uint256) external;
}
