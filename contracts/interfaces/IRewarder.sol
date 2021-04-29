// SPDX-License-Identifier: MIT

// COPIED from SushiSwap
// https://github.com/sushiswap/sushiswap/blob/master/contracts/interfaces/IRewarder.sol
// commit hash e409abb8dc7de6b0b1dcd60c81ea2651e54b4dd9

pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
interface IRewarder {
    using BoringERC20 for IERC20;
    function onSushiReward(uint256 pid, address user, address recipient, uint256 sushiAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 sushiAmount) external view returns (IERC20[] memory, uint256[] memory);
}
