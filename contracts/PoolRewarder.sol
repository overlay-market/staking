// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "./interfaces/IRewarder.sol";
import "./ChefV2.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";


/// @notice Use for double rewards to MCV2 pool 2 LPs
/// Inherits from SushiSwap MCV2 IRewarder. onSushiReward() hook is called
/// on every MCV2.deposit/withdraw/harvest() function call, and transfers
/// a share of additional reward tokens funds pooled in this contract to
/// MCV2 pool 2 LPs on harvest.
contract PoolRewarder is IRewarder {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;
    uint256 private immutable rewardPoolId;
    IERC20 private immutable rewardToken;
    address private immutable CHEF_V2;

    constructor (IERC20 _rewardToken, uint256 _rewardPoolId, address _CHEF_V2) public {
        rewardToken = _rewardToken;
        rewardPoolId = _rewardPoolId;
        CHEF_V2 = _CHEF_V2;
    }

    modifier onlyMCV2 {
        require(msg.sender == CHEF_V2, "!MCV2");
        _;
    }

    struct UserInfo {
        uint256 amount;
    }

    /// @notice Info of each user that stakes LP tokens in pool 2 `rewardPoolId`.
    mapping (address => UserInfo) private userInfo;

    // Sends share of pooled funds in rewarder contract to LP provider in pool `rewardPoolId` of MCV2
    function onSushiReward(uint256 _pid, address _user, address _to, uint256 _sushiAmount, uint256 _newLpAmount) onlyMCV2 override external {
        if (_pid != rewardPoolId) {
            return;
        }

        // Effects
        UserInfo storage user = userInfo[_user];
        uint256 amount = user.amount;
        user.amount = _newLpAmount;

        // Interactions
        if (amount > 0 && _sushiAmount > 0) {
            // Send reward share on harvest
            uint256 total = ChefV2(CHEF_V2).lpToken(_pid).balanceOf(CHEF_V2);
            uint256 reward = rewardToken.balanceOf(address(this)).mul(amount) / total;
            rewardToken.safeTransfer(_to, reward);
        }
    }

    function pendingTokens(uint256 _pid, address _user, uint256 _sushiAmount) override external returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) {
        IERC20[] memory _rewardTokens = new IERC20[](1);
        _rewardTokens[0] = (rewardToken);
        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = pendingToken(_pid, _user);
        return (_rewardTokens, _rewardAmounts);
    }

    function pendingToken(uint256 _pid, address _user) public returns (uint256) {
        if (_pid != rewardPoolId) {
            return 0;
        }
        uint256 total = ChefV2(CHEF_V2).lpToken(_pid).balanceOf(CHEF_V2);
        uint256 amount = userInfo[_user].amount;
        return rewardToken.balanceOf(address(this)).mul(amount) / total;
    }
}
