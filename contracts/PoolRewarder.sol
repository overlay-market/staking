// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "./interfaces/IRewarder.sol";
import "./ChefV2.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";


/// @notice Use for double rewards to MCV2 pool 2 LPs. onSushiReward hook is called
/// on every CHEF_V2.deposit/withdraw/harvest function call, and transfers
/// a share of additional reward funds pooled in this contract to
/// LPs staking in CHEF_V2 pool with rewardPoolId on CHEF_V2.harvest.
contract PoolRewarder is IRewarder, BoringOwnable {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;
    IERC20 private immutable rewardToken;
    address private immutable CHEF_V2;

    constructor (IERC20 _rewardToken, address _CHEF_V2) public {
        rewardToken = _rewardToken;
        CHEF_V2 = _CHEF_V2;
    }

    modifier onlyMCV2 {
        require(msg.sender == CHEF_V2, "!MCV2");
        _;
    }

    /// @notice user info for amount of lp tokens staked in pool
    mapping (uint256 => mapping (address => uint256)) private userAmount;
    /// @notice per pool weights for rewards
    mapping (uint256 => uint256) public poolAllocPoint;
    uint256 public totalAllocPoint;

    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        totalAllocPoint = totalAllocPoint.sub(poolAllocPoint[_pid]).add(_allocPoint);
        poolAllocPoint[_pid] = _allocPoint;
    }

    /// @notice Sends LP's share of pending double rewards pooled in this contract
    function onSushiReward(uint256 _pid, address _user, address _to, uint256 _sushiAmount, uint256 _newLpAmount) onlyMCV2 override external {
        // Effects
        uint256 amount = userAmount[_pid][_user];
        uint256 alloc = poolAllocPoint[_pid];
        userAmount[_pid][_user] = _newLpAmount;

        // Interactions
        if (_sushiAmount > 0 && amount > 0 && alloc > 0) {
            // Send reward share on harvest
            uint256 lpSupply = ChefV2(CHEF_V2).lpToken(_pid).balanceOf(CHEF_V2);
            uint256 reward = rewardToken.balanceOf(address(this)).mul(amount) / lpSupply;
            uint256 weighted = reward.mul(alloc) / totalAllocPoint;
            rewardToken.safeTransfer(_to, weighted);
        }
    }

    /// @notice Displays LP's share of pending double rewards pooled in this contract
    function pendingTokens(uint256 _pid, address _user, uint256 _sushiAmount) override external returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) {
        IERC20[] memory _rewardTokens = new IERC20[](1);
        _rewardTokens[0] = (rewardToken);
        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = pendingToken(_pid, _user);
        return (_rewardTokens, _rewardAmounts);
    }

    function pendingToken(uint256 _pid, address _user) public view returns (uint256) {
        uint256 alloc = poolAllocPoint[_pid];
        if (alloc == 0) {
            return 0;
        }

        uint256 lpSupply = ChefV2(CHEF_V2).lpToken(_pid).balanceOf(CHEF_V2);
        uint256 amount = userAmount[_pid][_user];
        uint256 reward = rewardToken.balanceOf(address(this)).mul(amount) / lpSupply;
        return reward.mul(alloc) / totalAllocPoint;
    }
}
