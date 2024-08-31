// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Custom error definitions
error AddressZeroDetected();
error ZeroValueNotAllowed();
error CantSendToZeroAddress();
error InsufficientFunds();
error NotOwner();
error InsufficientContractBalance();
error AlreadyHaveAnActiveStake();
error LIQUIDATIONTIMENOTREACHEDYET();

/**
 * @title StakeLayi
 * @dev A smart contract for staking ERC20 tokens with reward calculation.
 */
contract StakeLayi {
    // Address of the ERC20 token being staked
    address private tokenAddress;

    // The owner of the contract, immutable after deployment
    address private immutable owner;

    // Event emitted when a stake is successfully made
    event StakeSuccessful(address indexed user, uint256 indexed amount);

    // Event emitted when a withdrawal is successfully made
    event WithdrawalSuccessful(address indexed user, uint256 indexed amount);

    // The interest rate set to 3%. (scaled to 300 because Solidity doesn't support decimals: 3 * 100)
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
     * @dev Constructor to set the ERC20 token address and contract owner.
     * @param _tokenAddress The address of the ERC20 token contract.
     */
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        owner = msg.sender;
    }

    /**
     * @dev Allows a user to stake a specified amount of tokens.
     * @param _amount The amount of tokens to stake.
     */
    function stake(uint _amount) external {
        // Check for invalid address
        if (msg.sender == address(0)) {
            revert AddressZeroDetected();
        }

        // Ensure the amount is greater than zero
        if (_amount <= 0) {
            revert ZeroValueNotAllowed();
        }

        // Get the user's token balance
        uint256 _userTokenBalance = IERC20(tokenAddress).balanceOf(msg.sender);

        // Ensure the user has enough tokens to stake
        if (_userTokenBalance < _amount) {
            revert InsufficientFunds();
        }

        // Transfer the tokens from the user to the contract
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        // Update the user's balance then update the stake start time if it is the first time staking
        balances[msg.sender] += _amount;
        if (stakeTimes[msg.sender] == 0) {
            stakeTimes[msg.sender] = block.timestamp;
        }

        // Emit a successful stake event
        emit StakeSuccessful(msg.sender, _amount);
    }

    /**
     * @dev Allows a user to withdraw their staked tokens and the rewards.
     */
    function withdrawStake() external {
        // Check for invalid address
        if (msg.sender == address(0)) {
            revert AddressZeroDetected();
        }

        // Ensure the minimum staking duration has been met
        if (block.timestamp - stakeTimes[msg.sender] < MIN_STAKING_DURATION) {
            revert LIQUIDATIONTIMENOTREACHEDYET();
        }

        // Ensure the user has staked tokens
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
        IERC20(tokenAddress).transfer(msg.sender, stakingWithReward);

        // Emit a successful withdrawal event
        emit WithdrawalSuccessful(msg.sender, stakingWithReward);
    }

    /**
     * @dev Returns the balance of the contract.
     * @return The balance of the contract in tokens.
     */
    function getContractBal() external view returns (uint) {
        // Ensure only the owner can view the contract balance
        if (msg.sender != owner) {
            revert NotOwner();
        }
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * @dev Returns the total balance of the user including staked tokens and rewards.
     * @return The total balance of the user in tokens.
     */
    function getUserBal() external view returns (uint) {
        uint stakingWithReward = balances[msg.sender] +
            calculateReward(msg.sender);
        return stakingWithReward;
    }

    /**
     * @dev Calculates the reward based on the staked amount and duration.
     * @param _user The address of the user.
     * @return The calculated reward in tokens.
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
}
