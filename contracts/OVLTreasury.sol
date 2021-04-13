// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./OVLChef.sol";


contract OVLTreasury is ERC1155Holder, ERC20("OVLTreasury", "tOVL") {
    using SafeMath for uint256;

    OVLChef public chef;
    IERC20 public ovl;
    uint256 public poolId; // pool id for OVL-ETH pool 2

    constructor(
        OVLChef _chef,
        uint256 _pid,
        IERC20 _ovl
    ) public {
        chef = _chef;
        poolId = _pid;
        ovl = _ovl;
    }

    // Deposit chef pool credits to treasury for double rewards
    function deposit(uint256 _amount) public {
        // Amount of credits locked in treasury
        uint256 totalCreditsStaked = chef.balanceOf(address(this), poolId);
        // Amount of treasury shares
        uint256 totalShares = totalSupply();

        if (totalCreditsStaked == 0 || totalShares == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 shares = _amount.mul(totalShares).div(totalCreditsStaked);
            _mint(msg.sender, shares);
        }

        // Make sure chef transfer of pool credit at end given ERC1155 callback in transfer()
        chef.safeTransferFrom(msg.sender, address(this), poolId, _amount, "");
    }

    // Withdraw shares in treasury to collect double rewards and receive back pool credit
    function withdraw(uint256 _share) public {
        // Harvest oustanding rewards from chef PRIOR to transfer on behalf of all pool credits locked
        // so pool rewards are up to date
        chef.harvest(poolId, address(this));

        // Calc amount to of reward in treasury to send given shares burnt
        uint256 totalShares = totalSupply();
        uint256 rewards = _share.mul(ovl.balanceOf(address(this))).div(totalShares);
        uint256 credits = _share.mul(chef.balanceOf(address(this), poolId)).div(totalShares);

        // Burn the shares then send out the rewards and associated pool credits
        _burn(msg.sender, _share);
        ovl.transfer(msg.sender, rewards);

        // Make sure chef transfer of pool credit at end given ERC1155 callback in transfer()
        chef.safeTransferFrom(address(this), msg.sender, poolId, credits, "");
    }
}
