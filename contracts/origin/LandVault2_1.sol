// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LandTokenStakingV2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 lastRewardBlock;            // Last block number for reward distribution.
        uint256 accRewardTokenPerShare;     // Accumulated Reward Token per share, times 1e12. See below.
    }
    
    // Staked token and Reward token
    IERC20 public _inToken;
    IERC20 public _rewardToken;
    address public _rewardVault;

    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public _userInfo;
  
    PoolInfo public _pool;

    // Reward tokens per block.
    uint256 public _rewardPerBlock;
    // The block number for farming starts.
    uint256 public _startBlock;
    // The block number when farming ends.
    uint256 public _bonusEndBlock;

    uint256 private constant E12 = 1e12;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IERC20 inToken,
        IERC20 rewardToken,
        address rewardVault,
        uint256 rewardPerBlock,
        uint256 startBlock,
        uint256 bonusEndBlock
    ) {
        require(rewardVault!=address(0), "Invalid address");
        _inToken = inToken;
        _rewardToken = rewardToken;
        _rewardVault = rewardVault;
        _rewardPerBlock = rewardPerBlock;
        _startBlock = startBlock;
        _bonusEndBlock = bonusEndBlock;

        _pool = PoolInfo({
            lastRewardBlock: startBlock,
            accRewardTokenPerShare: 0
        });
    }
    
    // Return number of blocks (for reward) since last pool update.
    function getElapsedBlockSinceUpdate() public view returns (uint256) {
        
        uint256 from = _pool.lastRewardBlock;
        uint256 to = block.number;
         
        if (to <= _bonusEndBlock) {
            return to.sub(from);
        } else if (from >= _bonusEndBlock) {
            return 0;
        } else {
            return _bonusEndBlock.sub(from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address from) public view returns (uint256) {
        UserInfo storage user = _userInfo[from];
        uint256 accRewardPerShare = _pool.accRewardTokenPerShare;
        uint256 totalStaked = _inToken.balanceOf(address(this));
        if (block.number > _pool.lastRewardBlock && totalStaked != 0) {
            uint256 num = getElapsedBlockSinceUpdate();
            uint256 tokenReward = num.mul(_rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(tokenReward.mul(E12).div(totalStaked));
        }
        return user.amount.mul(accRewardPerShare).div(E12).sub(user.rewardDebt);
    }

    // Update reward variables of the pool to be up-to-date.
    function updatePool() public {
        if (block.number <= _pool.lastRewardBlock) {
            return;
        }
        uint256 totalStaked = _inToken.balanceOf(address(this));
        if (totalStaked == 0) {
            _pool.lastRewardBlock = block.number;
            return;
        }
        uint256 num = getElapsedBlockSinceUpdate();
        uint256 tokenReward = num.mul(_rewardPerBlock);
        _pool.accRewardTokenPerShare = _pool.accRewardTokenPerShare.add(tokenReward.mul(E12).div(totalStaked));
        _pool.lastRewardBlock = block.number;
    }


    // Stake inToken tokens to earn reward tokens
    function deposit(uint256 amount) public {
        UserInfo storage user = _userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(_pool.accRewardTokenPerShare).div(E12).sub(user.rewardDebt);
            if(pending > 0) {
                _rewardToken.safeTransferFrom(_rewardVault, address(msg.sender), pending);
            }
        }
        if(amount > 0) {
            _inToken.safeTransferFrom(address(msg.sender), address(this), amount);
            user.amount = user.amount.add(amount);
        }
        user.rewardDebt = user.amount.mul(_pool.accRewardTokenPerShare).div(E12);

        emit Deposit(msg.sender, amount);
    }

    // Withdraw Lp tokens
    function withdraw(uint256 amount) public {
        UserInfo storage user = _userInfo[msg.sender];
        require(user.amount >= amount, "withdraw: amount exceeded");
        updatePool();
        uint256 pending = user.amount.mul(_pool.accRewardTokenPerShare).div(E12).sub(user.rewardDebt);
        if(pending > 0) {
            _rewardToken.safeTransferFrom(_rewardVault, address(msg.sender), pending);
        }
        if(amount > 0) {
            user.amount = user.amount.sub(amount);
            _inToken.safeTransfer(address(msg.sender), amount);
        }
        user.rewardDebt = user.amount.mul(_pool.accRewardTokenPerShare).div(E12);

        emit Withdraw(msg.sender, amount);
    }
    
    function compoundReward() external {
        require(pendingReward(msg.sender) > 0);
        uint rewardAmt = pendingReward(msg.sender);
        withdraw(0);
        deposit(rewardAmt);
    }

    function stopReward() external onlyOwner {
        _bonusEndBlock = block.number;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external {
        UserInfo storage user = _userInfo[msg.sender];
        _inToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);

        user.amount = 0;
        user.rewardDebt = 0;
    }
}