// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScholarshipStaking {
    address public owner;
    uint256 public rewardRate; // Reward rate in percentage
    uint256 public totalStaked;

    struct Stake {
        uint256 amount;
        uint256 reward;
        uint256 lastStakedTime;
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(uint256 _rewardRate) {
        owner = msg.sender;
        rewardRate = _rewardRate;
    }

    function stake() external payable {
        require(msg.value > 0, "Stake amount must be greater than zero");

        Stake storage userStake = stakes[msg.sender];

        // Update rewards based on previous stake
        if (userStake.amount > 0) {
            userStake.reward += calculateReward(msg.sender);
        }

        userStake.amount += msg.value;
        userStake.lastStakedTime = block.timestamp;

        totalStaked += msg.value;

        emit Staked(msg.sender, msg.value);
    }

    function unstake() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake to unstake");

        uint256 amountToUnstake = userStake.amount;
        uint256 reward = calculateReward(msg.sender);

        userStake.amount = 0;
        userStake.reward = 0;
        userStake.lastStakedTime = 0;

        totalStaked -= amountToUnstake;

        payable(msg.sender).transfer(amountToUnstake + reward);

        emit Unstaked(msg.sender, amountToUnstake);
        emit RewardClaimed(msg.sender, reward);
    }

    function calculateReward(address user) public view returns (uint256) {
        Stake storage userStake = stakes[user];
        uint256 stakingDuration = block.timestamp - userStake.lastStakedTime;
        return (userStake.amount * rewardRate * stakingDuration) / (365 days * 100);
    }

    function updateRewardRate(uint256 _newRate) external onlyOwner {
        rewardRate = _newRate;
    }

    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance");
        payable(owner).transfer(amount);
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
