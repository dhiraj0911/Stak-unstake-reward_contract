// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingToken is ERC20 {
    using SafeMath for uint256;

    // Structure
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }

    uint256 public constant REWARD_RATE = 10; 
    uint256 public constant REWARD_INTERVAL = 1 days; 
    uint256 public constant REWARD_DURATION = 365 days;

    mapping(address => Stake) public stakingInfo;
    mapping(address => uint256) public rewards;

    constructor() ERC20("Staking Token", "STK") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(stakingInfo[msg.sender].amount == 0, "You already have an active stake");

        _transfer(msg.sender, address(this), amount);

        stakingInfo[msg.sender] = Stake(amount, block.timestamp, 0, true);
    }

    function unstake() external {
        require(stakingInfo[msg.sender].active, "No active stake");

        Stake storage stake = stakingInfo[msg.sender];
        require(stake.endTime == 0, "Stake already withdrawn");

        stake.endTime = block.timestamp;
        uint256 stakingDuration = stake.endTime.sub(stake.startTime);
        require(stakingDuration >= REWARD_INTERVAL, "Minimum staking duration not reached");

        uint256 reward = calculateReward(stake.amount, stakingDuration);
        rewards[msg.sender] = rewards[msg.sender].add(reward);

        _transfer(address(this), msg.sender, stake.amount);
    }

    function claimRewards() external {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        rewards[msg.sender] = 0;
        _mint(msg.sender, reward);
    }

    function calculateReward(uint256 amount, uint256 duration) internal view returns (uint256) {
        uint256 reward = amount.mul(REWARD_RATE).mul(duration).div(REWARD_DURATION);
        return reward;
    }
}
