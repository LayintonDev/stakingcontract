// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Custom error definitions for specific error handling
error AddressZeroDetected();
error ZeroValueNotAllowed();
error CantSendToZeroAddress();
error InsufficientFunds();
error NotOwner();
error InsufficientContractBalance();
error AlreadyHaveAnActiveStake();
error LIQUIDATIONTIMENOTREACHEDYET();

/**
 * @title StakeEther
 * @dev A smart contract for staking Ether with reward calculation.
 */
contract StakeEther {
    // The owner of the contract, immutable after deployment
    address private immutable owner;

    // Event emitted when a stake is successfully made
    event StakeSuccessful(address indexed user, uint256 indexed amount);

    // Event emitted when a withdrawal is successfully made
    event WithdrawalSuccessful(address indexed user, uint256 indexed amount);

    // The interest rate set to 3% (scaled to 300 because Solidity doesn't support decimals: 3 * 100)
    uint private constant RATE = 300;

    // Precision factor to account for the scaled rate (100 * 100)
    uint private constant PRECISION_FACTOR = 10000;

    // Minimum staking duration set to 30 days (in seconds)
    uint private constant MIN_STAKING_DURATION = 30 * 24 * 60 * 60;

    // Number of seconds in a year
    uint private constant SECONDS_IN_A_YEAR = 365 * 24 * 60 * 60;

    // Mapping of user addresses to their staked balances
    mapping(address => uint) private balances;

    // Mapping of user addresses to their staking start times
    mapping(address => uint) private stakeTimes;

    /**
     * @dev Constructor to set the contract owner.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Allows a user to stake Ether.
     * The amount of Ether sent with this transaction is added to the user's staked balance.
     */
    function stake() external payable {
        // Check for invalid address
        if (msg.sender == address(0)) {
            revert AddressZeroDetected();
        }

        // Ensure the staked amount is greater than zero
        if (msg.value <= 0) {
            revert ZeroValueNotAllowed();
        }

        // Update the user's balance and stake start time
        balances[msg.sender] += msg.value;
        stakeTimes[msg.sender] = block.timestamp;

        // Emit a successful stake event
        emit StakeSuccessful(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw their staked Ether and the rewards.
     */
    function withdrawStake() external payable {
        // Check for invalid address
        if (msg.sender == address(0)) {
            revert AddressZeroDetected();
        }

        // Ensure the minimum staking duration has been met
        if (block.timestamp - stakeTimes[msg.sender] < MIN_STAKING_DURATION) {
            revert LIQUIDATIONTIMENOTREACHEDYET();
        }

        // Ensure the user has staked Ether
        if (balances[msg.sender] <= 0) {
            revert InsufficientFunds();
        }

        // Calculate the reward
        uint256 reward = calculateReward(msg.sender);

        // Store the staked amount and total (stake + reward)
        uint stakeAmount = balances[msg.sender];
        uint stakingWithReward = stakeAmount + reward;

        // Reset the user's balance and stake time
        balances[msg.sender] = 0;
        stakeTimes[msg.sender] = 0;

        // Transfer the staked amount plus rewards back to the user
        (bool success, ) = msg.sender.call{value: stakingWithReward}("");

        // Revert if the transfer fails
        if (!success) {
            revert("Withdrawal Failed");
        }

        // Emit a successful withdrawal event
        emit WithdrawalSuccessful(msg.sender, stakingWithReward);
    }

    /**
     * @dev Returns the balance of the contract.
     * @return The balance of the contract in wei.
     */
    function getContractBal() external view returns (uint) {
        // Ensure only the owner can view the contract balance
        if (msg.sender != owner) {
            revert NotOwner();
        }
        return address(this).balance;
    }

    /**
     * @dev Returns the total balance of the user including staked Ether and rewards.
     * @return The total balance of the user in wei.
     */
    function getUserBal() external view returns (uint) {
        uint stakingWithReward = balances[msg.sender] +
            calculateReward(msg.sender);
        return stakingWithReward;
    }

    /**
     * @dev Calculates the reward based on the staked amount and duration.
     * @param _user The address of the user.
     * @return The calculated reward in wei.
     */
    function calculateReward(address _user) private view returns (uint) {
        // Calculate the duration of the stake
        uint duration = block.timestamp - stakeTimes[_user];

        // Get the staked amount
        uint stakedAmount = balances[_user];

        // Calculate the reward using the formula: (stakedAmount * RATE * duration) / (PRECISION_FACTOR * SECONDS_IN_A_YEAR)
        uint divisor = PRECISION_FACTOR * SECONDS_IN_A_YEAR;
        uint reward = (stakedAmount * RATE * duration) / divisor;

        return reward;
    }

    /**
     * @dev Fallback function to receive Ether directly.
     */
    receive() external payable {}
}
