//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IHouse.sol";
import "../interface/IStakeEvents.sol";

contract Stake is Ownable, IStakeEvents {

    IHouse house;
    IERC20 assetToken;
    IERC20 landToken;

    mapping(address => uint) public amountStaked;
    mapping(address => bool) public hasStaked;
    address[] stakers;

    constructor(
        address _houseAddress,
        address _assetToken,
        address _landToken
    ) {
        house = IHouse(_houseAddress);
        assetToken = IERC20(_assetToken);   
        landToken = IERC20(_landToken);
    }

    /**
        @notice Set setting conract address 
        @param _address: Setting contract address
    */
    function setHouseContractAddress(address _address) external onlyOwner {
        house = IHouse(_address);
    }

    /** 
        @notice Stake Asset Tokens - deposit amount from user to contract address
        @param amount : deposit amount, tokenId : nft tokenId
    */
    function stake(uint amount, uint tokenId) public payable {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(user == msg.sender, "You do not own this NFT");
        require(activated, "Activation required");
        require(amount > 0, "No Deposit");

        assetToken.transferFrom(msg.sender, address(this), amount);
        house.deposit(tokenId, amount);
        amountStaked[msg.sender] += amount;

        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
            hasStaked[msg.sender] = true; 
        }

        emit Stake(msg.sender, tokenId, amount);
    }

    /** 
        @notice Untake Asset Tokens - withdraw amount from contract address to user
        @param amount : withdraw amount, tokenId : nft tokenId
    */
    function unstake(uint amount, uint tokenId) public {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(user == msg.sender, "You do not own this NFT");
        require(activated, "Activation required");
        require (amount > 0, "No Withdraw");
        
        require (house.getDepositedBalance(tokenId) >= amount, "Withdraw more than balance");
        require (amountStaked[msg.sender] >= amount, "Withdraw more than balance");
        
        assetToken.transfer(msg.sender, amount);
        house.withdraw(tokenId, amount);
        amountStaked[msg.sender] -= amount;

        emit Unstake(msg.sender, tokenId, amount);
    }

}
